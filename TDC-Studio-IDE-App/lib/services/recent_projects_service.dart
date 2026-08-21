// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Recent projects persistence for TDC Studio launcher.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentProject {
  final String path;
  final String id;
  final String title;
  final String type; // course | cheat_sheet | locale
  final String category;
  final DateTime modifiedAt;

  const RecentProject({
    required this.path,
    required this.id,
    required this.title,
    required this.type,
    this.category = '',
    required this.modifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'id': id,
        'title': title,
        'type': type,
        'category': category,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory RecentProject.fromJson(Map<String, dynamic> json) {
    return RecentProject(
      path: json['path'] as String? ?? '',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'course',
      category: json['category'] as String? ?? '',
      modifiedAt: DateTime.tryParse(json['modifiedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get relativeTime {
    final diff = DateTime.now().difference(modifiedAt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    return '${modifiedAt.day}/${modifiedAt.month}/${modifiedAt.year}';
  }
}

class RecentProjectsService {
  RecentProjectsService._();
  static const _key = 'tdc_studio_recent_projects';
  static const _maxItems = 8;

  static Future<List<RecentProject>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) {
          try {
            return RecentProject.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentProject>()
        .toList();
  }

  static Future<void> add(RecentProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((p) => p.path == project.path);
    current.insert(0, project);
    final trimmed = current.take(_maxItems).toList();
    await prefs.setStringList(
      _key,
      trimmed.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  static Future<void> remove(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((p) => p.path == path);
    await prefs.setStringList(
      _key,
      current.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }
}
