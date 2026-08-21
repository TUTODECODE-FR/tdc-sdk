// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// Parser minimaliste d'import .tdc pour TDC Studio App
// Supporte : locale, entry, course
// ============================================================

class ParsedLocale {
  final String code;
  final Map<String, String> values;
  ParsedLocale({required this.code, required this.values});
}

class ParsedEntry {
  final String id;
  String command;
  String description;
  String category;
  int dangerLevel;
  String explanation;
  List<String> options;
  List<String> examples;

  ParsedEntry({
    required this.id,
    this.command = '',
    this.description = '',
    this.category = 'Admin Sys',
    this.dangerLevel = 1,
    this.explanation = '',
    this.options = const [],
    this.examples = const [],
  });
}

class ParsedCourse {
  final String id;
  String title;
  String description;
  String category;
  String level;
  String duration;
  List<ParsedModule> modules;

  ParsedCourse({
    required this.id,
    this.title = '',
    this.description = '',
    this.category = 'linux',
    this.level = 'beginner',
    this.duration = '',
    this.modules = const [],
  });
}

class ParsedModule {
  final String id;
  String title;
  String duration;
  String content;

  ParsedModule({
    required this.id,
    this.title = '',
    this.duration = '',
    this.content = '',
  });
}

class TdcImportParser {
  TdcImportParser._();

  static List<ParsedLocale> parseLocales(String source) {
    final locales = <ParsedLocale>[];
    final re = RegExp(r'locale\s+"([^"]+)"\s*\{', multiLine: true);
    for (final m in re.allMatches(source)) {
      final code = m.group(1)!;
      final body = _blockBody(source, m.end);
      final values = <String, String>{};
      for (final line in body.split('\n')) {
        final kv = _parseKeyValue(line.trim());
        if (kv != null) values[kv.key] = kv.value;
      }
      locales.add(ParsedLocale(code: code, values: values));
    }
    return locales;
  }

  static List<ParsedEntry> parseEntries(String source) {
    final entries = <ParsedEntry>[];
    final re = RegExp(r'entry\s+"([^"]+)"\s*\{', multiLine: true);
    for (final m in re.allMatches(source)) {
      final id = m.group(1)!;
      final body = _blockBody(source, m.end);
      final entry = ParsedEntry(id: id);
      _fillEntry(entry, body);
      entries.add(entry);
    }
    return entries;
  }

  static List<ParsedCourse> parseCourses(String source) {
    final courses = <ParsedCourse>[];
    final re = RegExp(r'course\s+"([^"]+)"\s*\{', multiLine: true);
    for (final m in re.allMatches(source)) {
      final id = m.group(1)!;
      final body = _blockBody(source, m.end);
      final course = ParsedCourse(id: id);
      _fillCourse(course, body);
      courses.add(course);
    }
    return courses;
  }

