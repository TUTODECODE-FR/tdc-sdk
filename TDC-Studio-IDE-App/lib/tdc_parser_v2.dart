// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

/// Unified parser and serializer for TUTODECODE Script (.tdc) v2.
///
/// Supports the five resource types defined by DSL v2:
/// course, cheat_sheet, locale, template, asset_pack.
library;

// ============================================================================
// Exceptions and validation
// ============================================================================

/// Exception thrown when a .tdc source cannot be parsed.
class TdcParseException implements Exception {
  final int line;
  final int column;
  final String message;

  TdcParseException({
    required this.line,
    required this.column,
    required this.message,
  });

  @override
  String toString() => 'TdcParseException at $line:$column: $message';
}

/// A single validation error found by [TdcResource.validate].
class TdcValidationError {
  final String path;
  final String message;

  TdcValidationError({required this.path, required this.message});

  @override
  String toString() => 'TdcValidationError at $path: $message';
}

// ============================================================================
// Data models
// ============================================================================

/// A parsed .tdc resource. The concrete payload is stored in [concrete].
class TdcResource {
  String tdcVersion;
  String type;
  String id;
  Object concrete;

  TdcResource({
    required this.tdcVersion,
    required this.type,
    required this.id,
    required this.concrete,
  });

  String get resourceType => type;
  String get slug => id;

  String get title {
    return switch (concrete) {
      TdcCourse c => c.title,
      TdcCheatSheet c => c.title,
      TdcLocale l => l.id,
      TdcTemplate t => t.title,
      TdcAssetPack a => a.title,
      _ => '',
    };
  }

  TdcCourse get asCourse => concrete as TdcCourse;
  TdcCheatSheet get asCheatSheet => concrete as TdcCheatSheet;
  TdcLocale get asLocale => concrete as TdcLocale;
  TdcTemplate get asTemplate => concrete as TdcTemplate;
  TdcAssetPack get asAssetPack => concrete as TdcAssetPack;

  TdcResource copyWith({
    String? tdcVersion,
    String? type,
    String? id,
    Object? concrete,
  }) {
    return TdcResource(
      tdcVersion: tdcVersion ?? this.tdcVersion,
      type: type ?? this.type,
      id: id ?? this.id,
      concrete: concrete ?? this.concrete,
    );
  }

  List<TdcValidationError> validate() {
    final errors = <TdcValidationError>[];
    if (tdcVersion != '2') {
      errors.add(
        TdcValidationError(
          path: 'tdc-version',
          message: 'Expected tdc-version 2, got "$tdcVersion".',
        ),
      );
    }
    if (!const {
      'course',
      'cheat_sheet',
      'locale',
      'template',
      'asset_pack',
    }.contains(type)) {
      errors.add(
        TdcValidationError(
          path: 'type',
          message: 'Unknown resource type "$type".',
        ),
      );
    }
    if (id.isEmpty) {
      errors.add(
        TdcValidationError(path: 'id', message: 'Resource id is required.'),
      );
    }

    switch (concrete) {
      case TdcCourse c:
        errors.addAll(c.validate(id));
        break;
      case TdcCheatSheet c:
        errors.addAll(c.validate(id));
        break;
      case TdcLocale l:
        errors.addAll(l.validate(id));
        break;
      case TdcTemplate t:
        errors.addAll(t.validate(id));
        break;
      case TdcAssetPack a:
        errors.addAll(a.validate(id));
        break;
    }
    return errors;
  }
}

class TdcCourse {
  String id;
  String title;
  String description;
  String category;
  String level;
  String duration;
  String icon;
  List<TdcModule> modules;

  TdcCourse({
    required this.id,
    this.title = '',
    this.description = '',
    this.category = '',
    this.level = '',
    this.duration = '',
    this.icon = '',
    this.modules = const [],
  });

  TdcCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? level,
    String? duration,
    String? icon,
    List<TdcModule>? modules,
  }) {
    return TdcCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      icon: icon ?? this.icon,
      modules: modules ?? this.modules,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Title is required.'));
    }
    if (category.isEmpty) {
      errors.add(TdcValidationError(path: '$path.category', message: 'Category is required.'));
    }
    if (modules.isEmpty) {
      errors.add(TdcValidationError(path: '$path.modules', message: 'At least one module is required.'));
    }
    for (var i = 0; i < modules.length; i++) {
      errors.addAll(modules[i].validate('$path.modules[$i]'));
    }
    return errors;
  }
}

class TdcModule {
  String id;
  String title;
  String duration;
  String content;
  List<TdcCodeBlock> codeBlocks;
  List<TdcQuestion> questions;

  TdcModule({
    required this.id,
    this.title = '',
    this.duration = '',
    this.content = '',
    this.codeBlocks = const [],
    this.questions = const [],
  });

  TdcModule copyWith({
    String? id,
    String? title,
    String? duration,
    String? content,
    List<TdcCodeBlock>? codeBlocks,
    List<TdcQuestion>? questions,
  }) {
    return TdcModule(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      content: content ?? this.content,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      questions: questions ?? this.questions,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (id.isEmpty) {
      errors.add(TdcValidationError(path: '$path.id', message: 'Module id is required.'));
    }
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Module title is required.'));
    }
    for (var i = 0; i < questions.length; i++) {
      errors.addAll(questions[i].validate('$path.questions[$i]'));
    }
    return errors;
  }
}

class TdcCodeBlock {
  String language;
  String title;
  String code;

  TdcCodeBlock({
    this.language = '',
    this.title = '',
    this.code = '',
  });

  TdcCodeBlock copyWith({
    String? language,
    String? title,
    String? code,
  }) {
    return TdcCodeBlock(
      language: language ?? this.language,
      title: title ?? this.title,
      code: code ?? this.code,
    );
  }
}

