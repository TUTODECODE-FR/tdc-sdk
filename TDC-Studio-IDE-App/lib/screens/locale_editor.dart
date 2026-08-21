// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// TDC Studio — Éditeur de Locales UI
// ============================================================
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import '../tdc_import_parser.dart';
import '../widgets/studio_help_button.dart';

/// Éditeur de traduction UI pour les locales .tdc.
class LocaleEditor extends StatefulWidget {
  const LocaleEditor({super.key});

  @override
  State<LocaleEditor> createState() => _LocaleEditorState();
}

class _LocaleEditorState extends State<LocaleEditor>
    with AutomaticKeepAliveClientMixin {
  final _localeKeys = <String, TextEditingController>{};
  final _sourceValues = <String, String>{};
  final _targetValues = <String, String>{};
  final _localeCode = ValueNotifier<String>('en');
  String _sourceCode = 'fr';
  bool _isLoading = true;
  String _status = '';

  @override
  bool get wantKeepAlive => true;

  static const _supportedTargets = ['en', 'es', 'de', 'ar', 'zh', 'it', 'pt'];

  List<StudioAction> get _actions => [
        StudioAction(
          icon: Icons.language,
          label: 'Changer référence',
          help:
              'Charge une autre langue de référence (textes sous chaque clé). '
              'Ne remplit PAS les champs de traduction.',
          onPressed: _importSource,
        ),
        StudioAction(
          icon: Icons.upload_file,
          label: 'Reprendre traduction',
          help:
              'Charge un locale_xx.tdc déjà commencé dans les champs éditables. '
              'La référence ($_sourceCode) reste intacte.',
          onPressed: _importTarget,
        ),
        StudioAction(
          icon: Icons.copy,
          label: 'Copier',
          help: 'Copie le .tdc v2 de la langue cible dans le presse-papier.',
          onPressed: _copy,
        ),
        StudioAction(
          icon: Icons.download,
          label: 'Exporter',
          help:
              'Enregistre locale_<code>.tdc — à placer dans T2DECODE/assets/.',
          onPressed: _export,
          primary: true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  @override
  void dispose() {
    for (final c in _localeKeys.values) {
      c.dispose();
    }
    _localeCode.dispose();
    super.dispose();
  }

  Future<void> _loadSource() async {
    try {
      final source = await rootBundle.loadString('assets/locales/fr.tdc');
      final locales = TdcImportParser.parseLocales(source);
      if (locales.isEmpty) {
        setState(() => _status = 'Aucune locale source trouvée dans assets/locales/fr.tdc');
        return;
      }
      final locale = locales.first;
      _applySourceLocale(locale.code, locale.values);
      setState(() {
        _isLoading = false;
        _status =
            'Référence $_sourceCode : ${_sourceValues.length} clés (assets/locales/fr.tdc)';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Erreur chargement source : $e';
      });
    }
  }

  void _applySourceLocale(String code, Map<String, String> values) {
    _sourceCode = code;
    _sourceValues
      ..clear()
      ..addAll(values);
    // Keep existing translations when possible; create controllers for new keys.
    for (final k in values.keys) {
      _localeKeys.putIfAbsent(
        k,
        () => TextEditingController(text: _targetValues[k] ?? ''),
      );
    }
  }

  /// Loads an existing translation into the editable "Cible" fields.
  Future<void> _importTarget() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'TDC locale cible', extensions: ['tdc']),
      ],
      confirmButtonText: 'Charger la traduction',
    );
    if (file == null) return;
    try {
      final text = await File(file.path).readAsString(encoding: utf8);
      final locales = TdcImportParser.parseLocales(text);
      if (locales.isEmpty) {
        _showSnack('Aucune locale trouvée — ce fichier n\'est pas une traduction UI');
        return;
      }
      final locale = locales.first;
      var filled = 0;
      setState(() {
        _localeCode.value = locale.code;
        for (final entry in locale.values.entries) {
          _targetValues[entry.key] = entry.value;
          if (_localeKeys.containsKey(entry.key)) {
            _localeKeys[entry.key]!.text = entry.value;
            filled++;
          }
        }
        _status =
            'Traduction "${locale.code}" chargée dans les champs Cible ($filled / ${_sourceValues.length} clés)';
      });
      _showSnack(
        'Cible remplie : ${locale.code} — $filled clés traduites (la référence $_sourceCode n\'a pas changé)',
      );
    } catch (e) {
      _showSnack('Erreur import cible : $e');
    }
  }

  /// Replaces the reference language (keys + "Source :" hints).
  Future<void> _importSource() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'TDC locale source', extensions: ['tdc']),
      ],
      confirmButtonText: 'Charger la référence',
    );
    if (file == null) return;
    try {
      final text = await File(file.path).readAsString(encoding: utf8);
      final locales = TdcImportParser.parseLocales(text);
      if (locales.isEmpty) {
        _showSnack('Aucune locale trouvée — ce fichier n\'est pas une référence UI');
        return;
      }
      final locale = locales.first;
      setState(() {
        _applySourceLocale(locale.code, locale.values);
        _status =
            'Référence remplacée par "${locale.code}" (${locale.values.length} clés) — les champs Cible sont inchangés';
      });
      _showSnack(
        'Source = ${locale.code} (textes de référence). Utilisez « Cible .tdc » pour reprendre une traduction existante.',
      );
    } catch (e) {
      _showSnack('Erreur import source : $e');
    }
  }

  String _generateTdc() {
    final code = _localeCode.value;
    final sb = StringBuffer();
    sb.writeln('// SPDX-License-Identifier: GPL-3.0-only');
    sb.writeln('// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>');
    sb.writeln('// TUTODECODE UI Locale — format .tdc v2');
    sb.writeln();
    sb.writeln('tdc-version: 2');
    sb.writeln('type: locale');
    sb.writeln();
    sb.writeln('locale "$code" {');
    for (final k in _sourceValues.keys.toList()..sort()) {
      final target = _localeKeys[k]?.text.trim() ?? '';
      final value = target.isNotEmpty ? target : _sourceValues[k] ?? '';
      if (value.isEmpty) continue;
      sb.writeln('  $k: "$value"');
    }
    sb.writeln('}');
    return sb.toString();
  }

  Future<void> _export() async {
    final fileName = 'locale_${_localeCode.value}.tdc';
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return;
    try {
      await File(location.path).writeAsString(_generateTdc(), encoding: utf8);
      _showSnack('Exporté vers ${location.path}');
    } catch (e) {
      _showSnack('Erreur export : $e');
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _generateTdc()));
    _showSnack('Code .tdc copié dans le presse-papier');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int get _translatedCount {
    var count = 0;
    for (final entry in _localeKeys.entries) {
      if (entry.value.text.trim().isNotEmpty && entry.value.text.trim() != _sourceValues[entry.key]) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5EBDA)),
      );
    }

    final keys = _sourceValues.keys.toList()..sort();
    final progress = keys.isEmpty ? 0.0 : _translatedCount / keys.length;

    return Column(
      children: [
        _buildToolbar(keys.length, progress),
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _status,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              return _buildKeyCard(key);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Text('Réf. : $_sourceCode', style: const TextStyle(color: Color(0xFFF5EBDA))),
          const SizedBox(width: 16),
          const Text('Traduire vers :', style: TextStyle(color: Color(0xFFF5EBDA))),
          const SizedBox(width: 8),
          ValueListenableBuilder<String>(
            valueListenable: _localeCode,
            builder: (context, code, _) {
              return DropdownButton<String>(
                value: code,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Color(0xFFF5EBDA)),
                items: _supportedTargets
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _localeCode.value = v;
                },
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression : $_translatedCount/$total',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF5EBDA)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Aide — à quoi sert chaque bouton ?',
            onPressed: () => showStudioHelpDialog(
              context,
              title: 'Aide Locales UI',
              intro:
                  'Référence = textes à traduire. Cible = vos traductions. '
                  'Survolez un bouton pour un rappel rapide.',
              actions: _actions,
            ),
            icon: const Icon(Icons.help_outline, color: Color(0xFFF5EBDA)),
          ),
          for (final a in _actions) ...[
            const SizedBox(width: 8),
            StudioHelpButton(action: a),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyCard(String key) {
    final source = _sourceValues[key] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  color: Color(0xFFF5EBDA),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_sourceCode : $source',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _localeKeys[key],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Traduction (${_localeCode.value})',
                  hintText: source,
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 1,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
