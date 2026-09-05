// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import '../models/volunteer_task.dart';

/// Parse le tableau Markdown de VOLUNTEER_BOARD.md (wishlist / backlog).
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

  static List<String> _splitRow(String line) {
    var s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|')) s = s.substring(0, s.length - 1);
    return s.split('|');
  }
}