class TdcQuestion {
  String text;
  List<TdcChoice> choices;
  String? explanation;

  TdcQuestion({
    this.text = '',
    this.choices = const [],
    this.explanation,
  });

  TdcQuestion copyWith({
    String? text,
    List<TdcChoice>? choices,
    String? explanation,
  }) {
    return TdcQuestion(
      text: text ?? this.text,
      choices: choices ?? this.choices,
      explanation: explanation ?? this.explanation,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (text.isEmpty) {
      errors.add(TdcValidationError(path: '$path.text', message: 'Question text is required.'));
    }
    if (choices.isEmpty) {
      errors.add(TdcValidationError(path: '$path.choices', message: 'At least one choice is required.'));
    }
    if (!choices.any((c) => c.correct)) {
      errors.add(TdcValidationError(path: '$path.choices', message: 'At least one correct choice is required.'));
    }
    if (!choices.any((c) => !c.correct)) {
      errors.add(TdcValidationError(path: '$path.choices', message: 'At least one incorrect choice is required.'));
    }
    return errors;
  }
}

class TdcChoice {
  String text;
  bool correct;

  TdcChoice({required this.text, required this.correct});

  TdcChoice copyWith({String? text, bool? correct}) {
    return TdcChoice(text: text ?? this.text, correct: correct ?? this.correct);
  }
}

class TdcCheatSheet {
  String id;
  String title;
  String category;
  int dangerLevel;
  List<TdcCheatEntry> entries;

  TdcCheatSheet({
    required this.id,
    this.title = '',
    this.category = '',
    this.dangerLevel = 0,
    this.entries = const [],
  });

  TdcCheatSheet copyWith({
    String? id,
    String? title,
    String? category,
    int? dangerLevel,
    List<TdcCheatEntry>? entries,
  }) {
    return TdcCheatSheet(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      entries: entries ?? this.entries,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Title is required.'));
    }
    if (category.isEmpty) {
      errors.add(TdcValidationError(path: '$path.category', message: 'Category is required.'));
    }
    if (entries.isEmpty) {
      errors.add(TdcValidationError(path: '$path.entries', message: 'At least one entry is required.'));
    }
    for (var i = 0; i < entries.length; i++) {
      errors.addAll(entries[i].validate('$path.entries[$i]'));
    }
    return errors;
  }
}

class TdcCheatEntry {
  String id;
  String command;
  String description;
  String explanation;
  List<String> options;
  List<String> examples;
  List<String> warnings;

  TdcCheatEntry({
    required this.id,
    this.command = '',
    this.description = '',
    this.explanation = '',
    this.options = const [],
    this.examples = const [],
    this.warnings = const [],
  });

  TdcCheatEntry copyWith({
    String? id,
    String? command,
    String? description,
    String? explanation,
    List<String>? options,
    List<String>? examples,
    List<String>? warnings,
  }) {
    return TdcCheatEntry(
      id: id ?? this.id,
      command: command ?? this.command,
      description: description ?? this.description,
      explanation: explanation ?? this.explanation,
      options: options ?? this.options,
      examples: examples ?? this.examples,
      warnings: warnings ?? this.warnings,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (id.isEmpty) {
      errors.add(TdcValidationError(path: '$path.id', message: 'Entry id is required.'));
    }
    if (command.isEmpty) {
      errors.add(TdcValidationError(path: '$path.command', message: 'Command is required.'));
    }
    if (description.isEmpty) {
      errors.add(TdcValidationError(path: '$path.description', message: 'Description is required.'));
    }
    return errors;
  }
}

class TdcLocale {
  String id;
  Map<String, String> values;

  TdcLocale({required this.id, this.values = const {}});

  TdcLocale copyWith({String? id, Map<String, String>? values}) {
    return TdcLocale(id: id ?? this.id, values: values ?? this.values);
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (id.isEmpty) {
      errors.add(TdcValidationError(path: '$path.id', message: 'Locale code is required.'));
    }
    if (values.isEmpty) {
      errors.add(TdcValidationError(path: '$path.values', message: 'Locale must contain at least one key.'));
    }
    for (final entry in values.entries) {
      if (entry.value.isEmpty) {
        errors.add(
          TdcValidationError(
            path: '$path.values["${entry.key}"]',
            message: 'Value for key "${entry.key}" must not be empty.',
          ),
        );
      }
    }
    return errors;
  }
}

class TdcTemplate {
  String id;
  String title;
  String category;
  String level;
  String duration;
  int? moduleCount;
  int? quizPerModule;
  int? totalXp;
  List<TdcTemplateModule> modules;

  TdcTemplate({
    required this.id,
    this.title = '',
    this.category = '',
    this.level = '',
    this.duration = '',
    this.moduleCount,
    this.quizPerModule,
    this.totalXp,
    this.modules = const [],
  });

  TdcTemplate copyWith({
    String? id,
    String? title,
    String? category,
    String? level,
    String? duration,
    int? moduleCount,
    int? quizPerModule,
    int? totalXp,
    List<TdcTemplateModule>? modules,
  }) {
    return TdcTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      moduleCount: moduleCount ?? this.moduleCount,
      quizPerModule: quizPerModule ?? this.quizPerModule,
      totalXp: totalXp ?? this.totalXp,
      modules: modules ?? this.modules,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Title is required.'));
    }
    if (category.isEmpty) {
      errors.add(TdcValidationError(path: '$path.category', message: 'Category is required.'));
    }
    if (modules.isEmpty) {
      errors.add(TdcValidationError(path: '$path.modules', message: 'At least one module is required.'));
    }
    for (var i = 0; i < modules.length; i++) {
      errors.addAll(modules[i].validate('$path.modules[$i]'));
    }
    return errors;
  }
}

class TdcTemplateModule {
  String id;
  String title;
  String contentTemplate;
  TdcCodeBlock? codeBlock;

