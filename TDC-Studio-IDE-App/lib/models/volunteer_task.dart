// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

/// Une idée / tâche du board bénévolat (issue GitLab ou fallback local).
class VolunteerTask {
  final String id;
  final String status;
  final String priority;
  final String title;
  final String description;
  final String skills;
  final String takenBy;
  final String link;
  final List<String> labels;

  const VolunteerTask({
    required this.id,
    required this.status,
    required this.priority,
    required this.title,
    required this.description,
    this.skills = '',
    this.takenBy = '—',
    this.link = '—',
    this.labels = const [],
  });

  bool get isLibre => status.toLowerCase() == 'libre';

  bool get isEnCours => status.toLowerCase().contains('cours');

  bool get isFait => status.toLowerCase() == 'fait';

  bool get isBloque => status.toLowerCase().contains('bloqu');

  bool get isBug =>
      labels.any((l) => l.toLowerCase() == 'bug') ||
      title.toLowerCase().contains('bug');

  bool get isIdea =>
      labels.any((l) =>
          l.toLowerCase() == 'wishlist' ||
          l.toLowerCase() == 'proposition') ||
      !isBug;

  /// iid numérique GitLab (`#42` → 42), ou null si fallback local.
  int? get issueIid {
    final m = RegExp(r'^#?(\d+)$').firstMatch(id.trim());
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  /// Mappe une issue GitLab vers une carte Hub.
  factory VolunteerTask.fromGitlabIssue(Map<String, dynamic> json) {
    final iid = json['iid'];
    final state = (json['state'] as String? ?? 'opened').toLowerCase();
    final assignees = json['assignees'] as List? ?? const [];
    final labelsRaw = json['labels'] as List? ?? const [];
    final labels = labelsRaw.map((e) => '$e').toList();

    String status;
    if (state == 'closed') {
      status = 'Fait';
    } else if (assignees.isNotEmpty) {
      status = 'En cours';
    } else {
      status = 'Libre';
    }

    String priority = '';
    for (final l in labels) {
      final lower = l.toLowerCase();
      if (lower == 'p1' || lower == 'priority::1') {
        priority = 'P1';
        break;
      }
      if (lower == 'p2' || lower == 'priority::2') {
        priority = 'P2';
        break;
      }
      if (lower == 'p3' || lower == 'priority::3') {
        priority = 'P3';
        break;
      }
    }

    String takenBy = '—';
    if (assignees.isNotEmpty) {
      final first = assignees.first;
      if (first is Map) {
        final u = first['username'] as String?;
        if (u != null && u.isNotEmpty) takenBy = '@$u';
      }
    }

    final desc = (json['description'] as String? ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final shortDesc =
        desc.length > 160 ? '${desc.substring(0, 157)}…' : desc;

    final skillBits = <String>[];
    for (final l in labels) {
      final lower = l.toLowerCase();
      if (lower == 'benevolat' ||
          lower.startsWith('priority') ||
          lower == 'p1' ||
          lower == 'p2' ||
          lower == 'p3') {
        continue;
      }
      skillBits.add(l);
    }

    return VolunteerTask(
      id: '#$iid',
      status: status,
      priority: priority,
      title: (json['title'] as String? ?? 'Sans titre').trim(),
      description: shortDesc,
      skills: skillBits.join(', '),
      takenBy: takenBy,
      link: json['web_url'] as String? ?? '—',
      labels: labels,
    );
  }
}
