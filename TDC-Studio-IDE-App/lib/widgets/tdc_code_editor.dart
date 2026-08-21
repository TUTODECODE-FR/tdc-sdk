// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Code editor with line numbers, highlighting and clickable diagnostics.
library;

import 'package:flutter/material.dart';
import '../tdc_parser_v2.dart';
import 'tdc_highlighting_controller.dart';

class TdcDiagnostic {
  final int line;
  final int column;
  final String message;
  final bool isError;

  const TdcDiagnostic({
    required this.line,
    required this.column,
    required this.message,
    this.isError = true,
  });
}

class TdcCodeEditor extends StatefulWidget {
  const TdcCodeEditor({
    super.key,
    required this.controller,
    required this.diagnostics,
    this.onChanged,
    this.onApplyToForm,
    this.applyEnabled = true,
    this.syncAuto = true,
    this.onSyncAutoChanged,
  });

  final TdcHighlightingController controller;
  final List<TdcDiagnostic> diagnostics;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onApplyToForm;
  final bool applyEnabled;
  final bool syncAuto;
  final ValueChanged<bool>? onSyncAutoChanged;

  @override
  State<TdcCodeEditor> createState() => _TdcCodeEditorState();
}

class _TdcCodeEditorState extends State<TdcCodeEditor> {
  static const double _fontSize = 14;
  static const double _lineHeightFactor = 1.5;
  static const double _lineExtent = _fontSize * _lineHeightFactor; // 21
  static const double _pad = 12;

  final _scrollController = ScrollController();
  final _lineScrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncLineScroll);
    widget.controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant TdcCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTick);
    _scrollController.removeListener(_syncLineScroll);
    _scrollController.dispose();
    _lineScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncLineScroll() {
    if (_lineScrollController.hasClients &&
        _lineScrollController.offset != _scrollController.offset) {
      _lineScrollController.jumpTo(_scrollController.offset);
    }
  }

  int get _lineCount {
    final text = widget.controller.text;
    if (text.isEmpty) return 1;
    return '\n'.allMatches(text).length + 1;
  }

  void _jumpToLine(int line) {
    final lines = widget.controller.text.split('\n');
    var offset = 0;
    for (var i = 0; i < line - 1 && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    widget.controller.selection = TextSelection.collapsed(
      offset: offset.clamp(0, widget.controller.text.length),
    );
    _focusNode.requestFocus();
    if (!_scrollController.hasClients) return;
    final target = ((line - 1) * _lineExtent)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = _lineCount;
    final errorLines = {
      for (final d in widget.diagnostics.where((d) => d.isError)) d.line,
    };

    return Column(
      children: [
        _buildToolbar(),
        if (widget.diagnostics.isNotEmpty) _buildDiagnosticsBar(),
        Expanded(
          child: Container(
            color: const Color(0xFF050505),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 48,
                  child: ListView.builder(
                    controller: _lineScrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    // Same vertical padding as TextField contentPadding
                    // so line N lines up with text row N.
                    padding: const EdgeInsets.symmetric(vertical: _pad),
                    itemCount: lineCount,
                    itemExtent: _lineExtent,
                    itemBuilder: (context, i) {
                      final line = i + 1;
                      final isError = errorLines.contains(line);
                      return Container(
                        height: _lineExtent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        color: isError
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : null,
                        child: Text(
                          '$line',
                          style: TextStyle(
                            color: isError
                                ? const Color(0xFFEF4444)
                                : Colors.white24,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: _lineExtent / 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(width: 1, color: const Color(0xFF2A2A2A)),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFECEFF1),
                      fontSize: _fontSize,
                      height: _lineHeightFactor,
                    ),
                    strutStyle: const StrutStyle(
                      fontSize: _fontSize,
                      height: _lineHeightFactor,
                      forceStrutHeight: true,
                      fontFamily: 'monospace',
                    ),
                    cursorColor: const Color(0xFFF5EBDA),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(_pad),
                      isDense: true,
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          const Text('Sync auto', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Switch(
            value: widget.syncAuto,
            activeThumbColor: const Color(0xFFF5EBDA),
            onChanged: widget.onSyncAutoChanged,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.applyEnabled ? widget.onApplyToForm : null,
            icon: const Icon(Icons.sync_alt, size: 16),
            label: const Text('Appliquer au formulaire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5EBDA),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsBar() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      color: const Color(0xFF1A1010),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.diagnostics.length,
        itemBuilder: (context, i) {
          final d = widget.diagnostics[i];
          return InkWell(
            onTap: () => _jumpToLine(d.line),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    d.isError ? Icons.error_outline : Icons.warning_amber,
                    size: 14,
                    color: d.isError
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ligne ${d.line}:${d.column}',
                    style: TextStyle(
                      color: d.isError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Build diagnostics from parser exception / validation errors.
List<TdcDiagnostic> diagnosticsFromCode(String code) {
  final result = <TdcDiagnostic>[];
  try {
    final resource = TdcParserV2.parse(code);
    for (final err in resource.validate()) {
      result.add(TdcDiagnostic(
        line: 1,
        column: 1,
        message: err.message,
        isError: false,
      ));
    }
  } on TdcParseException catch (e) {
    result.add(TdcDiagnostic(
      line: e.line,
      column: e.column,
      message: e.message,
      isError: true,
    ));
  } catch (e) {
    result.add(TdcDiagnostic(line: 1, column: 1, message: e.toString()));
  }
  return result;
}
