// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/volunteer_board_fallback.dart';
import '../models/volunteer_task.dart';
import 'community_settings_service.dart';
import 'volunteer_board_parser.dart';

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

/// Hub bénévolat ↔ GitLab Issues API (liste live + création idée/bug).
///
/// Source de vérité : issues labellisées `benevolat` (souvent + `wishlist` /
/// `bug` / `proposition`). Fallback hors ligne : markdown embarqué.
class GitlabVolunteerService {
  GitlabVolunteerService._();

  /// Label commun à toutes les issues du board bénévolat.
  static const volunteerLabel = 'benevolat';

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

  /// Charge le board depuis les **issues GitLab** (label `benevolat`).
  /// Sans réseau / sans issues : fallback markdown embarqué.
  static Future<({List<VolunteerTask> tasks, bool fromNetwork, String? error})>
      loadBoard() async {
    try {
      final host = await CommunitySettingsService.getHost();
      final project = await CommunitySettingsService.getProjectPath();
      final pid = _projectId(project);
      final headers = await _headers();

      // Issues ouvertes + récemment fermées (state=all, filtrées côté client).
      final uri = Uri.parse('$host/api/v4/projects/$pid/issues').replace(
        queryParameters: {
          'labels': volunteerLabel,
          'state': 'all',
          'per_page': '100',
          'order_by': 'updated_at',
          'sort': 'desc',
        },
      );

      final res =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(res.body);
        if (list is List) {
          final tasks = list
              .whereType<Map>()
              .map((e) => VolunteerTask.fromGitlabIssue(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
          if (tasks.isNotEmpty) {
            return (tasks: tasks, fromNetwork: true, error: null);
          }
          return (
            tasks: VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown),
            fromNetwork: true,
            error:
                'Aucune issue « $volunteerLabel » pour l’instant — aperçu local '
                '(crée des issues avec ce label sur GitLab).',
          );
        }
      }

      // Projet public sans PAT peut échouer ; tenter sans label si 404 labels.
      return (
        tasks: VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown),
        fromNetwork: false,
        error: 'Issues GitLab indisponibles (${res.statusCode}) — aperçu local.',
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

  static Future<GitlabVolunteerResult> proposeIdea({
    required String title,
    required String description,
  }) async {
    return _createLabeledIssue(
      title: title,
      description: description,
      labels: const [volunteerLabel, 'wishlist', 'proposition'],
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
      labels: const [volunteerLabel, 'bug'],
      prefix: '🐛 Bug',
    );
  }

  static Future<GitlabVolunteerResult> _createLabeledIssue({
    required String title,
    required String description,
    required List<String> labels,
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
      'labels': labels.join(','),
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