  TdcTemplateModule({
    required this.id,
    this.title = '',
    this.contentTemplate = '',
    this.codeBlock,
  });

  TdcTemplateModule copyWith({
    String? id,
    String? title,
    String? contentTemplate,
    TdcCodeBlock? codeBlock,
  }) {
    return TdcTemplateModule(
      id: id ?? this.id,
      title: title ?? this.title,
      contentTemplate: contentTemplate ?? this.contentTemplate,
      codeBlock: codeBlock ?? this.codeBlock,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (id.isEmpty) {
      errors.add(TdcValidationError(path: '$path.id', message: 'Module id is required.'));
    }
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Module title is required.'));
    }
    return errors;
  }
}

class TdcAssetPack {
  String id;
  String title;
  String version;
  List<TdcAsset> assets;

  TdcAssetPack({
    required this.id,
    this.title = '',
    this.version = '',
    this.assets = const [],
  });

  TdcAssetPack copyWith({
    String? id,
    String? title,
    String? version,
    List<TdcAsset>? assets,
  }) {
    return TdcAssetPack(
      id: id ?? this.id,
      title: title ?? this.title,
      version: version ?? this.version,
      assets: assets ?? this.assets,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (title.isEmpty) {
      errors.add(TdcValidationError(path: '$path.title', message: 'Title is required.'));
    }
    if (version.isEmpty) {
      errors.add(TdcValidationError(path: '$path.version', message: 'Version is required.'));
    }
    if (assets.isEmpty) {
      errors.add(TdcValidationError(path: '$path.assets', message: 'At least one asset is required.'));
    }
    for (var i = 0; i < assets.length; i++) {
      errors.addAll(assets[i].validate('$path.assets[$i]'));
    }
    return errors;
  }
}

class TdcAsset {
  String type;
  String id;
  String source;
  String category;
  String? alt;

  TdcAsset({
    required this.type,
    required this.id,
    required this.source,
    this.category = '',
    this.alt,
  });

  TdcAsset copyWith({
    String? type,
    String? id,
    String? source,
    String? category,
    String? alt,
  }) {
    return TdcAsset(
      type: type ?? this.type,
      id: id ?? this.id,
      source: source ?? this.source,
      category: category ?? this.category,
      alt: alt ?? this.alt,
    );
  }

  List<TdcValidationError> validate(String path) {
    final errors = <TdcValidationError>[];
    if (type.isEmpty) {
      errors.add(TdcValidationError(path: '$path.type', message: 'Asset type is required.'));
    }
    if (id.isEmpty) {
      errors.add(TdcValidationError(path: '$path.id', message: 'Asset id is required.'));
    }
    if (source.isEmpty) {
      errors.add(TdcValidationError(path: '$path.source', message: 'Asset source is required.'));
    }
    return errors;
  }
}

// ============================================================================
// Tokenizer
// ============================================================================

enum TdcTokenType {
  identifier,
  string,
  number,
  lBrace,
  rBrace,
  lBracket,
  rBracket,
  colon,
  comma,
  plus,
  minus,
  newline,
  eof,
}

class TdcToken {
  final TdcTokenType type;
  final String value;
  final int line;
  final int column;

  TdcToken({required this.type, required this.value, required this.line, required this.column});

  @override
  String toString() => 'TdcToken($type, "$value", $line:$column)';
}

class _TdcTokenizer {
  final String _source;
  final List<TdcToken> _tokens = [];
  int _pos = 0;
  int _line = 1;
  int _column = 1;

  _TdcTokenizer(this._source);

  List<TdcToken> tokenize() {
    while (!_isAtEnd) {
      _scanToken();
    }
    _tokens.add(
      TdcToken(type: TdcTokenType.eof, value: '', line: _line, column: _column),
    );
    return _tokens;
  }

  void _scanToken() {
    final char = _advance();
    final startLine = _line;
    final startColumn = _column - 1;

    switch (char) {
      case ' ':
      case '\t':
      case '\r':
      case '\f':
        // Ignore whitespace other than newlines.
        break;
      case '\n':
        _addToken(TdcTokenType.newline, char, line: startLine, column: startColumn);
        break;
      case '{':
        _addToken(TdcTokenType.lBrace, char, line: startLine, column: startColumn);
        break;
      case '}':
        _addToken(TdcTokenType.rBrace, char, line: startLine, column: startColumn);
        break;
      case '[':
        _addToken(TdcTokenType.lBracket, char, line: startLine, column: startColumn);
        break;
      case ']':
        _addToken(TdcTokenType.rBracket, char, line: startLine, column: startColumn);
        break;
      case ':':
        _addToken(TdcTokenType.colon, char, line: startLine, column: startColumn);
        break;
      case ',':
        _addToken(TdcTokenType.comma, char, line: startLine, column: startColumn);
        break;
      case '+':
        _addToken(TdcTokenType.plus, char, line: startLine, column: startColumn);
        break;
      case '-':
        _addToken(TdcTokenType.minus, char, line: startLine, column: startColumn);
        break;
      case '/':
        if (_match('/')) {
          while (!_isAtEnd && _peek() != '\n') {
            _advance();
          }
        } else {
          _error('Unexpected character: $char', line: startLine, column: startColumn);
        }
        break;
      case '"':
        _string(startLine, startColumn);
        break;
      default:
        if (_isDigit(char)) {
          _number(startLine, startColumn, char);
        } else if (_isIdentifierStart(char)) {
          _identifier(startLine, startColumn, char);
        } else {
          _error('Unexpected character: $char', line: startLine, column: startColumn);
        }
    }
  }

