// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:shared_preferences/shared_preferences.dart';

/// Préférences communauté / bénévolat (GitLab + affichage).
///
/// Le jeton personnel (PAT) est stocké via [SharedPreferences] (dépendance
/// déjà présente). Scope GitLab requis : **api**.
///
/// Un cache mémoire est tenu à jour à chaque lecture/écriture pour que le Hub
/// voie le jeton immédiatement après « Enregistrer » / « Vérifier », sans
/// redémarrer l’app (SharedPreferences desktop peut sinon rester stale).
class CommunitySettingsService {
  CommunitySettingsService._();

  static const defaultProjectPath = 'tutodecode-org/tdc-sdk';
  static const defaultGitlabHost = 'https://gitlab.com';
  static const patTokensUrl =
      'https://gitlab.com/-/user_settings/personal_access_tokens';
  static const gitlabOrgUrl = 'https://gitlab.com/tutodecode-org';
  static const liberapayUrl = 'https://liberapay.com/tutodecode';

  static const _kPat = 'tdc_community_gitlab_pat';
  static const _kUsername = 'tdc_community_gitlab_username';
  static const _kProjectPath = 'tdc_community_gitlab_project';
  static const _kHost = 'tdc_community_gitlab_host';

  static String? _pat;
  static String? _username;
  static String? _projectPath;
  static String? _host;
  static bool _memoryReady = false;

  /// Recharge le cache mémoire depuis le disque (démarrage / 1er accès).
  ///
  /// Après un `set*`, le cache est déjà à jour : ne pas rappeler [reload]
  /// juste après une écriture (SharedPreferences desktop peut encore être
  /// stale sur disque et écraserait le cache mémoire).
  static Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final pat = prefs.getString(_kPat)?.trim();
    final user = prefs.getString(_kUsername)?.trim();
    final project = prefs.getString(_kProjectPath)?.trim();
    final host = prefs.getString(_kHost)?.trim();
    _pat = (pat == null || pat.isEmpty) ? null : pat;
    _username = (user == null || user.isEmpty) ? null : user;
    _projectPath = (project == null || project.isEmpty) ? null : project;
    _host = (host == null || host.isEmpty) ? null : host;
    _memoryReady = true;
  }

  static Future<void> _ensureMemory() async {
    if (!_memoryReady) await reload();
  }

  static Future<String?> getPat() async {
    await _ensureMemory();
    return _pat;
  }

  static Future<void> setPat(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kPat);
      _pat = null;
    } else {
      await prefs.setString(_kPat, trimmed);
      _pat = trimmed;
    }
    _memoryReady = true;
  }

  static Future<String?> getUsername() async {
    await _ensureMemory();
    return _username;
  }

  static Future<void> setUsername(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kUsername);
      _username = null;
    } else {
      final cleaned = trimmed.replaceFirst(RegExp(r'^@'), '');
      await prefs.setString(_kUsername, cleaned);
      _username = cleaned;
    }
    _memoryReady = true;
  }

  static Future<String> getProjectPath() async {
    await _ensureMemory();
    final v = _projectPath;
    return (v == null || v.isEmpty) ? defaultProjectPath : v;
  }

  static Future<void> setProjectPath(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kProjectPath);
      _projectPath = null;
    } else {
      await prefs.setString(_kProjectPath, trimmed);
      _projectPath = trimmed;
    }
    _memoryReady = true;
  }

  static Future<String> getHost() async {
    await _ensureMemory();
    final v = _host;
    if (v == null || v.isEmpty) return defaultGitlabHost;
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  static Future<void> setHost(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_kHost);
      _host = null;
    } else {
      final cleaned =
          trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
      await prefs.setString(_kHost, cleaned);
      _host = cleaned;
    }
    _memoryReady = true;
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
