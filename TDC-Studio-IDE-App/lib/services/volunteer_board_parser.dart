// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import '../models/volunteer_task.dart';

/// Parse le tableau Markdown de VOLUNTEER_BOARD.md (source de vérité).
class VolunteerBoardParser {
  VolunteerBoardParser._();

  static List<VolunteerTask> parse(String markdown) {
    final lines = markdown.split('\n');
    final tasks = <VolunteerTask>[];
    var inBacklogTable = false;

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.startsWith('## Backlog')) {
        inBacklogTable = true;
        continue;
      }
      if (inBacklogTable && line.startsWith('## ')) {
        break;
      }
      if (!inBacklogTable) continue;
      if (!line.startsWith('|')) continue;
      if (line.contains('---') || line.toLowerCase().contains('| id |')) {
        continue;
      }

      final cells = _splitRow(line);
      if (cells.length < 5) continue;
      final id = cells[0].trim();
      if (!RegExp(r'^TDC-\d+', caseSensitive: false).hasMatch(id)) continue;

      tasks.add(VolunteerTask(
        id: id,
        status: cells.length > 1 ? cells[1].trim() : 'Libre',
        priority: cells.length > 2 ? cells[2].trim() : '',
        title: cells.length > 3 ? cells[3].trim() : '',
        description: cells.length > 4 ? cells[4].trim() : '',
        skills: cells.length > 5 ? cells[5].trim() : '',
        takenBy: cells.length > 6 ? cells[6].trim() : '—',
        link: cells.length > 7 ? cells[7].trim() : '—',
      ));
    }
    return tasks;
  }

  /// Met à jour la ligne d'une tâche (Pris par + statut) dans le markdown.
  static String claimInMarkdown({
    required String markdown,
    required String taskId,
    required String username,
    String status = 'En cours',
    String? link,
  }) {
    final handle = username.startsWith('@') ? username : '@$username';
    final lines = markdown.split('\n');
    final out = <String>[];

    for (final line in lines) {
      if (!line.trimLeft().startsWith('|')) {
        out.add(line);
        continue;
      }
      final cells = _splitRow(line);
      if (cells.isEmpty || cells[0].trim() != taskId) {
        out.add(line);
        continue;
      }
      while (cells.length < 8) {
        cells.add('—');
      }
      cells[1] = ' $status ';
      cells[6] = ' $handle ';
      if (link != null && link.isNotEmpty) {
        cells[7] = ' $link ';
      }
      out.add('|${cells.join('|')}|');
    }
    return out.join('\n');
  }

  static List<String> _splitRow(String line) {
    var s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|')) s = s.substring(0, s.length - 1);
    return s.split('|');
  }
}
