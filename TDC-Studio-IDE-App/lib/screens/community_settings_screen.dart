// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/community_settings_service.dart';
import '../services/gitlab_volunteer_service.dart';
import '../services/open_url.dart';
import 'volunteer_hub_screen.dart';

/// Paramètres « Communauté / Bénévolat » — liens GitLab + jeton.
class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _patCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  bool _loading = true;
  bool _obscurePat = true;
  bool _saving = false;
  String? _statusMsg;
  bool _statusOk = false;

  static const _beige = Color(0xFFF5EBDA);
  static const _surface = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pat = await CommunitySettingsService.getPat();
    final user = await CommunitySettingsService.getUsername();
    final project = await CommunitySettingsService.getProjectPath();
    final host = await CommunitySettingsService.getHost();
    if (!mounted) return;
    setState(() {
      _patCtrl.text = pat ?? '';
      _userCtrl.text = user ?? '';
      _projectCtrl.text = project;
      _hostCtrl.text = host;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _patCtrl.dispose();
    _userCtrl.dispose();
    _projectCtrl.dispose();
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool verify = false}) async {
    setState(() {
      _saving = true;
      _statusMsg = null;
    });
    await CommunitySettingsService.setPat(_patCtrl.text);
    await CommunitySettingsService.setUsername(_userCtrl.text);
    await CommunitySettingsService.setProjectPath(_projectCtrl.text);
    await CommunitySettingsService.setHost(_hostCtrl.text);

    if (verify) {
      if (_patCtrl.text.trim().isEmpty) {
        setState(() {
          _saving = false;
          _statusOk = false;
          _statusMsg =
              'Le jeton est requis pour participer (scope « api »).';
        });
        return;
      }
      final r = await GitlabVolunteerService.verifyPat(_patCtrl.text.trim());
      if (r.ok && r.username != null) {
        _userCtrl.text = r.username!;
        await CommunitySettingsService.setUsername(r.username);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _statusOk = r.ok;
        _statusMsg = r.message;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _statusOk = true;
      _statusMsg = 'Préférences enregistrées.';
    });
  }

  InputDecoration _fieldDeco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _beige),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _beige,
        title: const Text('Communauté / Bénévolat'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VolunteerHubScreen()),
              );
            },
            child: const Text('Hub', style: TextStyle(color: _beige)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _beige))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _beige.withValues(alpha: 0.25)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On avance ensemble',
                        style: TextStyle(
                          color: _beige,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pour proposer une idée ou signaler un bug depuis '
                        'l’app, ajoute ton pseudo GitLab et un jeton personnel. '
                        'La lecture du tableau reste possible sans jeton. '
                        'Pour coder : branche + MR (voir CONTRIBUTING).',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PROJET GITLAB',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _hostCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco('Adresse GitLab', hint: 'https://gitlab.com'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _projectCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco(
                    'Projet',
                    hint: CommunitySettingsService.defaultProjectPath,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'LIENS / SOUTENIR',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Repos publics et soutien libre — sans « claim » de tâche. '
                  'On avance ensemble, à ton rythme.',
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final url = await CommunitySettingsService.projectWebUrl();
                      await openExternalUrl(url);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16, color: _beige),
                    label: const Text(
                      'Projet GitLab — TDC-SDK',
                      style: TextStyle(color: _beige),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openExternalUrl(
                      CommunitySettingsService.gitlabOrgUrl,
                    ),
                    icon: const Icon(Icons.group_outlined, size: 16, color: _beige),
                    label: const Text(
                      'Organisation GitLab — tutodecode-org',
                      style: TextStyle(color: _beige),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => openExternalUrl(
                      CommunitySettingsService.liberapayUrl,
                    ),
                    child: const Text(
                      '❤️ Soutenir TUTODECODE',
                      style: TextStyle(color: Color(0xFFE11D48)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'TON PROFIL',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco(
                    'Pseudo GitLab (requis pour participer)',
                    hint: 'ex. ton-pseudo-gitlab',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _patCtrl,
                  obscureText: _obscurePat,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDeco(
                    'Jeton d\'accès personnel (requis pour participer)',
                    hint: 'glpat-…',
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePat ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white38,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePat = !_obscurePat),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nécessaire pour proposer une idée ou signaler un bug via '
                  'GitLab. Scope « api ». Stocké uniquement en local sur cet '
                  'ordinateur — tu peux le révoquer à tout moment.',
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        openExternalUrl(CommunitySettingsService.patTokensUrl),
                    icon: const Icon(Icons.key, size: 16, color: Color(0xFFD4AF37)),
                    label: const Text(
                      'Créer un jeton sur GitLab',
                      style: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
                if (_statusMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_statusOk ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMsg!,
                      style: TextStyle(
                        color: _statusOk
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => _save(verify: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _beige,
                          side: const BorderSide(color: _beige),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : () => _save(verify: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _beige,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Vérifier le jeton'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VolunteerHubScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Ouvrir le Hub Communauté'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: await CommunitySettingsService.boardWebUrl(),
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien du tableau copié')),
                    );
                  },
                  child: const Text(
                    'Copier le lien du tableau des contributions',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}