  void _string(int startLine, int startColumn) {
    // The opening quote has already been consumed by _scanToken.
    // _pos now points to the character following that opening quote.
    final isTriple = _pos + 1 < _source.length &&
        _source[_pos] == '"' &&
        _source[_pos + 1] == '"';

    if (isTriple) {
      // Consume the remaining two opening quotes.
      _advance();
      _advance();

      final buffer = StringBuffer();
      while (true) {
        if (_isAtEnd) {
          _error('Unterminated triple-quoted string', line: startLine, column: startColumn);
        }
        if (_source[_pos] == '"' &&
            _pos + 1 < _source.length &&
            _source[_pos + 1] == '"' &&
            _pos + 2 < _source.length &&
            _source[_pos + 2] == '"') {
          _advance();
          _advance();
          _advance();
          break;
        }
        buffer.write(_advance());
      }
      final value = _normalizeTripleQuoted(buffer.toString());
      _addToken(TdcTokenType.string, value, line: startLine, column: startColumn);
      return;
    }

    // Single-line string.
    final buffer = StringBuffer();
    while (!_isAtEnd && _peek() != '"') {
      if (_peek() == '\\') {
        _advance();
        final escaped = _advance();
        switch (escaped) {
          case 'n':
            buffer.write('\n');
            break;
          case 't':
            buffer.write('\t');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case '"':
            buffer.write('"');
            break;
          case '\\':
            buffer.write('\\');
            break;
          default:
            buffer.write('\\');
            buffer.write(escaped);
            break;
        }
      } else {
        buffer.write(_advance());
      }
    }
    if (_isAtEnd) {
      _error('Unterminated string', line: startLine, column: startColumn);
    }
    _advance(); // Closing quote.
    _addToken(TdcTokenType.string, buffer.toString(), line: startLine, column: startColumn);
  }

