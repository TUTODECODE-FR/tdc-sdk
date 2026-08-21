// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Suggested T2DECODE asset paths by resource type / category.
library;

/// Where exported .tdc files should land inside the T2DECODE repo.
class ExportPlacement {
  ExportPlacement._();

  static String forCourse({
    required String category,
    required String id,
  }) {
    final cat = category.trim().isEmpty ? 'general' : category.trim();
    final safeId = id.trim().isEmpty ? 'course' : id.trim();
    return 'T2DECODE/assets/courses/$cat/$safeId.tdc';
  }

  static String forCheatSheet({
    required String category,
    required String id,
  }) {
    final cat = category.trim().isEmpty ? 'general' : category.trim();
    final safeId = id.trim().isEmpty ? 'cheat-sheet' : id.trim();
    return 'T2DECODE/assets/cheat_sheets/$cat/$safeId.tdc';
  }

  static String forLocale(String localeCode) {
    final code = localeCode.trim().isEmpty ? 'xx' : localeCode.trim();
    return 'T2DECODE/assets/locale_$code.tdc';
  }

  static String hintForType(String type) {
    switch (type) {
      case 'cheat_sheet':
        return 'Placez le fichier dans assets/cheat_sheets/<catégorie>/ '
            'puis fusionnez ou référencez-le depuis le pack NetKit.';
      case 'locale':
        return 'Placez le fichier à la racine de assets/ '
            '(ex. locale_en.tdc) pour qu\'il soit chargé par T2DECODE.';
      case 'course':
      default:
        return 'Placez le fichier dans assets/courses/<catégorie>/ '
            'ou fusionnez-le dans assets/courses.tdc.';
    }
  }

  static String folderHint(String relativePath) {
    final parts = relativePath.split('/');
    if (parts.length < 2) return relativePath;
    return parts.sublist(0, parts.length - 1).join('/');
  }
}

/// Pre-export checklist for courses.
class CourseExportCheck {
  final bool ok;
  final List<String> errors;
  final List<String> warnings;

  const CourseExportCheck({
    required this.ok,
    this.errors = const [],
    this.warnings = const [],
  });

  static CourseExportCheck validate({
    required String id,
    required String title,
    required String description,
    required int moduleCount,
    required int questionCount,
    required bool syntaxOk,
    List<String> syntaxMessages = const [],
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (id.trim().isEmpty) errors.add('ID du cours manquant');
    if (title.trim().isEmpty) errors.add('Titre du cours manquant');
    if (description.trim().isEmpty) errors.add('Description pédagogique manquante');
    if (moduleCount < 1) errors.add('Au moins 1 chapitre est requis');
    if (questionCount < 1) errors.add('Au moins 1 question de quiz est requise');
    if (!syntaxOk) {
      errors.addAll(
        syntaxMessages.isEmpty
            ? ['Syntaxe .tdc invalide']
            : syntaxMessages.map((m) => 'Syntaxe : $m'),
      );
    }
    if (questionCount > 0 && questionCount < 3) {
      warnings.add('Peu de questions ($questionCount) — visez ≥ 3 pour un bon quiz');
    }

    return CourseExportCheck(
      ok: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}
