// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio — Éditeur de Cheat Sheets (.tdc v2)
// ============================================================
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/templates/cheat_sheet_templates.dart';
import '../services/export_paths.dart';
import '../services/recent_projects_service.dart';
import '../tdc_parser_v2.dart';
import '../widgets/export_location_dialog.dart';
import '../widgets/start_project_dialog.dart';
import '../widgets/studio_help_button.dart';

/// Éditeur de fiches mémo au format .tdc v2.
class CheatSheetEditor extends StatefulWidget {
  const CheatSheetEditor({
    super.key,
    this.askHowToStart = true,
    this.onBootstrapped,
  });

  /// When false, skip the start dialog (session already started).
  final bool askHowToStart;

  /// Called once after the start dialog flow finishes (or is skipped).
  final VoidCallback? onBootstrapped;

  @override
  State<CheatSheetEditor> createState() => _CheatSheetEditorState();
}

class _CheatSheetEditorState extends State<CheatSheetEditor>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  String _category = 'admin_sys';
  int _dangerLevel = 1;
  final _entries = <TdcCheatEntry>[];
  final _expanded = <int>{};
  String _status = 'Nouveau — vide';
  int _formEpoch = 0;
  bool _ready = false;
  bool _bootstrapStarted = false;

  @override
  bool get wantKeepAlive => true;

  static const _categories = [
    'red_team',
    'blue_team',
    'admin_sys',
    'cloud',
    'network',
    'security',
    'web',
    'git',
  ];

  List<StudioAction> get _actions => [
        StudioAction(
          icon: Icons.note_add,
          label: 'Nouveau',
          help:
              'Repart de zéro : dialogue Importer / Template / Écrire de zéro. '
              'Rien n\'est prérempli sans votre choix.',
          onPressed: _newProject,
        ),
        StudioAction(
          icon: Icons.upload_file,
          label: 'Importer',
          help:
              'Ouvre un fichier .tdc de type cheat_sheet et remplit le formulaire.',
          onPressed: _import,
        ),
        StudioAction(
          icon: Icons.dashboard_customize,
          label: 'Templates',
          help: 'Charge un modèle (SSH, Nmap, Git…) à adapter.',
          onPressed: _pickTemplate,
        ),
        StudioAction(
          icon: Icons.copy,
          label: 'Copier',
          help: 'Copie le code .tdc v2 dans le presse-papier.',
          onPressed: _copy,
        ),
        StudioAction(
          icon: Icons.download,
          label: 'Exporter',
          help:
              'Valide la fiche, indique où la placer (assets/cheat_sheets/<catégorie>/), '
              'puis enregistre le fichier.',
          onPressed: _export,
          primary: true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _titleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;

    if (!widget.askHowToStart) {
      // Already started this session — do not wipe form, do not re-ask.
      if (mounted) setState(() => _ready = true);
      widget.onBootstrapped?.call();
      return;
    }

    if (!mounted) return;
    final choice = await showStartProjectDialog(
      context,
      title: 'Nouvelle Cheat Sheet',
      subtitle: 'Rien n\'est prérempli. Comment commencer ?',
      importSubtitle: 'Ouvrir une cheat sheet .tdc existante',
      scratchSubtitle: 'Fiche vide — ID, titre, puis vos commandes',
      templateTitle: 'Partir d\'un template',
      templateSubtitle: 'SSH, Nmap, Git… à personnaliser',
    );
    if (!mounted) return;
    switch (choice) {
      case StartProjectChoice.importFile:
        await _import();
        if (_entries.isEmpty) _resetEmpty();
      case StartProjectChoice.template:
        await _pickTemplate();
        if (_entries.isEmpty) _resetEmpty();
      case StartProjectChoice.fromScratch:
      case null:
        _resetEmpty();
    }
    if (mounted) setState(() => _ready = true);
    widget.onBootstrapped?.call();
  }

  void _resetEmpty() {
    _idController.text = '';
    _titleController.text = '';
    _category = 'admin_sys';
    _dangerLevel = 1;
    _entries.clear();
    _expanded.clear();
    _formEpoch++;
    _status = 'Nouveau — vide';
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String get _sheetId => _idController.text.trim();
  String get _sheetTitle => _titleController.text.trim();

  TdcResource _toResource() {
    return TdcResource(
      tdcVersion: '2',
      type: 'cheat_sheet',
      id: _sheetId.isEmpty ? 'untitled' : _sheetId,
      concrete: TdcCheatSheet(
        id: _sheetId.isEmpty ? 'untitled' : _sheetId,
        title: _sheetTitle,
        category: _category,
        dangerLevel: _dangerLevel,
        entries: List.from(_entries),
      ),
    );
  }

  String _generateTdc() => TdcSerializerV2.serialize(_toResource());

  void _applySheet(TdcCheatSheet sheet, {required String status}) {
    _idController.text = sheet.id;
    _titleController.text = sheet.title;
    _category = sheet.category;
    _dangerLevel = sheet.dangerLevel.clamp(1, 3);
    _entries
      ..clear()
      ..addAll(sheet.entries.map((e) => e.copyWith()));
    _expanded
      ..clear()
      ..addAll(List.generate(_entries.length, (i) => i));
    _formEpoch++;
    _status = status;
  }

  Future<void> _newProject() async {
    final choice = await showStartProjectDialog(
      context,
      title: 'Nouvelle Cheat Sheet',
      subtitle: 'Comment souhaitez-vous continuer ?',
      importSubtitle: 'Ouvrir une cheat sheet .tdc existante',
      scratchSubtitle: 'Effacer et repartir sur une fiche vide',
      templateTitle: 'Partir d\'un template',
      templateSubtitle: 'SSH, Nmap, Git…',
    );
    if (!mounted) return;
    switch (choice) {
      case StartProjectChoice.importFile:
        await _import();
      case StartProjectChoice.template:
        await _pickTemplate();
      case StartProjectChoice.fromScratch:
        setState(_resetEmpty);
      case null:
        break;
    }
  }

  Future<void> _pickTemplate() async {
    final selected = await showCheatSheetTemplatePicker(context);
    if (selected == null) return;
    setState(() {
      _applySheet(
        selected.asCheatSheet,
        status: 'Template "${selected.id}" chargé',
      );
    });
    _showSnack('Template "${selected.asCheatSheet.title}" chargé');
  }

  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'TDC', extensions: ['tdc']),
    ]);
    if (file == null) return;
    try {
      final text = await File(file.path).readAsString(encoding: utf8);
      final resource = TdcParserV2.parse(text);
      if (resource.type != 'cheat_sheet') {
        _showSnack('Ce fichier n\'est pas une cheat_sheet (type: ${resource.type})');
        return;
      }
      setState(() {
        _applySheet(
          resource.asCheatSheet,
          status: 'Importé : ${resource.asCheatSheet.entries.length} entrée(s)',
        );
      });
      await RecentProjectsService.add(RecentProject(
        path: file.path,
        id: resource.id,
        title: resource.asCheatSheet.title,
        type: 'cheat_sheet',
        category: resource.asCheatSheet.category,
        modifiedAt: DateTime.now(),
      ));
      _showSnack('Cheat sheet "${resource.id}" importée');
    } catch (e) {
      _showSnack('Erreur import : $e');
    }
  }

  Future<void> _export() async {
    final validation = _toResource().validate();
    final check = CourseExportCheck(
      ok: validation.isEmpty && _sheetId.isNotEmpty && _sheetTitle.isNotEmpty,
      errors: [
        if (_sheetId.isEmpty) 'ID de la cheat sheet manquant',
        if (_sheetTitle.isEmpty) 'Titre manquant',
        if (_entries.isEmpty) 'Au moins 1 entrée (commande) est requise',
        ...validation.map((e) => e.message),
      ],
    );
    final relative = ExportPlacement.forCheatSheet(
      category: _category,
      id: _sheetId.isEmpty ? 'untitled' : _sheetId,
    );
    final proceed = await showExportLocationDialog(
      context: context,
      resourceType: 'cheat_sheet',
      relativePath: relative,
      check: check,
      fileName: '${_sheetId.isEmpty ? 'untitled' : _sheetId}.tdc',
    );
    if (!proceed) return;
    final location = await getSaveLocation(
      suggestedName: '${_sheetId.isEmpty ? 'untitled' : _sheetId}.tdc',
    );
    if (location == null) return;
    try {
      await File(location.path).writeAsString(_generateTdc(), encoding: utf8);
      await RecentProjectsService.add(RecentProject(
        path: location.path,
        id: _sheetId,
        title: _sheetTitle,
        type: 'cheat_sheet',
        category: _category,
        modifiedAt: DateTime.now(),
      ));
      setState(() => _status = 'Exporté');
      _showSnack('Exporté vers ${location.path}');
    } catch (e) {
      _showSnack('Erreur export : $e');
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _generateTdc()));
    _showSnack('Code .tdc copié');
  }

  void _addEntry() {
    setState(() {
      final i = _entries.length;
      _entries.add(TdcCheatEntry(
        id: 'entry-${i + 1}',
        command: '',
        description: '',
      ));
      _expanded.add(i);
      _status = 'Modifié';
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _expanded.remove(index);
      _status = 'Modifié';
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _slugify(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'cheat-sheet' : slug;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5EBDA)),
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: ListView(
            key: ValueKey('cs-$_formEpoch'),
            padding: const EdgeInsets.all(20),
            children: [
              _buildMetaCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Commandes',
                    style: TextStyle(
                      color: Color(0xFFF5EBDA),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_entries.length} entrée(s)',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.add, color: Color(0xFFF5EBDA)),
                    label: const Text('Ajouter', style: TextStyle(color: Color(0xFFF5EBDA))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_entries.isEmpty)
                _buildEmptyEntriesHint()
              else
                ...List.generate(_entries.length, _buildEntryCard),
              const SizedBox(height: 12),
              _buildAddDashedCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Text(
            'Cheat Sheets .tdc v2',
            style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _status,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Aide — à quoi sert chaque bouton ?',
            onPressed: () => showStudioHelpDialog(
              context,
              title: 'Aide Cheat Sheets',
              intro:
                  'Une cheat sheet = une fiche de commandes pour T2DECODE (NetKit). '
                  'Survolez un bouton ou ouvrez cette aide pour comprendre chaque action.',
              actions: _actions,
            ),
            icon: const Icon(Icons.help_outline, color: Color(0xFFF5EBDA)),
          ),
          const SizedBox(width: 4),
          for (final a in _actions) ...[
            StudioHelpButton(action: a),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5EBDA).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Infos de la fiche',
            style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Identifiant unique + titre affiché dans T2DECODE. '
            'La catégorie décide du dossier d\'export.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ID *',
                    helperText: 'ex. ssh-basics',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _status = 'Modifié'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    helperText: 'Affiché aux apprenants',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    if (_idController.text.trim().isEmpty) {
                      _idController.text = _slugify(v);
                    }
                    setState(() => _status = 'Modifié');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_category) ? _category : _categories.first,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Color(0xFFF5EBDA)),
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    helperText: '→ dossier d\'export',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _dangerLevel,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Color(0xFFF5EBDA)),
                  decoration: const InputDecoration(
                    labelText: 'Niveau de danger',
                    helperText: 'Badge pédagogique',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 — Normal')),
                    DropdownMenuItem(value: 2, child: Text('2 — Prudence')),
                    DropdownMenuItem(value: 3, child: Text('3 — Sensible')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _dangerLevel = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEntriesHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Column(
        children: [
          Icon(Icons.terminal, color: Color(0xFFF5EBDA), size: 36),
          SizedBox(height: 12),
          Text(
            'Aucune commande pour l\'instant',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Ajoutez une entrée : commande, description pédagogique, options, exemples.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDashedCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addEntry,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: const Color(0xFFF5EBDA).withValues(alpha: 0.45)),
          child: const SizedBox(
            width: double.infinity,
            height: 64,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFFF5EBDA)),
                  SizedBox(width: 10),
                  Text(
                    'Ajouter une commande',
                    style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];
    final open = _expanded.contains(index);
    final preview = entry.command.isEmpty ? '(nouvelle commande)' : entry.command;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: open
                ? const Color(0xFFF5EBDA).withValues(alpha: 0.35)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (open) {
                    _expanded.remove(index);
                  } else {
                    _expanded.add(index);
                  }
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBDA).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFFF5EBDA),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: entry.command.isEmpty ? Colors.white38 : const Color(0xFFC3E88D),
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          if (entry.description.isNotEmpty)
                            Text(
                              entry.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white38,
                    ),
                    IconButton(
                      tooltip: 'Supprimer cette entrée',
                      onPressed: () => _removeEntry(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(
                  children: [
                    _field(
                      label: 'ID',
                      helper: 'Identifiant unique de la commande',
                      initial: entry.id,
                      onChanged: (v) => entry.id = v.trim(),
                    ),
                    _field(
                      label: 'Commande *',
                      helper: 'Syntaxe exacte affichée aux apprenants',
                      initial: entry.command,
                      mono: true,
                      onChanged: (v) {
                        entry.command = v;
                        setState(() {});
                      },
                    ),
                    _field(
                      label: 'Description *',
                      helper: 'En une phrase : à quoi sert la commande',
                      initial: entry.description,
                      onChanged: (v) {
                        entry.description = v;
                        setState(() {});
                      },
                    ),
                    _field(
                      label: 'Explication',
                      helper: 'Détail pédagogique (flags, contexte…)',
                      initial: entry.explanation,
                      maxLines: 3,
                      onChanged: (v) => entry.explanation = v,
                    ),
                    _field(
                      label: 'Options',
                      helper: 'Une option par ligne',
                      initial: entry.options.join('\n'),
                      maxLines: 2,
                      onChanged: (v) => entry.options = _lines(v),
                    ),
                    _field(
                      label: 'Exemples',
                      helper: 'Un exemple concret par ligne',
                      initial: entry.examples.join('\n'),
                      maxLines: 2,
                      mono: true,
                      onChanged: (v) => entry.examples = _lines(v),
                    ),
                    _field(
                      label: 'Avertissements',
                      helper: 'Risques, cadre légal… (une ligne = un warning)',
                      initial: entry.warnings.join('\n'),
                      maxLines: 2,
                      onChanged: (v) => entry.warnings = _lines(v),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _lines(String v) =>
      v.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Widget _field({
    required String label,
    required String helper,
    required String initial,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        style: TextStyle(
          color: Colors.white,
          fontFamily: mono ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
