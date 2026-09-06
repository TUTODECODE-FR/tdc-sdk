// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

/// Une idée / tâche du tableau des contributions (VOLUNTEER_BOARD.md).
class VolunteerTask {
  final String id;
  final String status;
  final String priority;
  final String title;
  final String description;
  final String skills;
  final String takenBy;
  final String link;

  const VolunteerTask({
    required this.id,
    required this.status,
    required this.priority,
    required this.title,
    required this.description,
    this.skills = '',
    this.takenBy = '—',
    this.link = '—',
  });

  bool get isLibre => status.toLowerCase() == 'libre';

  bool get isEnCours => status.toLowerCase().contains('cours');

  bool get isFait => status.toLowerCase() == 'fait';

  bool get isBloque => status.toLowerCase().contains('bloqu');
}
