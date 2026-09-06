// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio — Application unifiée
// ============================================================
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_studio_screen.dart';
import 'editorial_screen.dart';
import 'screens/community_settings_screen.dart';
import 'screens/volunteer_hub_screen.dart';
import 'services/recent_projects_service.dart';
import 'tdc_parser_v2.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TdcStudioApp());
}

class TdcStudioApp extends StatelessWidget {
  const TdcStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TDC Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFF5EBDA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5EBDA),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF141414),
        ),
      ),
      home: const TdcStudioLauncherScreen(),
    );
  }
}

class TdcStudioLauncherScreen extends StatefulWidget {
  const TdcStudioLauncherScreen({super.key});

  @override
  State<TdcStudioLauncherScreen> createState() => _TdcStudioLauncherScreenState();
}

class _TdcStudioLauncherScreenState extends State<TdcStudioLauncherScreen> {
  List<RecentProject> _recents = [];
  bool _loading = true;
  String _appVersion = '…';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final results = await Future.wait([
      RecentProjectsService.load(),
      PackageInfo.fromPlatform(),
    ]);
    if (!mounted) return;
    setState(() {
      _recents = results[0] as List<RecentProject>;
      _appVersion = (results[1] as PackageInfo).version;
      _loading = false;
    });
  }

  Future<void> _openEditorial({String? path, bool askHowToStart = true}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TdcEditorialScreen(
          initialFilePath: path,
          askHowToStart: askHowToStart && path == null,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openFilePicker() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'TDC', extensions: ['tdc']),
    ]);
    if (file == null || !mounted) return;
    try {
      final text = await File(file.path).readAsString();
      final resource = TdcParserV2.parse(text);
      if (resource.type == 'course') {
        await _openEditorial(path: file.path);
        return;
      }
      // Non-course → Dev & Traduction
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TdcAppStudioScreen()),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir : $e')),
      );
    }
  }

  Future<void> _removeRecent(RecentProject p) async {
    await RecentProjectsService.remove(p.path);
    await _reload();
  }

  Future<void> _revealInFinder(String path) async {
    try {
      await Process.run('open', ['-R', path]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _openFilePicker,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _openFilePicker,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () => _openEditorial(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _openEditorial(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A0A), Color(0xFF141414)],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBDA).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFF5EBDA).withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'TDC Studio',
                              style: TextStyle(
                                color: Color(0xFFF5EBDA),
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'v$_appVersion',
                            style: const TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'IDE de création de contenu TUTODECODE',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'PROJETS RÉCENTS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: LinearProgressIndicator(
                            color: Color(0xFFF5EBDA),
                            backgroundColor: Color(0xFF2A2A2A),
                          ),
                        )
                      else if (_recents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: const Text(
                            'Aucun projet récent — créez un cours ou ouvrez un fichier .tdc.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      else
                        ..._recents.map(_buildRecentTile),
                      const SizedBox(height: 32),
                      const Text(
                        'CRÉER',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.menu_book,
                              title: 'Éditeur de Cours',
                              subtitle:
                                  'Import .tdc, from scratch ou template — quiz, sync, coloration',
                              onTap: () => _openEditorial(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModeCard(
                              icon: Icons.translate,
                              title: 'Dev & Traduction',
                              subtitle: 'Cheat sheets, locales UI et export assets (.tdc v2)',
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TdcAppStudioScreen(),
                                  ),
                                );
                                await _reload();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'OUVRIR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openEditorial(),
                            icon: const Icon(Icons.add),
                            label: const Text('Nouveau cours'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF5EBDA),
                              side: const BorderSide(color: Color(0xFFF5EBDA)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _openFilePicker,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Ouvrir fichier (Ctrl+O)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Color(0xFF2A2A2A)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'COMMUNAUTÉ',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entraide & bénévolat',
                              style: TextStyle(
                                color: Color(0xFFF5EBDA),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Issues bénévolat en live, proposer une idée ou signaler un souci — sans éditer un tableau markdown.',
                              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const VolunteerHubScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.favorite_outline, size: 18),
                                  label: const Text('Hub Communauté'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CommunitySettingsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.settings_outlined, size: 18),
                                  label: const Text('Paramètres communauté'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFF5EBDA),
                                    side: const BorderSide(color: Color(0xFFF5EBDA)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTile(RecentProject p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (p.type == 'course') {
              _openEditorial(path: p.path);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TdcAppStudioScreen()),
              );
            }
          },
          onSecondaryTapDown: (details) {
            showMenu(
              context: context,
              position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy,
              ),
              color: const Color(0xFF1E1E1E),
              items: [
                PopupMenuItem(
                  onTap: () => _openEditorial(path: p.path),
                  child: const Text('Ouvrir'),
                ),
                PopupMenuItem(
                  onTap: () => Future.microtask(() => _revealInFinder(p.path)),
                  child: const Text('Révéler dans le Finder'),
                ),
                PopupMenuItem(
                  onTap: () => Future.microtask(() => _removeRecent(p)),
                  child: const Text('Retirer de la liste'),
                ),
              ],
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                Icon(
                  p.type == 'course' ? Icons.menu_book : Icons.description,
                  color: const Color(0xFFF5EBDA),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title.isEmpty ? p.id : p.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (p.category.isNotEmpty) p.category,
                          p.id,
                          p.path,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  p.relativeTime,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5EBDA).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFF5EBDA), size: 36),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF5EBDA),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
