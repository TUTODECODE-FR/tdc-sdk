// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Syntax-highlighting TextEditingController for .tdc v2.
library;

import 'package:flutter/material.dart';

/// Highlights TDC keywords, strings, comments, operators and numbers.
class TdcHighlightingController extends TextEditingController {
  TdcHighlightingController({super.text});

  static const keywordColor = Color(0xFFC792EA); // purple
  static const stringColor = Color(0xFFC3E88D); // green
  static const commentColor = Color(0xFF78909C); // grey-blue
  static const numberColor = Color(0xFFF78C6C); // orange
  static const operatorColor = Color(0xFF89DDFF); // cyan
  static const defaultColor = Color(0xFFECEFF1); // light grey (not pure white)

  static const _keywordSet = {
    'tdc-version',
    'type',
    'course',
    'module',
    'content',
    'codeblock',
    'quiz',
    'question',
    'cheat_sheet',
    'entry',
    'locale',
    'template',
    'structure',
    'modules',
    'asset_pack',
    'assets',
    'icon',
    'image',
    'title',
    'description',
    'category',
    'level',
    'duration',
    'explanation',
    'command',
    'options',
    'examples',
    'warnings',
    'danger_level',
    'code',
    'content_template',
    'module_count',
    'quiz_per_module',
    'total_xp',
    'source',
    'alt',
    'version',
  };

  /// Public helper for tests / overlay rendering.
  TextSpan buildHighlightedSpan({TextStyle? style}) {
    return _buildSpan(style ?? const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5));
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      fontFamily: 'monospace',
      fontSize: style?.fontSize ?? 14,
      height: style?.height ?? 1.5,
      // Keep a fallback color; per-span colors override it.
      color: defaultColor,
    );
    return _buildSpan(base);
  }

  TextSpan _buildSpan(TextStyle base) {
    final source = text;
    if (source.isEmpty) {
      return TextSpan(style: base.copyWith(color: defaultColor), text: '');
    }

    final spans = <InlineSpan>[];
    var i = 0;
    while (i < source.length) {
      // Line comments
      if (source.startsWith('//', i)) {
        final end = source.indexOf('\n', i);
        final stop = end < 0 ? source.length : end;
        spans.add(TextSpan(
          text: source.substring(i, stop),
          style: base.copyWith(color: commentColor, fontStyle: FontStyle.italic),
        ));
        i = stop;
        continue;
      }

      // Triple-quoted strings
      if (source.startsWith('"""', i)) {
        final end = source.indexOf('"""', i + 3);
        final stop = end < 0 ? source.length : end + 3;
        spans.add(TextSpan(
          text: source.substring(i, stop),
          style: base.copyWith(color: stringColor),
        ));
        i = stop;
        continue;
      }

      // Double-quoted strings
      if (source[i] == '"') {
        var j = i + 1;
        while (j < source.length && source[j] != '"') {
          if (source[j] == '\\' && j + 1 < source.length) {
            j += 2;
          } else {
            j++;
          }
        }
        if (j < source.length) j++;
        spans.add(TextSpan(
          text: source.substring(i, j),
          style: base.copyWith(color: stringColor),
        ));
        i = j;
        continue;
      }

      // Operators / braces
      if ('{}[]:+-,'.contains(source[i])) {
        spans.add(TextSpan(
          text: source[i],
          style: base.copyWith(color: operatorColor),
        ));
        i++;
        continue;
      }

      // Numbers
      if (_isDigit(source[i])) {
        var j = i + 1;
        while (j < source.length && (_isDigit(source[j]) || source[j] == '.')) {
          j++;
        }
        spans.add(TextSpan(
          text: source.substring(i, j),
          style: base.copyWith(color: numberColor),
        ));
        i = j;
        continue;
      }

      // Identifiers / keywords (incl. tdc-version, cheat_sheet)
      if (_isIdentStart(source[i])) {
        var j = i + 1;
        while (j < source.length && _isIdentPart(source[j])) {
          j++;
        }
        final word = source.substring(i, j);
        final isKw = _keywordSet.contains(word);
        // Color only — bold changes glyph metrics and desyncs line numbers.
        spans.add(TextSpan(
          text: word,
          style: base.copyWith(color: isKw ? keywordColor : defaultColor),
        ));
        i = j;
        continue;
      }

      spans.add(TextSpan(text: source[i], style: base.copyWith(color: defaultColor)));
      i++;
    }

    return TextSpan(style: base, children: spans);
  }

  static bool _isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
  static bool _isIdentStart(String c) =>
      (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
      (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
      c == '_';
  static bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c) || c == '.' || c == '-';
}