  String _normalizeTripleQuoted(String value) {
    if (value.startsWith('\n')) {
      value = value.substring(1);
    }
    if (value.endsWith('\n')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  void _number(int startLine, int startColumn, String firstChar) {
    final buffer = StringBuffer(firstChar);
    while (!_isAtEnd && _isDigit(_peek())) {
      buffer.write(_advance());
    }
    _addToken(TdcTokenType.number, buffer.toString(), line: startLine, column: startColumn);
  }

  void _identifier(int startLine, int startColumn, String firstChar) {
    final buffer = StringBuffer(firstChar);
    while (!_isAtEnd && _isIdentifierPart(_peek())) {
      buffer.write(_advance());
    }
    _addToken(TdcTokenType.identifier, buffer.toString(), line: startLine, column: startColumn);
  }

  String _advance() {
    final char = _source[_pos];
    _pos++;
    if (char == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    return char;
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (_source[_pos] != expected) return false;
    _advance();
    return true;
  }

  String _peek() => _isAtEnd ? '\x00' : _source[_pos];

  bool get _isAtEnd => _pos >= _source.length;

  static bool _isDigit(String char) => char.compareTo('0') >= 0 && char.compareTo('9') <= 0;

  static bool _isIdentifierStart(String char) =>
      (char.compareTo('a') >= 0 && char.compareTo('z') <= 0) ||
      (char.compareTo('A') >= 0 && char.compareTo('Z') <= 0) ||
      char == '_';

  static bool _isIdentifierPart(String char) =>
      _isIdentifierStart(char) || _isDigit(char) || char == '.' || char == '-';

  void _addToken(TdcTokenType type, String value, {required int line, required int column}) {
    _tokens.add(TdcToken(type: type, value: value, line: line, column: column));
  }

  Never _error(String message, {required int line, required int column}) {
    throw TdcParseException(line: line, column: column, message: message);
  }
}

// ============================================================================
// AST used during parsing
// ============================================================================

class _TdcAstBlock {
  final String type;
  final String? id;
  final List<_TdcAstField> fields;
  final List<_TdcAstBlock> blocks;

  _TdcAstBlock({required this.type, this.id, required this.fields, required this.blocks});
}

class _TdcAstField {
  final String key;
  final _TdcAstValue value;

  _TdcAstField({required this.key, required this.value});
}

sealed class _TdcAstValue {
  String get asString;
  int get asInt;
  List<String> get asStringList;
}

class _StringValue implements _TdcAstValue {
  final String value;
  _StringValue(this.value);

  @override
  String get asString => value;

  @override
  int get asInt => int.tryParse(value) ?? 0;

  @override
  List<String> get asStringList => [value];
}

class _ListValue implements _TdcAstValue {
  final List<String> value;
  _ListValue(this.value);

  @override
  String get asString => value.isEmpty ? '' : value.first;

  @override
  int get asInt => value.isEmpty ? 0 : int.tryParse(value.first) ?? 0;

  @override
  List<String> get asStringList => value;
}

// ============================================================================
// Parser
// ============================================================================

class _TdcParser {
  final List<TdcToken> _tokens;
  int _pos = 0;

  _TdcParser(this._tokens);

  List<TdcResource> parseAll() {
    final resources = <TdcResource>[];
    while (!_isAtEnd()) {
      _skipNewlines();
      if (_check(TdcTokenType.eof)) break;
      final before = _pos;
      final resource = _parseResource();
      if (resource != null) {
        resources.add(resource);
      } else if (_pos == before) {
        // No progress: skip the current token to avoid an infinite loop.
        _advance();
      }
      _skipNewlines();
    }
    return resources;
  }

  TdcResource? _parseResource() {
    _skipNewlines();
    if (!_check(TdcTokenType.identifier) || _peek.value != 'tdc-version') {
      return null;
    }

    _advance(); // tdc-version
    _consume(TdcTokenType.colon, 'Expected ":" after tdc-version');
    final versionToken = _consume(TdcTokenType.number, 'Expected version number after tdc-version:');
    final tdcVersion = versionToken.value;

    _skipNewlines();

    _consume(TdcTokenType.identifier, 'Expected "type" identifier');
    if (_previous.value != 'type') {
      _error(_previous, 'Expected "type" keyword');
    }
    _consume(TdcTokenType.colon, 'Expected ":" after type');
    final typeToken = _consume(TdcTokenType.identifier, 'Expected resource type after type:');
    final type = typeToken.value;

    _skipNewlines();

    final block = _parseBlock();
    if (block.type != type) {
      _error(_peek, 'Expected top-level block of type "$type", found "${block.type}"');
    }

    return _buildResource(tdcVersion, type, block);
  }

  _TdcAstBlock _parseBlock() {
    final typeToken = _consume(TdcTokenType.identifier, 'Expected block type');
    final type = typeToken.value;

    String? id;
    if (_check(TdcTokenType.string) || _check(TdcTokenType.identifier)) {
      id = _advance().value;
    }

    _consume(TdcTokenType.lBrace, 'Expected "{" after block type "$type"');

    final fields = <_TdcAstField>[];
    final blocks = <_TdcAstBlock>[];

    while (!_check(TdcTokenType.rBrace) && !_check(TdcTokenType.eof)) {
      _skipNewlines();
      if (_check(TdcTokenType.rBrace)) break;

      if (_check(TdcTokenType.identifier)) {
        if (_isAt(1, TdcTokenType.colon)) {
          fields.add(_parseField());
        } else if (_isAt(1, TdcTokenType.string) && _isAt(2, TdcTokenType.lBrace)) {
          blocks.add(_parseBlock());
        } else if (_isAt(1, TdcTokenType.lBrace)) {
          blocks.add(_parseBlock());
        } else if (_isAt(1, TdcTokenType.string)) {
          // Field with implicit colon: key "value" or key """...""" (e.g. content).
          final key = _advance().value;
          final value = _StringValue(_advance().value);
          fields.add(_TdcAstField(key: key, value: value));
        } else {
          _error(_peek, 'Expected ":", block id, or "{" after identifier "${_peek.value}"');
        }
      } else if (_check(TdcTokenType.plus) || _check(TdcTokenType.minus)) {
        final sign = _advance().value;
        final text = _consume(TdcTokenType.string, 'Expected answer text after "$sign"');
        fields.add(
          _TdcAstField(
            key: sign == '+' ? '_correct' : '_incorrect',
            value: _StringValue(text.value),
          ),
        );
      } else {
        _error(_peek, 'Unexpected token in block "$type"');
      }
    }

    _consume(TdcTokenType.rBrace, 'Expected "}" to close block "$type"');

    return _TdcAstBlock(type: type, id: id, fields: fields, blocks: blocks);
  }

  _TdcAstField _parseField() {
    final keyToken = _consume(TdcTokenType.identifier, 'Expected field key');
    final key = keyToken.value;
    _consume(TdcTokenType.colon, 'Expected ":" after field key "$key"');
    final value = _parseValue();
    return _TdcAstField(key: key, value: value);
  }

  _TdcAstValue _parseValue() {
    if (_check(TdcTokenType.string)) {
      return _StringValue(_advance().value);
    }
    if (_check(TdcTokenType.lBracket)) {
      return _parseList();
    }
    if (_check(TdcTokenType.number) || _check(TdcTokenType.identifier)) {
      // Unquoted single-word value (e.g. linux, beginner, 2h, 15min).
      final buffer = StringBuffer();
      while (_check(TdcTokenType.number) || _check(TdcTokenType.identifier)) {
        buffer.write(_advance().value);
      }
      return _StringValue(buffer.toString());
    }
    _error(_peek, 'Expected value after ":"');
  }

  _ListValue _parseList() {
    _advance(); // [
    final values = <String>[];
    _skipNewlines();
    if (_check(TdcTokenType.rBracket)) {
      _advance();
      return _ListValue(values);
    }
    while (true) {
      final token = _consume(TdcTokenType.string, 'Expected string in list');
      values.add(token.value);
      _skipNewlines();
      if (_check(TdcTokenType.rBracket)) {
        _advance();
        break;
      }
      _consume(TdcTokenType.comma, 'Expected "," or "]" after list item');
      _skipNewlines();
    }
    return _ListValue(values);
  }

  TdcToken _consume(TdcTokenType type, String message) {
    if (_check(type)) return _advance();
    _error(_peek, message);
  }

  bool _check(TdcTokenType type) => _peek.type == type;

  TdcToken get _peek => _tokens[_pos];

  TdcToken get _previous => _tokens[_pos - 1];

  TdcToken _advance() {
    if (!_isAtEnd()) _pos++;
    return _previous;
  }

  bool _isAtEnd() => _peek.type == TdcTokenType.eof;

  bool _isAt(int offset, TdcTokenType type) {
    final index = _pos + offset;
    if (index >= _tokens.length) return false;
    return _tokens[index].type == type;
  }

  void _skipNewlines() {
    while (_check(TdcTokenType.newline)) {
      _advance();
    }
  }

  Never _error(TdcToken token, String message) {
    throw TdcParseException(
      line: token.line,
      column: token.column,
      message: message,
    );
  }
}

// ============================================================================
// AST to model conversion
// ============================================================================

Map<String, List<_TdcAstValue>> _fieldMap(List<_TdcAstField> fields) {
  final map = <String, List<_TdcAstValue>>{};
  for (final field in fields) {
    map.putIfAbsent(field.key, () => []).add(field.value);
  }
  return map;
}

String _stringField(Map<String, List<_TdcAstValue>> fields, String key) {
  final values = fields[key];
  if (values == null || values.isEmpty) return '';
  return values.first.asString;
}

int _intField(Map<String, List<_TdcAstValue>> fields, String key) {
  final values = fields[key];
  if (values == null || values.isEmpty) return 0;
  return values.first.asInt;
}

int? _intFieldOrNull(Map<String, List<_TdcAstValue>> fields, String key) {
  final values = fields[key];
  if (values == null || values.isEmpty) return null;
  return values.first.asInt;
}

List<String> _stringListField(Map<String, List<_TdcAstValue>> fields, String key) {
  final values = fields[key];
  if (values == null || values.isEmpty) return const [];
  return values.first.asStringList;
}

TdcResource _buildResource(String tdcVersion, String type, _TdcAstBlock block) {
  final id = block.id ?? '';
  final Object concrete;
  switch (type) {
    case 'course':
      concrete = _buildCourse(id, block);
      break;
    case 'cheat_sheet':
      concrete = _buildCheatSheet(id, block);
      break;
    case 'locale':
      concrete = _buildLocale(id, block);
      break;
    case 'template':
      concrete = _buildTemplate(id, block);
      break;
    case 'asset_pack':
      concrete = _buildAssetPack(id, block);
      break;
    default:
      throw TdcParseException(
        line: 0,
        column: 0,
        message: 'Unknown resource type "$type".',
      );
  }
  return TdcResource(tdcVersion: tdcVersion, type: type, id: id, concrete: concrete);
}

TdcCourse _buildCourse(String id, _TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  return TdcCourse(
    id: id,
    title: _stringField(fields, 'title'),
    description: _stringField(fields, 'description'),
    category: _stringField(fields, 'category'),
    level: _stringField(fields, 'level'),
    duration: _stringField(fields, 'duration'),
    icon: _stringField(fields, 'icon'),
    modules: block.blocks.where((b) => b.type == 'module').map(_buildModule).toList(),
  );
}

TdcModule _buildModule(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  final codeBlocks = block.blocks.where((b) => b.type == 'codeblock').map(_buildCodeBlock).toList();
  final questions = block.blocks
      .where((b) => b.type == 'quiz')
      .expand((quiz) => quiz.blocks.where((b) => b.type == 'question').map(_buildQuestion))
      .toList();
  return TdcModule(
    id: block.id ?? '',
    title: _stringField(fields, 'title'),
    duration: _stringField(fields, 'duration'),
    content: _stringField(fields, 'content'),
    codeBlocks: codeBlocks,
    questions: questions,
  );
}

TdcCodeBlock _buildCodeBlock(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  return TdcCodeBlock(
    language: block.id ?? '',
    title: _stringField(fields, 'title'),
    code: _stringField(fields, 'code'),
  );
}

TdcQuestion _buildQuestion(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  final choices = <TdcChoice>[];
  for (final field in block.fields) {
    if (field.key == '_correct') {
      choices.add(TdcChoice(text: field.value.asString, correct: true));
    } else if (field.key == '_incorrect') {
      choices.add(TdcChoice(text: field.value.asString, correct: false));
    }
  }
  return TdcQuestion(
    text: block.id ?? '',
    choices: choices,
    explanation: _stringField(fields, 'explanation').nullIfEmpty,
  );
}

TdcCheatSheet _buildCheatSheet(String id, _TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  return TdcCheatSheet(
    id: id,
    title: _stringField(fields, 'title'),
    category: _stringField(fields, 'category'),
    dangerLevel: _intField(fields, 'danger_level'),
    entries: block.blocks.where((b) => b.type == 'entry').map(_buildCheatEntry).toList(),
  );
}

TdcCheatEntry _buildCheatEntry(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  return TdcCheatEntry(
    id: block.id ?? '',
    command: _stringField(fields, 'command'),
    description: _stringField(fields, 'description'),
    explanation: _stringField(fields, 'explanation'),
    options: _stringListField(fields, 'options'),
    examples: _stringListField(fields, 'examples'),
    warnings: _stringListField(fields, 'warnings'),
  );
}

TdcLocale _buildLocale(String id, _TdcAstBlock block) {
  final values = <String, String>{};
  for (final field in block.fields) {
    values[field.key] = field.value.asString;
  }
  return TdcLocale(id: id, values: values);
}

TdcTemplate _buildTemplate(String id, _TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  final structureBlocks = block.blocks.where((b) => b.type == 'structure').toList();
  final modulesBlocks = block.blocks.where((b) => b.type == 'modules').toList();

  final Map<String, List<_TdcAstValue>>? structureFields;
  if (structureBlocks.isNotEmpty) {
    structureFields = _fieldMap(structureBlocks.first.fields);
  } else {
    structureFields = null;
  }

  final modules = modulesBlocks.isNotEmpty
      ? modulesBlocks.first.blocks.where((b) => b.type == 'module').map(_buildTemplateModule).toList()
      : <TdcTemplateModule>[];

  return TdcTemplate(
    id: id,
    title: _stringField(fields, 'title'),
    category: _stringField(fields, 'category'),
    level: _stringField(fields, 'level'),
    duration: _stringField(fields, 'duration'),
    moduleCount: structureFields != null ? _intFieldOrNull(structureFields, 'module_count') : null,
    quizPerModule: structureFields != null ? _intFieldOrNull(structureFields, 'quiz_per_module') : null,
    totalXp: structureFields != null ? _intFieldOrNull(structureFields, 'total_xp') : null,
    modules: modules,
  );
}

TdcTemplateModule _buildTemplateModule(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  final codeBlocks = block.blocks.where((b) => b.type == 'codeblock').map(_buildCodeBlock).toList();
  return TdcTemplateModule(
    id: block.id ?? '',
    title: _stringField(fields, 'title'),
    contentTemplate: _stringField(fields, 'content_template'),
    codeBlock: codeBlocks.isNotEmpty ? codeBlocks.first : null,
  );
}

TdcAssetPack _buildAssetPack(String id, _TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  final assetsBlocks = block.blocks.where((b) => b.type == 'assets').toList();
  final assets = assetsBlocks.isNotEmpty
      ? assetsBlocks.first.blocks.map(_buildAsset).toList()
      : <TdcAsset>[];
  return TdcAssetPack(
    id: id,
    title: _stringField(fields, 'title'),
    version: _stringField(fields, 'version'),
    assets: assets,
  );
}

TdcAsset _buildAsset(_TdcAstBlock block) {
  final fields = _fieldMap(block.fields);
  return TdcAsset(
    type: block.type,
    id: block.id ?? '',
    source: _stringField(fields, 'source'),
    category: _stringField(fields, 'category'),
    alt: _stringField(fields, 'alt').nullIfEmpty,
  );
}

extension _StringNullIfEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

// ============================================================================
// Public parser API
// ============================================================================

/// Parser entry points for TDC v2 resources.
class TdcParserV2 {
  TdcParserV2._();

  static TdcResource parse(String source) {
    final tokens = _TdcTokenizer(source).tokenize();
    final parser = _TdcParser(tokens);
    final resources = parser.parseAll();
    if (resources.isEmpty) {
      throw TdcParseException(
        line: 1,
        column: 1,
        message: 'No TDC resource found. Expected header tdc-version: 2.',
      );
    }
    return resources.first;
  }

  static List<TdcResource> parseAll(String source) {
    final tokens = _TdcTokenizer(source).tokenize();
    return _TdcParser(tokens).parseAll();
  }

  /// Diagnostic helper that returns the token stream without parsing.
  static List<String> debugTokenize(String source) {
    final tokens = _TdcTokenizer(source).tokenize();
    return tokens.map((t) => '${t.type}:${t.value}').toList();
  }
}

// ============================================================================
// Serializer
// ============================================================================

/// Serializer for TDC v2 resources.
class TdcSerializerV2 {
  TdcSerializerV2._();

  static String serialize(TdcResource resource) {
    final buffer = StringBuffer();
    buffer.writeln('tdc-version: ${resource.tdcVersion}');
    buffer.writeln('type: ${resource.type}');
    buffer.writeln();
    _writeResourceBody(buffer, resource, 0);
    return buffer.toString();
  }

  static void _writeResourceBody(StringBuffer buffer, TdcResource resource, int indent) {
    switch (resource.type) {
      case 'course':
        _writeCourse(buffer, resource.asCourse, indent);
      case 'cheat_sheet':
        _writeCheatSheet(buffer, resource.asCheatSheet, indent);
      case 'locale':
        _writeLocale(buffer, resource.asLocale, indent);
      case 'template':
        _writeTemplate(buffer, resource.asTemplate, indent);
      case 'asset_pack':
        _writeAssetPack(buffer, resource.asAssetPack, indent);
    }
  }

  static String _indent(int depth) => '  ' * depth;

  static void _writeBlockHeader(
    StringBuffer buffer,
    String type,
    String? id,
    int indent,
  ) {
    buffer.write(_indent(indent));
    buffer.write(type);
    if (id != null && id.isNotEmpty) {
      buffer.write(' ');
      _writeInlineString(buffer, id);
    }
    buffer.writeln(' {');
  }

  static void _writeBlockClose(StringBuffer buffer, int indent) {
    buffer.writeln('${_indent(indent)}}');
  }

  static void _writeField(
    StringBuffer buffer,
    String key,
    String value,
    int indent,
  ) {
    if (value.isEmpty) return;
    buffer.write(_indent(indent));
    buffer.write('$key: ');
    _writeStringValue(buffer, value, indent);
    buffer.writeln();
  }

  static void _writeStringValue(StringBuffer buffer, String value, int indent) {
    if (value.contains('\n')) {
      buffer.writeln('"""');
      for (final line in value.split('\n')) {
        buffer.write(_indent(indent));
        buffer.writeln(line);
      }
      buffer.write(_indent(indent));
      buffer.write('"""');
    } else {
      _writeInlineString(buffer, value);
    }
  }

  static void _writeInlineString(StringBuffer buffer, String value) {
    buffer.write('"');
    for (final char in value.split('')) {
      switch (char) {
        case '\\':
          buffer.write('\\\\');
          break;
        case '"':
          buffer.write('\\"');
          break;
        case '\n':
          buffer.write('\\n');
          break;
        case '\t':
          buffer.write('\\t');
          break;
        default:
          buffer.write(char);
          break;
      }
    }
    buffer.write('"');
  }

  static void _writeList(
    StringBuffer buffer,
    String key,
    List<String> values,
    int indent,
  ) {
    if (values.isEmpty) return;
    buffer.write(_indent(indent));
    buffer.write('$key: [');
    for (var i = 0; i < values.length; i++) {
      if (i > 0) buffer.write(', ');
      _writeInlineString(buffer, values[i]);
    }
    buffer.writeln(']');
  }

  static void _writeCourse(StringBuffer buffer, TdcCourse course, int indent) {
    _writeBlockHeader(buffer, 'course', course.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', course.title, inner);
    _writeField(buffer, 'description', course.description, inner);
    _writeField(buffer, 'category', course.category, inner);
    _writeField(buffer, 'level', course.level, inner);
    _writeField(buffer, 'duration', course.duration, inner);
    _writeField(buffer, 'icon', course.icon, inner);
    for (final module in course.modules) {
      buffer.writeln();
      _writeModule(buffer, module, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeModule(StringBuffer buffer, TdcModule module, int indent) {
    _writeBlockHeader(buffer, 'module', module.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', module.title, inner);
    _writeField(buffer, 'duration', module.duration, inner);
    _writeField(buffer, 'content', module.content, inner);
    for (final codeBlock in module.codeBlocks) {
      buffer.writeln();
      _writeCodeBlock(buffer, codeBlock, inner);
    }
    if (module.questions.isNotEmpty) {
      buffer.writeln();
      _writeQuiz(buffer, module.questions, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeCodeBlock(StringBuffer buffer, TdcCodeBlock codeBlock, int indent) {
    _writeBlockHeader(buffer, 'codeblock', codeBlock.language, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', codeBlock.title, inner);
    _writeField(buffer, 'code', codeBlock.code, inner);
    _writeBlockClose(buffer, indent);
  }

  static void _writeQuiz(StringBuffer buffer, List<TdcQuestion> questions, int indent) {
    _writeBlockHeader(buffer, 'quiz', null, indent);
    final inner = indent + 1;
    for (var i = 0; i < questions.length; i++) {
      if (i > 0) buffer.writeln();
      _writeQuestion(buffer, questions[i], inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeQuestion(StringBuffer buffer, TdcQuestion question, int indent) {
    _writeBlockHeader(buffer, 'question', question.text, indent);
    final inner = indent + 1;
    for (final choice in question.choices) {
      buffer.write(_indent(inner));
      buffer.write(choice.correct ? '+ ' : '- ');
      _writeInlineString(buffer, choice.text);
      buffer.writeln();
    }
    if (question.explanation != null && question.explanation!.isNotEmpty) {
      _writeField(buffer, 'explanation', question.explanation!, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeCheatSheet(StringBuffer buffer, TdcCheatSheet cheatSheet, int indent) {
    _writeBlockHeader(buffer, 'cheat_sheet', cheatSheet.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', cheatSheet.title, inner);
    _writeField(buffer, 'category', cheatSheet.category, inner);
    if (cheatSheet.dangerLevel > 0) {
      buffer.writeln('${_indent(inner)}danger_level: ${cheatSheet.dangerLevel}');
    }
    for (final entry in cheatSheet.entries) {
      buffer.writeln();
      _writeCheatEntry(buffer, entry, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeCheatEntry(StringBuffer buffer, TdcCheatEntry entry, int indent) {
    _writeBlockHeader(buffer, 'entry', entry.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'command', entry.command, inner);
    _writeField(buffer, 'description', entry.description, inner);
    _writeField(buffer, 'explanation', entry.explanation, inner);
    _writeList(buffer, 'options', entry.options, inner);
    _writeList(buffer, 'examples', entry.examples, inner);
    _writeList(buffer, 'warnings', entry.warnings, inner);
    _writeBlockClose(buffer, indent);
  }

  static void _writeLocale(StringBuffer buffer, TdcLocale locale, int indent) {
    _writeBlockHeader(buffer, 'locale', locale.id, indent);
    final inner = indent + 1;
    for (final entry in locale.values.entries) {
      buffer.write(_indent(inner));
      buffer.write('${entry.key}: ');
      _writeInlineString(buffer, entry.value);
      buffer.writeln();
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeTemplate(StringBuffer buffer, TdcTemplate template, int indent) {
    _writeBlockHeader(buffer, 'template', template.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', template.title, inner);
    _writeField(buffer, 'category', template.category, inner);
    _writeField(buffer, 'level', template.level, inner);
    _writeField(buffer, 'duration', template.duration, inner);

    if (template.moduleCount != null ||
        template.quizPerModule != null ||
        template.totalXp != null) {
      buffer.writeln();
      _writeBlockHeader(buffer, 'structure', null, inner);
      final structureInner = inner + 1;
      if (template.moduleCount != null) {
        buffer.writeln('${_indent(structureInner)}module_count: ${template.moduleCount}');
      }
      if (template.quizPerModule != null) {
        buffer.writeln('${_indent(structureInner)}quiz_per_module: ${template.quizPerModule}');
      }
      if (template.totalXp != null) {
        buffer.writeln('${_indent(structureInner)}total_xp: ${template.totalXp}');
      }
      _writeBlockClose(buffer, inner);
    }

    if (template.modules.isNotEmpty) {
      buffer.writeln();
      _writeBlockHeader(buffer, 'modules', null, inner);
      final modulesInner = inner + 1;
      for (final module in template.modules) {
        _writeTemplateModule(buffer, module, modulesInner);
      }
      _writeBlockClose(buffer, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeTemplateModule(
    StringBuffer buffer,
    TdcTemplateModule module,
    int indent,
  ) {
    _writeBlockHeader(buffer, 'module', module.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', module.title, inner);
    _writeField(buffer, 'content_template', module.contentTemplate, inner);
    if (module.codeBlock != null) {
      _writeCodeBlock(buffer, module.codeBlock!, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeAssetPack(StringBuffer buffer, TdcAssetPack assetPack, int indent) {
    _writeBlockHeader(buffer, 'asset_pack', assetPack.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'title', assetPack.title, inner);
    _writeField(buffer, 'version', assetPack.version, inner);
    if (assetPack.assets.isNotEmpty) {
      buffer.writeln();
      _writeBlockHeader(buffer, 'assets', null, inner);
      final assetsInner = inner + 1;
      for (final asset in assetPack.assets) {
        _writeAsset(buffer, asset, assetsInner);
      }
      _writeBlockClose(buffer, inner);
    }
    _writeBlockClose(buffer, indent);
  }

  static void _writeAsset(StringBuffer buffer, TdcAsset asset, int indent) {
    _writeBlockHeader(buffer, asset.type, asset.id, indent);
    final inner = indent + 1;
    _writeField(buffer, 'source', asset.source, inner);
    _writeField(buffer, 'category', asset.category, inner);
    if (asset.alt != null) {
      _writeField(buffer, 'alt', asset.alt!, inner);
    }
    _writeBlockClose(buffer, indent);
  }
}
