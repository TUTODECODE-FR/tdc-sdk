// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/volunteer_task.dart';
import 'community_settings_service.dart';
import 'volunteer_board_parser.dart';
import '../data/volunteer_board_fallback.dart';

class GitlabVolunteerResult {
  final bool ok;
  final String message;
  final String? webUrl;
  final String? username;

  const GitlabVolunteerResult({
    required this.ok,
    required this.message,
    this.webUrl,
    this.username,
  });
}

/// Hub bénévolat ↔ GitLab API (board = VOLUNTEER_BOARD.md).
class GitlabVolunteerService {
  GitlabVolunteerService._();

  static String _projectId(String path) => Uri.encodeComponent(path);

  static Future<Map<String, String>> _headers({String? pat}) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = pat ?? await CommunitySettingsService.getPat();
    if (token != null) {
      h['PRIVATE-TOKEN'] = token;
    }
    return h;
  }

  /// Charge le board depuis GitLab (raw), sinon fallback embarqué.
  static Future<({List<VolunteerTask> tasks, bool fromNetwork, String? error})>
      loadBoard() async {
    try {
      final rawUrl = await CommunitySettingsService.boardRawUrl();
      final headers = await _headers();
      final res = await http
          .get(Uri.parse(rawUrl), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final tasks = VolunteerBoardParser.parse(res.body);
        if (tasks.isNotEmpty) {
          return (tasks: tasks, fromNetwork: true, error: null);
        }
      }
      return (
        tasks: VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown),
        fromNetwork: false,
        error: 'Board distant indisponible (${res.statusCode}) — aperçu local.',
      );
    } catch (e) {
      return (
        tasks: VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown),
        fromNetwork: false,
        error: 'Hors ligne — aperçu local. ($e)',
      );
    }
  }

  /// Vérifie le PAT et récupère le username GitLab.
  static Future<GitlabVolunteerResult> verifyPat(String pat) async {
    final host = await CommunitySettingsService.getHost();
    try {
      final res = await http
          .get(
            Uri.parse('$host/api/v4/user'),
            headers: await _headers(pat: pat),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final username = json['username'] as String? ?? '';
        return GitlabVolunteerResult(
          ok: true,
          message: 'Connecté·e en tant que @$username',
          username: username,
        );
      }
      return GitlabVolunteerResult(
        ok: false,
        message: 'Jeton refusé (${res.statusCode}). Vérifie le scope « api ».',
      );
    } catch (e) {
      return GitlabVolunteerResult(ok: false, message: 'Erreur réseau : $e');
    }
  }

  /// Claim : branche + commit board + MR. Si échec → Issue `volunteer-claim`.
  static Future<GitlabVolunteerResult> claimTask(VolunteerTask task) async {
    final pat = await CommunitySettingsService.getPat();
    if (pat == null) {
      return const GitlabVolunteerResult(
        ok: false,
        message:
            'Pour participer, ajoute ton jeton GitLab (scope api) dans '
            'Paramètres → Communauté.',
      );
    }

    var username = await CommunitySettingsService.getUsername();
    if (username == null || username.isEmpty) {
      return const GitlabVolunteerResult(
        ok: false,
        message:
            'Indique ton pseudo GitLab dans Paramètres → Communauté '
            'avant de prendre une tâche.',
      );
    }

    final host = await CommunitySettingsService.getHost();
    final project = await CommunitySettingsService.getProjectPath();
    final pid = _projectId(project);
    final headers = await _headers(pat: pat);
    final safeUser = username
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
    final branch = 'volunteer/${task.id.toLowerCase()}-$safeUser';

    try {
      // 1) Contenu actuel du board
      final fileRes = await http
          .get(
            Uri.parse(
              '$host/api/v4/projects/$pid/repository/files/'
              '${Uri.encodeComponent('VOLUNTEER_BOARD.md')}/raw?ref=main',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (fileRes.statusCode != 200) {
        return await _claimViaIssue(
          task: task,
          username: username,
          host: host,
          pid: pid,
          headers: headers,
          reason: 'Lecture board (${fileRes.statusCode})',
        );
      }

      final updated = VolunteerBoardParser.claimInMarkdown(
        markdown: fileRes.body,
        taskId: task.id,
        username: username,
      );

      // 2) Commit sur nouvelle branche (start_branch = main)
      final commitBody = jsonEncode({
        'branch': branch,
        'start_branch': 'main',
        'commit_message':
            'docs(volunteer): claim ${task.id} by @$username\n\n'
                'Signed-off-by: $username via TDC Studio <contact@tutodecode.org>',
        'actions': [
          {
            'action': 'update',
            'file_path': 'VOLUNTEER_BOARD.md',
            'content': updated,
          }
        ],
      });

      final commitRes = await http
          .post(
            Uri.parse('$host/api/v4/projects/$pid/repository/commits'),
            headers: headers,
            body: commitBody,
          )
          .timeout(const Duration(seconds: 20));

      if (commitRes.statusCode != 201) {
        return await _claimViaIssue(
          task: task,
          username: username,
          host: host,
          pid: pid,
          headers: headers,
          reason: 'Commit (${commitRes.statusCode}): ${commitRes.body}',
        );
      }

      // 3) Merge Request
      final mrBody = jsonEncode({
        'source_branch': branch,
        'target_branch': 'main',
        'title': 'volunteer: Je m\'occupe de ${task.id} — ${task.title}',
        'description':
            '## Entraide\n\n'
            '**@$username** s\'occupe de **${task.id}** via TDC Studio.\n\n'
            '- Titre : ${task.title}\n'
            '- Mise à jour de `VOLUNTEER_BOARD.md` (Pris par + En cours)\n\n'
            '_MR ouverte depuis l\'app — merci à la communauté !_',
        'labels': 'volunteer-claim',
        'remove_source_branch': true,
      });

      final mrRes = await http
          .post(
            Uri.parse('$host/api/v4/projects/$pid/merge_requests'),
            headers: headers,
            body: mrBody,
          )
          .timeout(const Duration(seconds: 15));

      if (mrRes.statusCode == 201) {
        final json = jsonDecode(mrRes.body) as Map<String, dynamic>;
        final url = json['web_url'] as String?;
        return GitlabVolunteerResult(
          ok: true,
          message:
              'C\'est noté ! Ta proposition est en attente de validation communautaire.',
          webUrl: url,
          username: username,
        );
      }

      // Branche créée mais MR échouée → Issue de secours
      return await _claimViaIssue(
        task: task,
        username: username,
        host: host,
        pid: pid,
        headers: headers,
        reason: 'MR (${mrRes.statusCode}) — branche `$branch` créée',
        branchHint: branch,
      );
    } catch (e) {
      return GitlabVolunteerResult(
        ok: false,
        message: 'Impossible de réserver la tâche : $e',
      );
    }
  }

  static Future<GitlabVolunteerResult> _claimViaIssue({
    required VolunteerTask task,
    required String username,
    required String host,
    required String pid,
    required Map<String, String> headers,
    required String reason,
    String? branchHint,
  }) async {
    final boardUrl = await CommunitySettingsService.boardWebUrl();
    final desc = StringBuffer()
      ..writeln('## Claim bénévole (via TDC Studio)')
      ..writeln()
      ..writeln('- **Tâche** : `${task.id}` — ${task.title}')
      ..writeln('- **Pris par** : @$username')
      ..writeln('- **Board** : $boardUrl')
      ..writeln()
      ..writeln('Merci de mettre à jour `VOLUNTEER_BOARD.md` (Pris par + En cours).')
      ..writeln()
      ..writeln('_Fallback MVP : $reason'
          '${branchHint != null ? ' · branche `$branchHint`' : ''}._');

    final body = jsonEncode({
      'title': 'Claim ${task.id} by @$username',
      'description': desc.toString(),
      'labels': 'volunteer-claim',
    });

    try {
      final res = await http
          .post(
            Uri.parse('$host/api/v4/projects/$pid/issues'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return GitlabVolunteerResult(
          ok: true,
          message:
              'Demande envoyée (en attente validation). Un mainteneur mettra à jour le tableau.',
          webUrl: json['web_url'] as String?,
          username: username,
        );
      }
      return GitlabVolunteerResult(
        ok: false,
        message: 'Échec claim (${res.statusCode}) : ${res.body}',
      );
    } catch (e) {
      return GitlabVolunteerResult(ok: false, message: 'Erreur : $e');
    }
  }

  static Future<GitlabVolunteerResult> proposeIdea({
    required String title,
    required String description,
  }) async {
    return _createLabeledIssue(
      title: title,
      description: description,
      label: 'proposition',
      prefix: '💡 Proposition',
    );
  }

  static Future<GitlabVolunteerResult> reportBug({
    required String title,
    required String description,
  }) async {
    return _createLabeledIssue(
      title: title,
      description: description,
      label: 'bug',
      prefix: '🐛 Bug',
    );
  }

  static Future<GitlabVolunteerResult> _createLabeledIssue({
    required String title,
    required String description,
    required String label,
    required String prefix,
  }) async {
    final pat = await CommunitySettingsService.getPat();
    if (pat == null) {
      return const GitlabVolunteerResult(
        ok: false,
        message:
            'Pour participer, ajoute ton jeton GitLab (scope api) dans '
            'Paramètres → Communauté.',
      );
    }

    var username = await CommunitySettingsService.getUsername() ?? 'bénévole';
    final who = await verifyPat(pat);
    if (who.ok && who.username != null) {
      username = who.username!;
      await CommunitySettingsService.setUsername(username);
    }

    final host = await CommunitySettingsService.getHost();
    final project = await CommunitySettingsService.getProjectPath();
    final pid = _projectId(project);
    final headers = await _headers(pat: pat);

    final body = jsonEncode({
      'title': '$prefix : $title',
      'description':
          '## Depuis TDC Studio\n\n'
          '**Auteur·rice** : @$username\n\n'
          '$description\n\n'
          '---\n_Envoyé via le Hub Communauté de TDC Studio._',
      'labels': label,
    });

    try {
      final res = await http
          .post(
            Uri.parse('$host/api/v4/projects/$pid/issues'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 201) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return GitlabVolunteerResult(
          ok: true,
          message: 'Merci ! Ta contribution est visible pour la communauté.',
          webUrl: json['web_url'] as String?,
          username: username,
        );
      }
      return GitlabVolunteerResult(
        ok: false,
        message: 'Envoi impossible (${res.statusCode}) : ${res.body}',
      );
    } catch (e) {
      return GitlabVolunteerResult(ok: false, message: 'Erreur : $e');
    }
  }
}
