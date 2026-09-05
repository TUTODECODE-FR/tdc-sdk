// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:shared_preferences/shared_preferences.dart';

/// Préférences communauté / bénévolat (GitLab + affichage).
///
/// Le jeton personnel (PAT) est stocké via [SharedPreferences] (dépendance
/// déjà présente). Scope GitLab requis : **api**.
class CommunitySettingsService {
  CommunitySettingsService._();

  static const defaultProjectPath = 'tutodecode-org/tdc-sdk';
  static const defaultGitlabHost = 'https://gitlab.com';
  static const patTokensUrl =
      'https://gitlab.com/-/user_settings/personal_access_tokens';

  static const _kPat = 'tdc_community_gitlab_pat';
  static const _kUsername = 'tdc_community_gitlab_username';
  static const _kProjectPath = 'tdc_community_gitlab_project';
  static const _kHost = 'tdc_community_gitlab_host';

  static Future<String?> getPat() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kPat)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setPat(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kPat);
    } else {
      await prefs.setString(_kPat, trimmed);
    }
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kUsername)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setUsername(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kUsername);
    } else {
      await prefs.setString(_kUsername, trimmed.replaceFirst(RegExp(r'^@'), ''));
    }
  }

  static Future<String> getProjectPath() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kProjectPath)?.trim();
    return (v == null || v.isEmpty) ? defaultProjectPath : v;
  }

  static Future<void> setProjectPath(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kProjectPath);
    } else {
      await prefs.setString(_kProjectPath, trimmed);
    }
  }

  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kHost)?.trim();
    if (v == null || v.isEmpty) return defaultGitlabHost;
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  static Future<void> setHost(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kHost);
    } else {
      await prefs.setString(
        _kHost,
        trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed,
      );
    }
  }

  static Future<String> projectWebUrl() async {
    final host = await getHost();
    final path = await getProjectPath();
    return '$host/$path';
  }

  static Future<String> boardWebUrl() async {
    final base = await projectWebUrl();
    return '$base/-/blob/main/VOLUNTEER_BOARD.md';
  }

  static Future<String> boardRawUrl() async {
    final base = await projectWebUrl();
    return '$base/-/raw/main/VOLUNTEER_BOARD.md';
  }
}