  static String _blockBody(String source, int startOffset) {
    int depth = 1;
    int pos = startOffset;
    while (pos < source.length && depth > 0) {
      final c = source[pos];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) break;
      }
      pos++;
    }
    return source.substring(startOffset, pos).trim();
  }

  static _KeyValue? _parseKeyValue(String line) {
    if (line.isEmpty || line.startsWith('//')) return null;
    final idx = line.indexOf(':');
    if (idx <= 0) return null;
    final key = line.substring(0, idx).trim();
    var raw = line.substring(idx + 1).trim();
    if (raw.startsWith('"""')) {
      raw = raw.substring(3);
      if (raw.endsWith('"""')) raw = raw.substring(0, raw.length - 3);
    } else if (raw.startsWith('"') && raw.endsWith('"')) {
      raw = raw.substring(1, raw.length - 1);
    }
    return _KeyValue(key, raw);
  }

  static void _fillEntry(ParsedEntry entry, String body) {
    final lines = body.split('\n');
    String? tripleBuffer;
    String? tripleKey;

    for (var raw in lines) {
      var line = raw.trimRight();
      if (line.trim().startsWith('//')) continue;

      if (tripleBuffer != null) {
        if (line.trim() == '"""') {
          _setEntryField(entry, tripleKey!, tripleBuffer.trim());
          tripleBuffer = null;
          tripleKey = null;
        } else {
          tripleBuffer += '\n$line';
        }
        continue;
      }

      final kv = _parseKeyValue(line.trim());
      if (kv == null) continue;

      if (line.trim().substring(kv.key.length + 1).trim().startsWith('"""')) {
        tripleKey = kv.key;
        tripleBuffer = kv.value;
        continue;
      }

      _setEntryField(entry, kv.key, kv.value);
    }
  }

  static void _setEntryField(ParsedEntry entry, String key, String value) {
    switch (key) {
      case 'command':
        entry.command = value;
      case 'description':
        entry.description = value;
      case 'category':
        entry.category = value;
      case 'dangerLevel':
        entry.dangerLevel = int.tryParse(value) ?? 1;
      case 'explanation':
        entry.explanation = value;
      case 'options':
        entry.options = _parseList(value);
      case 'examples':
        entry.examples = _parseList(value);
    }
  }

  static void _fillCourse(ParsedCourse course, String body) {
    final lines = body.split('\n');
    String? tripleBuffer;
    String? tripleKey;
    final modules = <ParsedModule>[];

    for (var raw in lines) {
      var line = raw.trimRight();
      if (line.trim().startsWith('//')) continue;

      final moduleMatch = RegExp(r'module\s+"([^"]+)"\s*\{').firstMatch(line);
      if (moduleMatch != null) {
        final moduleBody = _blockBody(body, moduleMatch.end + (line.length - line.trimLeft().length));
        final module = ParsedModule(id: moduleMatch.group(1)!);
        _fillModule(module, moduleBody);
        modules.add(module);
        continue;
      }

      if (tripleBuffer != null) {
        if (line.trim() == '"""') {
          _setCourseField(course, tripleKey!, tripleBuffer.trim());
          tripleBuffer = null;
          tripleKey = null;
        } else {
          tripleBuffer += '\n$line';
        }
        continue;
      }

      final kv = _parseKeyValue(line.trim());
      if (kv == null) continue;

      if (line.trim().substring(kv.key.length + 1).trim().startsWith('"""')) {
        tripleKey = kv.key;
        tripleBuffer = kv.value;
        continue;
      }

      _setCourseField(course, kv.key, kv.value);
    }

    course.modules = modules;
  }

  static void _fillModule(ParsedModule module, String body) {
    final lines = body.split('\n');
    String? tripleBuffer;
    String? tripleKey;

    for (var raw in lines) {
      var line = raw.trimRight();
      if (line.trim().startsWith('//')) continue;

      if (tripleBuffer != null) {
        if (line.trim() == '"""') {
          _setModuleField(module, tripleKey!, tripleBuffer.trim());
          tripleBuffer = null;
          tripleKey = null;
        } else {
          tripleBuffer += '\n$line';
        }
        continue;
      }

      final kv = _parseKeyValue(line.trim());
      if (kv == null) continue;

      if (line.trim().substring(kv.key.length + 1).trim().startsWith('"""')) {
        tripleKey = kv.key;
        tripleBuffer = kv.value;
        continue;
      }

      _setModuleField(module, kv.key, kv.value);
    }
  }

  static void _setCourseField(ParsedCourse course, String key, String value) {
    switch (key) {
      case 'title':
        course.title = value;
      case 'description':
        course.description = value;
      case 'category':
        course.category = value;
      case 'level':
        course.level = value;
      case 'duration':
        course.duration = value;
    }
  }

  static void _setModuleField(ParsedModule module, String key, String value) {
    switch (key) {
      case 'title':
        module.title = value;
      case 'duration':
        module.duration = value;
      case 'content':
        module.content = value;
    }
  }

  static List<String> _parseList(String raw) {
    if (raw.isEmpty || raw == '[]') return [];
    final re = RegExp(r'"((?:[^"\\]|\\.)*)"');
    return re.allMatches(raw).map((m) => m.group(1)!).toList();
  }
}

class _KeyValue {
  final String key;
  final String value;
  _KeyValue(this.key, this.value);
}
