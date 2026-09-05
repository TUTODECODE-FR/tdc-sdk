// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

/// Une tâche du tableau des contributions (VOLUNTEER_BOARD.md).
class VolunteerTask {
  final String id;
  final String status;
  final String priority;
  final String title;
  final String description;
  final String skills;
  final String takenBy;
  final String link;
  final bool pendingValidation;

  const VolunteerTask({
    required this.id,
    required this.status,
    required this.priority,
    required this.title,
    required this.description,
    this.skills = '',
    this.takenBy = '—',
    this.link = '—',
    this.pendingValidation = false,
  });

  bool get isLibre =>
      status.toLowerCase() == 'libre' &&
      (takenBy.trim().isEmpty || takenBy.trim() == '—');

  bool get isEnCours => status.toLowerCase().contains('cours');

  bool get isFait => status.toLowerCase() == 'fait';

  bool get isBloque => status.toLowerCase().contains('bloqu');

  VolunteerTask copyWith({
    String? id,
    String? status,
    String? priority,
    String? title,
    String? description,
    String? skills,
    String? takenBy,
    String? link,
    bool? pendingValidation,
  }) {
    return VolunteerTask(
      id: id ?? this.id,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      takenBy: takenBy ?? this.takenBy,
      link: link ?? this.link,
      pendingValidation: pendingValidation ?? this.pendingValidation,
    );
  }
}
