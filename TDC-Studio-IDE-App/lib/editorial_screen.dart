// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio — Éditeur de Cours (mode "Éditorial")
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'services/export_paths.dart';
import 'services/recent_projects_service.dart';
import 'tdc_parser_v2.dart';
import 'widgets/export_location_dialog.dart';
import 'widgets/markdown_toolbar.dart';
import 'widgets/quiz_editor.dart';
import 'widgets/start_project_dialog.dart';
import 'widgets/tdc_code_editor.dart';
import 'widgets/tdc_highlighting_controller.dart';
import 'widgets/template_picker.dart';

class _ModuleData {
  String id;
  String title;
  String duration;
  final TextEditingController contentController;
  final List<QuizQuestionData> quiz;
  List<Map<String, String>> codeBlocks;

  _ModuleData({
    required this.id,
    required this.title,
    this.duration = '15min',
    String content = '',
    List<QuizQuestionData>? quiz,
    List<Map<String, String>>? codeBlocks,
  })  : contentController = TextEditingController(text: content),
        quiz = quiz ?? [],
        codeBlocks = codeBlocks ?? [];

  void dispose() => contentController.dispose();
}

class TdcEditorialScreen extends StatefulWidget {
  const TdcEditorialScreen({
    super.key,
    this.initialFilePath,
    this.askHowToStart = true,
  });

  /// Open this .tdc file directly (skips start dialog).
  final String? initialFilePath;

  /// When true and no initial file, show Import / From scratch / Template.
  final bool askHowToStart;

  @override
  State<TdcEditorialScreen> createState() => _TdcEditorialScreenState();
}

