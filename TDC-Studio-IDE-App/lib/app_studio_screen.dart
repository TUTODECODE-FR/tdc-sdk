// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio — Dev & Traduction (mode "App Studio")
// Onglets : Cheat Sheets, Locales (UI), Export vers assets/
// ============================================================
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_dialog.dart';
import 'screens/cheat_sheet_editor.dart';
import 'screens/locale_editor.dart';
import 'tdc_import_parser.dart';
import 'tdc_parser_v2.dart';

class TdcAppStudioScreen extends StatefulWidget {
  const TdcAppStudioScreen({super.key});

  @override
  State<TdcAppStudioScreen> createState() => _TdcAppStudioScreenState();
}

class _TdcAppStudioScreenState extends State<TdcAppStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _cheatSheetSessionStarted = false;

  // ── Locale state ──
  final _localeKeys = <String, TextEditingController>{};
  final _sourceLocaleValues = <String, String>{};
  final _localeCode = ValueNotifier<String>('en');
  final _localeKeysList = [
    'menu.home',
    'menu.tools',
    'menu.cheat_sheets',
    'menu.netkit',
    'menu.ai_chat',
    'menu.settings',
    'menu.roadmap',
    'menu.lab',
    'menu.ghost_link',
    'menu.phantom',
    'menu.coming_soon',
    'menu.phantom_coming_soon',
    'language.select_title',
    'home.banner.title',
    'home.banner.subtitle',
    'home.banner.explore',
  ];

  /// Valeurs sources (français) par défaut affichées comme référence.
  static const _defaultSourceValues = {
    'menu.home': 'Accueil',
    'menu.tools': 'Outils',
    'menu.cheat_sheets': 'Cheat Sheets',
    'menu.netkit': 'NetKit',
    'menu.ai_chat': 'Ghost AI',
    'menu.settings': 'Paramètres',
    'menu.roadmap': 'Roadmap',
    'menu.lab': 'T2C Lab',
    'menu.ghost_link': 'Ghost Link',
    'menu.phantom': 'T2C-Phantom',
    'menu.coming_soon': 'Prochainement',
    'menu.phantom_coming_soon': 'T2C-Phantom arrive bientôt — terminal pédagogique offline développé par l\'association.',
    'language.select_title': 'Choisissez votre langue',
    'home.banner.title': 'APPRENDRE.\nCONSTRUIRE.\nCOMPRENDRE.',
    'home.banner.subtitle': 'Comprendre l’informatique. Créer ses propres outils. Reprendre le contrôle.',
    'home.banner.explore': 'Explorer',
  };

  // Legacy export-tab helpers (empty until a sheet is linked from editor).
  final _csEntries = <CheatEntry>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TdcOnboardingDialog.showIfNeeded(context);
    });
    for (final k in _localeKeysList) {
      _localeKeys[k] = TextEditingController();
    }
    _sourceLocaleValues.addAll(_defaultSourceValues);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _localeKeys.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Génération .tdc v2 ──
  String _generateCheatSheetsTdc() {
    final sheetId = _csEntries.isEmpty ? 'cheat-sheets' : _slug(_csEntries.first.description);
    final resource = TdcResource(
      tdcVersion: '2',
      type: 'cheat_sheet',
      id: sheetId,
      concrete: TdcCheatSheet(
        id: sheetId,
        title: 'Cheat Sheets T2DECODE',
        category: _csEntries.isEmpty ? 'admin_sys' : _csEntries.first.category,
        dangerLevel: _csEntries.isEmpty
            ? 1
            : _csEntries.map((e) => e.dangerLevel).reduce((a, b) => a > b ? a : b),
        entries: _csEntries
            .map((e) => TdcCheatEntry(
                  id: e.id,
                  command: e.command,
                  description: e.description,
                  explanation: e.explanation,
                  options: e.options,
                  examples: e.examples,
                ))
            .toList(),
      ),
    );
    return TdcSerializerV2.serialize(resource);
  }

  String _generateLocaleTdc() {
    final code = _localeCode.value;
    final values = <String, String>{};
    for (final k in _localeKeysList) {
      final target = _localeKeys[k]?.text.trim() ?? '';
      final v = target.isNotEmpty ? target : _sourceLocaleValues[k];
      if (v == null || v.isEmpty) continue;
      values[k] = v;
    }
    final resource = TdcResource(
      tdcVersion: '2',
      type: 'locale',
      id: code,
      concrete: TdcLocale(id: code, values: values),
    );
    return TdcSerializerV2.serialize(resource);
  }

  String _slug(String input) {
    final slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (slug.isEmpty) return 'cheat-sheet';
    return slug.length > 40 ? slug.substring(0, 40) : slug;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code .tdc copié dans le presse-papier !')),
    );
  }

  Future<void> _importCoursePreview() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'TDC', extensions: ['tdc']),
    ]);
    if (file == null) return;
    try {
      final text = await File(file.path).readAsString(encoding: utf8);
      final courses = TdcImportParser.parseCourses(text);
      if (courses.isEmpty) {
        _showSnack('Aucun cours trouvé dans ce fichier .tdc');
        return;
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => _CoursePreviewDialog(courses: courses),
      );
    } catch (e) {
      _showSnack('Erreur import : $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportToAssets() async {
    final dir = await getDirectoryPath(
      confirmButtonText: 'Sélectionner le dossier assets',
    );
    if (dir == null) return;

    try {
      final assetsDir = Directory(dir);
      await assetsDir.create(recursive: true);

      final csFile = File('${assetsDir.path}/cheat_sheets.tdc');
      await csFile.writeAsString(_generateCheatSheetsTdc(), encoding: utf8);

      final localeFile = File('${assetsDir.path}/locale_${_localeCode.value}.tdc');
      await localeFile.writeAsString(_generateLocaleTdc(), encoding: utf8);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fichiers écrits dans ${assetsDir.path} :\ncheat_sheets.tdc, locale_${_localeCode.value}.tdc',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBDA).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF5EBDA).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'TDC Studio',
                style: TextStyle(
                  color: Color(0xFFF5EBDA),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dev & Traduction',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF5EBDA),
          labelColor: const Color(0xFFF5EBDA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.terminal), text: 'Cheat Sheets'),
            Tab(icon: Icon(Icons.language), text: 'Locales UI'),
            Tab(icon: Icon(Icons.code), text: 'Export .TDC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CheatSheetEditor(
            key: const PageStorageKey('cheat_sheets_editor'),
            askHowToStart: !_cheatSheetSessionStarted,
            onBootstrapped: () {
              if (_cheatSheetSessionStarted) return;
              setState(() => _cheatSheetSessionStarted = true);
            },
          ),
          const LocaleEditor(key: PageStorageKey('locales_editor')),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exporter les ressources de l\'app',
              style: TextStyle(
                color: Color(0xFFF5EBDA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _exportToAssets,
            icon: const Icon(Icons.folder_open),
            label: const Text('Exporter dans le dossier T2DECODE/assets'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5EBDA),
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _importCoursePreview,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer un cours .tdc (aperçu)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
              foregroundColor: const Color(0xFFF5EBDA),
              side: const BorderSide(color: Color(0xFFF5EBDA)),
            ),
          ),
          const SizedBox(height: 24),
          _exportCard('Cheat Sheets (.tdc v2)', _generateCheatSheetsTdc()),
          const SizedBox(height: 16),
          _exportCard('Locale UI (.tdc v2)', _generateLocaleTdc()),
        ],
      ),
    );
  }

  Widget _exportCard(String title, String code) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Color(0xFFF5EBDA),
                      fontWeight: FontWeight.bold,
                    )),
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
                  tooltip: 'Copier',
                  onPressed: () => _copy(code),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFF5EBDA),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePreviewDialog extends StatelessWidget {
  final List<ParsedCourse> courses;
  const _CoursePreviewDialog({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu du cours importé',
              style: TextStyle(
                color: Color(0xFFF5EBDA),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: courses.length,
                itemBuilder: (context, i) {
                  final c = courses[i];
                  return ExpansionTile(
                    title: Text(c.title.isEmpty ? c.id : c.title,
                        style: const TextStyle(color: Color(0xFFF5EBDA))),
                    subtitle: Text('${c.modules.length} modules — ${c.duration}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    children: c.modules
                        .map((m) => ListTile(
                              title: Text(m.title,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(m.duration,
                                  style: const TextStyle(color: Colors.white54)),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5EBDA),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheatEntry {
  final String id;
  String command;
  String description;
  String category;
  int dangerLevel;
  String explanation;
  List<String> options;
  List<String> examples;

  CheatEntry({
    required this.command,
    required this.description,
    this.category = 'Admin Sys',
    this.dangerLevel = 1,
    this.explanation = '',
    this.options = const [],
    this.examples = const [],
  }) : id = _slug(command);

  static String _slug(String cmd) {
    final s = cmd
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.length > 48 ? s.substring(0, 48) : s;
  }
}