class _TdcEditorialScreenState extends State<TdcEditorialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final TdcHighlightingController _editorController;
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String _category = 'linux';
  String _level = 'beginner';
  String _duration = '2h';
  String _icon = 'Terminal';

  final List<_ModuleData> _modules = [];

  String _syntaxStatus = 'Éditeur vide';
  bool _hasSyntaxError = false;
  bool _dirty = false;
  String _saveStatus = 'Nouveau';
  String? _currentFilePath;
  Timer? _autoSaveTimer;
  Timer? _formToCodeDebounce;
  Timer? _codeToFormDebounce;
  bool _idManuallyEdited = false;
  bool _syncAuto = true;
  bool _syncing = false;
  List<TdcDiagnostic> _diagnostics = [];
  int _formEpoch = 0; // rebuild form fields after import

  int get _questionCount =>
      _modules.fold(0, (s, m) => s + m.quiz.length);

  int get _totalXp => _modules.fold(
        0,
        (s, m) => s + m.quiz.fold(0, (a, q) => a + q.xp),
      );

  String get _courseId => _idController.text;
  String get _courseTitle => _titleController.text;
  String get _courseDesc => _descController.text;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _editorController = TdcHighlightingController();
    _idController = TextEditingController();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_dirty || !mounted) return;
      setState(() {
        _dirty = false;
        _saveStatus = 'Brouillon auto';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.initialFilePath != null) {
      await _loadFromPath(widget.initialFilePath!);
      return;
    }
    if (!widget.askHowToStart) {
      _resetEmpty();
      return;
    }
    if (!mounted) return;
    final choice = await showStartProjectDialog(context);
    if (!mounted) return;
    switch (choice) {
      case StartProjectChoice.importFile:
        await _importFile();
        if (_currentFilePath == null && mounted) _resetEmpty();
      case StartProjectChoice.template:
        await _pickTemplate();
        if (_modules.isEmpty && mounted) _resetEmpty();
      case StartProjectChoice.fromScratch:
      case null:
        _resetEmpty();
    }
  }

  void _resetEmpty() {
    for (final m in _modules) {
      m.dispose();
    }
    _modules.clear();
    _idController.text = '';
    _titleController.text = '';
    _descController.text = '';
    _category = 'linux';
    _level = 'beginner';
    _duration = '2h';
    _icon = 'Terminal';
    _idManuallyEdited = false;
    _currentFilePath = null;
    _dirty = false;
    _saveStatus = 'Nouveau';
    _formEpoch++;
    _generateCodeFromForm();
    setState(() {});
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _formToCodeDebounce?.cancel();
    _codeToFormDebounce?.cancel();
    _tabController.dispose();
    _editorController.dispose();
    _idController.dispose();
    _titleController.dispose();
    _descController.dispose();
    for (final m in _modules) {
      m.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() {
      _dirty = true;
      _saveStatus = 'Modifié';
    });
  }

  String _slugify(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'course' : slug;
  }

  void _refreshSyntaxStatus() {
    final errs = _diagnostics.where((d) => d.isError).toList();
    final warns = _diagnostics.where((d) => !d.isError).toList();
    if (errs.isNotEmpty) {
      _hasSyntaxError = true;
      _syntaxStatus = errs.length == 1
          ? '❌ ${errs.first.message}'
          : '❌ ${errs.length} erreurs — ${errs.first.message}';
    } else if (warns.isNotEmpty) {
      _hasSyntaxError = false;
      _syntaxStatus = warns.length == 1
          ? '⚠️ ${warns.first.message}'
          : '⚠️ ${warns.length} alertes';
    } else if (_courseId.isEmpty && _modules.isEmpty) {
      _hasSyntaxError = false;
      _syntaxStatus = 'Éditeur vide';
    } else {
      _hasSyntaxError = false;
      _syntaxStatus = '✅ Tout est correct';
    }
  }

  void _onFormChanged() {
    _markDirty();
    if (!_syncAuto || _syncing) {
      setState(() {});
      return;
    }
    _formToCodeDebounce?.cancel();
    _formToCodeDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _syncing) return;
      _syncing = true;
      _generateCodeFromForm();
      _syncing = false;
      setState(() {});
    });
    setState(() {});
  }

  void _onCodeChanged(String code) {
    _markDirty();
    _diagnostics = diagnosticsFromCode(code);
    _refreshSyntaxStatus();

    if (!_syncAuto || _syncing || _hasSyntaxError) {
      setState(() {});
      return;
    }
    _codeToFormDebounce?.cancel();
    _codeToFormDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _syncing || _hasSyntaxError) return;
      try {
        final resource = TdcParserV2.parse(code);
        if (resource.type != 'course') return;
        _syncing = true;
        _applyResource(resource, regenerateCode: false);
        _syncing = false;
      } catch (_) {}
      setState(() {});
    });
    setState(() {});
  }

  void _generateCodeFromForm() {
    final resource = _toResource();
    final code = TdcSerializerV2.serialize(resource);
    if (_editorController.text != code) {
      _editorController.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
    _diagnostics = diagnosticsFromCode(code);
    _refreshSyntaxStatus();
  }

  TdcResource _toResource() {
    return TdcResource(
      tdcVersion: '2',
      type: 'course',
      id: _courseId.isEmpty ? 'untitled' : _courseId,
      concrete: TdcCourse(
        id: _courseId.isEmpty ? 'untitled' : _courseId,
        title: _courseTitle,
        description: _courseDesc,
        category: _category,
        level: _level,
        duration: _duration,
        icon: _icon,
        modules: _modules.map((m) {
          return TdcModule(
            id: m.id,
            title: m.title,
            duration: m.duration,
            content: m.contentController.text,
            codeBlocks: m.codeBlocks
                .map((cb) => TdcCodeBlock(
                      language: cb['language'] ?? 'bash',
                      title: cb['title'] ?? '',
                      code: cb['code'] ?? '',
                    ))
                .toList(),
            questions: m.quiz
                .map((q) => TdcQuestion(
                      text: q.question,
                      explanation: q.explanation.isEmpty ? null : q.explanation,
                      choices: [
                        for (var i = 0; i < q.choices.length; i++)
                          TdcChoice(text: q.choices[i], correct: i == q.correctIndex),
                      ],
                    ))
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  void _applyResource(TdcResource resource, {bool regenerateCode = true}) {
    final course = resource.asCourse;
    for (final m in _modules) {
      m.dispose();
    }
    _modules.clear();
    _idController.text = course.id;
    _titleController.text = course.title;
    _descController.text = course.description;
    _category = course.category;
    _level = course.level;
    _duration = course.duration;
    _icon = course.icon;
    _idManuallyEdited = true;
    _formEpoch++;
    for (final m in course.modules) {
      _modules.add(_ModuleData(
        id: m.id,
        title: m.title,
        duration: m.duration,
        content: m.content,
        codeBlocks: m.codeBlocks
            .map((cb) => {
                  'language': cb.language,
                  'title': cb.title,
                  'code': cb.code,
                })
            .toList(),
        quiz: m.questions.map((q) {
          final correctIndex = q.choices.indexWhere((c) => c.correct);
          return QuizQuestionData(
            question: q.text,
            choices: q.choices.map((c) => c.text).toList(),
            correctIndex: correctIndex < 0 ? 0 : correctIndex,
            explanation: q.explanation ?? '',
            xp: 10,
          );
        }).toList(),
      ));
    }
    _dirty = false;
    _saveStatus = 'Chargé';
    if (regenerateCode) _generateCodeFromForm();
  }

  void _applyCodeToForm() {
    try {
      final resource = TdcParserV2.parse(_editorController.text);
      if (resource.type != 'course') {
        _showSnack('Le fichier n\'est pas un course (type: ${resource.type})');
        return;
      }
      setState(() => _applyResource(resource));
      _showSnack('Formulaire mis à jour depuis le code');
    } catch (e) {
      _showSnack('Erreur parse : $e');
    }
  }

  Future<void> _pickTemplate() async {
    final selected = await showTemplatePicker(context);
    if (selected == null) return;
    setState(() => _applyResource(selected));
    _showSnack('Template "${selected.title}" chargé');
  }

  Future<void> _importFile() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'TDC', extensions: ['tdc']),
    ]);
    if (file == null) return;
    await _loadFromPath(file.path);
  }

  Future<void> _loadFromPath(String path) async {
    try {
      final text = await File(path).readAsString(encoding: utf8);
      final resource = TdcParserV2.parse(text);
      if (resource.type != 'course') {
        _showSnack('Ce fichier n\'est pas un course (type: ${resource.type})');
        return;
      }
      setState(() {
        _applyResource(resource);
        _currentFilePath = path;
        _saveStatus = 'Ouvert';
      });
      await RecentProjectsService.add(RecentProject(
        path: path,
        id: resource.id,
        title: resource.asCourse.title,
        type: 'course',
        category: resource.asCourse.category,
        modifiedAt: DateTime.now(),
      ));
      _showSnack('Cours importé : ${resource.id}');
    } catch (e) {
      _showSnack('Erreur ouverture : $e');
    }
  }

  Future<void> _newProject() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text('Modifications non enregistrées',
              style: TextStyle(color: Color(0xFFF5EBDA))),
          content: const Text(
            'Continuer sans exporter ?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer')),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!mounted) return;
    final choice = await showStartProjectDialog(context);
    if (!mounted) return;
    switch (choice) {
      case StartProjectChoice.importFile:
        await _importFile();
      case StartProjectChoice.template:
        await _pickTemplate();
      case StartProjectChoice.fromScratch:
      case null:
        _resetEmpty();
    }
  }

  CourseExportCheck _buildCheck() {
    return CourseExportCheck.validate(
      id: _courseId,
      title: _courseTitle,
      description: _courseDesc,
      moduleCount: _modules.length,
      questionCount: _questionCount,
      syntaxOk: !_hasSyntaxError,
      syntaxMessages: _diagnostics.where((d) => d.isError).map((d) => d.message).toList(),
    );
  }

  Future<void> _export() async {
    _generateCodeFromForm();
    final check = _buildCheck();
    final relative = ExportPlacement.forCourse(
      category: _category,
      id: _courseId.isEmpty ? 'untitled' : _courseId,
    );
    final ok = await showExportLocationDialog(
      context: context,
      resourceType: 'course',
      relativePath: relative,
      check: check,
      fileName: '${_courseId.isEmpty ? 'untitled' : _courseId}.tdc',
    );
    if (!ok || !mounted) return;

    final location = await getSaveLocation(
      suggestedName: '${_courseId.isEmpty ? 'untitled' : _courseId}.tdc',
    );
    if (location == null) return;
    try {
      final code = TdcSerializerV2.serialize(_toResource());
      await File(location.path).writeAsString(code, encoding: utf8);
      setState(() {
        _currentFilePath = location.path;
        _dirty = false;
        _saveStatus = 'Exporté';
      });
      await RecentProjectsService.add(RecentProject(
        path: location.path,
        id: _courseId,
        title: _courseTitle.isEmpty ? _courseId : _courseTitle,
        type: 'course',
        category: _category,
        modifiedAt: DateTime.now(),
      ));
      if (mounted) {
        _showSnack('Exporté → ${location.path}');
      }
    } catch (e) {
      _showSnack('Erreur export : $e');
    }
  }

  Future<void> _save() async {
    if (_currentFilePath != null) {
      final check = _buildCheck();
      if (!check.ok) {
        await _export();
        return;
      }
      try {
        final code = TdcSerializerV2.serialize(_toResource());
        await File(_currentFilePath!).writeAsString(code, encoding: utf8);
        setState(() {
          _dirty = false;
          _saveStatus = 'Enregistré';
        });
        await RecentProjectsService.add(RecentProject(
          path: _currentFilePath!,
          id: _courseId,
          title: _courseTitle.isEmpty ? _courseId : _courseTitle,
          type: 'course',
          category: _category,
          modifiedAt: DateTime.now(),
        ));
        _showSnack('Enregistré');
      } catch (e) {
        _showSnack('Erreur sauvegarde : $e');
      }
      return;
    }
    await _export();
  }

  void _addModule() {
    setState(() {
      _modules.add(_ModuleData(
        id: 'module-${_modules.length + 1}',
        title: 'Nouveau chapitre',
        content: '# Nouveau chapitre\n\n',
      ));
    });
    _onFormChanged();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDiagnosticsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        if (_diagnostics.isEmpty && !_hasSyntaxError) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('✅ Tout est correct', style: TextStyle(color: Color(0xFF10B981))),
          );
        }
        final check = _buildCheck();
        final items = <String>[
          ...check.errors.map((e) => '❌ $e'),
          ...check.warnings.map((w) => '⚠️ $w'),
          ..._diagnostics.map((d) =>
              '${d.isError ? '❌' : '⚠️'} Ligne ${d.line}:${d.column} — ${d.message}'),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Diagnostics',
                style: TextStyle(color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _importFile,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _importFile,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _newProject,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newProject,
        const SingleActivator(LogicalKeyboardKey.keyE, meta: true): _export,
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): _export,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
                        color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _courseTitle.isEmpty ? 'Nouveau cours' : _courseTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showDiagnosticsSheet,
                  child: Text(
                    _syntaxStatus,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _hasSyntaxError
                          ? const Color(0xFFEF4444)
                          : (_syntaxStatus.startsWith('⚠️')
                              ? const Color(0xFFF59E0B)
                              : Colors.greenAccent),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _dirty
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _saveStatus,
                    style: TextStyle(
                      color: _dirty ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '${_modules.length} chap. · $_questionCount Q · $_totalXp XP',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _newProject,
                icon: const Icon(Icons.note_add, color: Color(0xFFF5EBDA), size: 18),
                label: const Text('Nouveau', style: TextStyle(color: Color(0xFFF5EBDA))),
              ),
              TextButton.icon(
                onPressed: _importFile,
                icon: const Icon(Icons.folder_open, color: Color(0xFFF5EBDA), size: 18),
                label: const Text('Ouvrir', style: TextStyle(color: Color(0xFFF5EBDA))),
              ),
              TextButton.icon(
                onPressed: _pickTemplate,
                icon: const Icon(Icons.dashboard_customize, color: Color(0xFFF5EBDA), size: 18),
                label: const Text('Templates', style: TextStyle(color: Color(0xFFF5EBDA))),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFFF5EBDA)),
                tooltip: 'Copier le code .TDC',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _editorController.text));
                  _showSnack('Code .TDC copié');
                },
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Color(0xFFF5EBDA)),
                tooltip: 'Enregistrer (Ctrl+S)',
                onPressed: _save,
              ),
              ElevatedButton.icon(
                onPressed: _export,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exporter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5EBDA),
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF5EBDA),
              labelColor: const Color(0xFFF5EBDA),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note), text: 'Formulaire Studio'),
                Tab(icon: Icon(Icons.code), text: 'Éditeur .TDC'),
                Tab(icon: Icon(Icons.remove_red_eye), text: 'Aperçu Direct'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(),
              TdcCodeEditor(
                controller: _editorController,
                diagnostics: _diagnostics,
                syncAuto: _syncAuto,
                applyEnabled: !_hasSyntaxError,
                onSyncAutoChanged: (v) => setState(() => _syncAuto = v),
                onApplyToForm: _applyCodeToForm,
                onChanged: _onCodeChanged,
              ),
              _buildPreviewTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            key: ValueKey('form-$_formEpoch'),
            padding: const EdgeInsets.all(20),
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Informations du Cours',
                    style: TextStyle(
                        color: Color(0xFFF5EBDA), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'ID du Cours *', border: OutlineInputBorder()),
                        onChanged: (_) {
                          _idManuallyEdited = true;
                          _onFormChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Titre du Cours *', border: OutlineInputBorder()),
                        onChanged: (v) {
                          if (!_idManuallyEdited) {
                            _idController.text = _slugify(v);
                          }
                          _onFormChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Description Pédagogique *', border: OutlineInputBorder()),
                  onChanged: (_) => _onFormChanged(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                            labelText: 'Catégorie', border: OutlineInputBorder()),
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: const [
                          'linux',
                          'network',
                          'security',
                          'system',
                          'cloud',
                          'crypto',
                          'web',
                          'general',
                        ]
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                          _onFormChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _level,
                        decoration: const InputDecoration(
                            labelText: 'Niveau', border: OutlineInputBorder()),
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: const ['beginner', 'intermediate', 'advanced']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _level = v);
                          _onFormChanged();
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
                        initialValue: const ['15min', '30min', '1h', '2h', '3h', '4h', '6h', '8h']
                                .contains(_duration)
                            ? _duration
                            : '2h',
                        decoration: const InputDecoration(
                          labelText: 'Durée estimée',
                          helperText: 'Affichée dans T2DECODE',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: const ['15min', '30min', '1h', '2h', '3h', '4h', '6h', '8h']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _duration = v);
                          _onFormChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: const [
                          'Terminal',
                          'Network',
                          'Shield',
                          'Cloud',
                          'Lock',
                          'Code',
                          'Server',
                          'Book',
                        ].contains(_icon)
                            ? _icon
                            : 'Terminal',
                        decoration: const InputDecoration(
                          labelText: 'Icône',
                          helperText: 'Icône du cours dans l\'app',
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: const Color(0xFF1E1E1E),
                        items: const [
                          DropdownMenuItem(value: 'Terminal', child: Text('Terminal')),
                          DropdownMenuItem(value: 'Network', child: Text('Network')),
                          DropdownMenuItem(value: 'Shield', child: Text('Shield')),
                          DropdownMenuItem(value: 'Cloud', child: Text('Cloud')),
                          DropdownMenuItem(value: 'Lock', child: Text('Lock')),
                          DropdownMenuItem(value: 'Code', child: Text('Code')),
                          DropdownMenuItem(value: 'Server', child: Text('Server')),
                          DropdownMenuItem(value: 'Book', child: Text('Book')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _icon = v);
                          _onFormChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note : mots-clés et auteur ne font pas partie du schéma .tdc v2 '
                  '(course) — la signature Ed25519 arrive en Vague 3.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('2. Chapitres & Modules',
                        style: TextStyle(
                            color: Color(0xFFF5EBDA),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addModule,
                      icon: const Icon(Icons.add, color: Color(0xFFF5EBDA)),
                      label: const Text('Chapitre', style: TextStyle(color: Color(0xFFF5EBDA))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Glisser-déposer pour réordonner',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 12),
              ],
            ),
            itemCount: _modules.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _modules.removeAt(oldIndex);
                _modules.insert(newIndex, item);
              });
              _onFormChanged();
            },
            itemBuilder: (context, index) => _buildModuleCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(int index) {
    final m = _modules[index];
    return Card(
      key: ValueKey('${m.id}-$index'),
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: m.title,
                    style: const TextStyle(
                        color: Color(0xFFF5EBDA), fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Titre du chapitre',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      m.title = v;
                      _onFormChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: m.duration,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Durée',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      m.duration = v;
                      _onFormChanged();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      m.dispose();
                      _modules.removeAt(index);
                    });
                    _onFormChanged();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownToolbar(
              onWrap: (before, after, {placeholder}) {
                applyMarkdownWrap(m.contentController, before, after, placeholder: placeholder);
                _onFormChanged();
              },
              onSnippet: (snippet) {
                applyMarkdownSnippet(m.contentController, snippet);
                _onFormChanged();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: m.contentController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contenu Markdown',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _onFormChanged(),
            ),
            const SizedBox(height: 16),
            QuizEditor(
              questions: m.quiz,
              onChanged: _onFormChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_courseTitle.isEmpty && _modules.isEmpty) {
      return const Center(
        child: Text(
          'Cours vide — ajoutez un titre et un chapitre,\nou importez un .tdc / template.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5EBDA).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBDA).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_category.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFFF5EBDA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(_level, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(_duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Text(
                      '$_totalXp XP',
                      style: const TextStyle(
                          color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _courseTitle.isEmpty ? '(Sans titre)' : _courseTitle,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _courseDesc.isEmpty ? '(Sans description)' : _courseDesc,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._modules.map((m) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title,
                    style: const TextStyle(
                        color: Color(0xFFF5EBDA), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: m.contentController.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    h1: const TextStyle(
                        color: Color(0xFFF5EBDA), fontSize: 22, fontWeight: FontWeight.bold),
                    h2: const TextStyle(
                        color: Color(0xFFF5EBDA), fontSize: 18, fontWeight: FontWeight.bold),
                    code: const TextStyle(color: Color(0xFFC3E88D), fontFamily: 'monospace'),
                  ),
                ),
                if (m.quiz.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  QuizPreview(questions: m.quiz),
                ],
                const SizedBox(height: 28),
              ],
            );
          }),
        ],
      ),
    );
  }
}
