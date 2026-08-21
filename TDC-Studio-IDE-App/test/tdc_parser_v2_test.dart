// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/tdc_parser_v2.dart';

void main() {
  group('TdcParserV2', () {
    const courseInput = '''
// TUTODECODE Course — format .tdc v2
tdc-version: 2
type: course

course "intro-linux" {
  title: "Linux & Administration Système"
  description: "Maîtrisez les commandes..."
  category: linux
  level: beginner
  duration: 2h
  icon: Terminal

  module "diag-prod" {
    title: "Chapitre 1 : Diagnostic système"
    duration: 15min

    content """
    # Incident de Production
    Vous êtes connecté en SSH.
    """

    codeblock "bash" {
      title: "Audit mémoire"
      code """
      uptime
      free -h
      """
    }

    quiz {
      question "Quelle commande affiche la mémoire ?" {
        + "free -h"
        - "whoami"
        explanation: "free -h affiche la RAM et SWAP."
      }
    }
  }
}
''';

    const cheatSheetInput = '''
tdc-version: 2
type: cheat_sheet

cheat_sheet "hydra-bruteforce" {
  title: "Brute-force d'authentification"
  category: red_team
  danger_level: 3

  entry "hydra-ssh" {
    command: "hydra -l [user] -P [wordlist] [target] ssh"
    description: "Brute-force SSH avec dictionnaire"
    explanation: """
    Teste des combinaisons identifiant/mot de passe.
    """
    options: [
      "-l : login fixe"
    ]
    examples: [
      "hydra -l admin -P rockyou.txt 10.0.0.1 ssh"
    ]
    warnings: [
      "Usage légal uniquement"
    ]
  }
}
''';

    const localeInput = '''
tdc-version: 2
type: locale

locale "en" {
  menu.home: "Home"
  menu.tools: "Tools"
  course.empty: "No course loaded"
}
''';

    const templateInput = '''
tdc-version: 2
type: template

template "linux-admin" {
  title: "Administration Linux"
  category: linux
  level: beginner
  duration: 2h

  structure {
    module_count: 3
    quiz_per_module: 2
    total_xp: 150
  }

  modules {
    module "intro" {
      title: "Introduction"
      content_template: """
      # Introduction
      {{description}}
      """
    }

    module "commands" {
      title: "Commandes"
      codeblock "bash" {
        code: "ls -la\npwd"
      }
    }
  }
}
''';

    const assetPackInput = '''
tdc-version: 2
type: asset_pack

asset_pack "linux-icons" {
  title: "Pack d'icônes Linux"
  version: "1.0"

  assets {
    icon "terminal" {
      source: "assets/icons/terminal.svg"
      category: system
    }
    image "linux-arch" {
      source: "assets/images/linux-arch.png"
      alt: "Architecture Linux"
    }
  }
}
''';

    test('parses a valid course', () {
      final resource = TdcParserV2.parse(courseInput);
      expect(resource.type, 'course');
      expect(resource.id, 'intro-linux');
      expect(resource.title, 'Linux & Administration Système');
      final course = resource.asCourse;
      expect(course.modules.length, 1);
      expect(course.modules.first.title, 'Chapitre 1 : Diagnostic système');
      expect(course.modules.first.content, contains('Incident de Production'));
      expect(course.modules.first.codeBlocks.length, 1);
      expect(course.modules.first.questions.length, 1);
      expect(course.modules.first.questions.first.choices.where((c) => c.correct).length, 1);
    });

    test('parses a valid cheat_sheet', () {
      final resource = TdcParserV2.parse(cheatSheetInput);
      expect(resource.type, 'cheat_sheet');
      expect(resource.id, 'hydra-bruteforce');
      final sheet = resource.asCheatSheet;
      expect(sheet.entries.length, 1);
      expect(sheet.entries.first.command, 'hydra -l [user] -P [wordlist] [target] ssh');
      expect(sheet.entries.first.warnings.length, 1);
    });

    test('parses a valid locale', () {
      final resource = TdcParserV2.parse(localeInput);
      expect(resource.type, 'locale');
      expect(resource.id, 'en');
      final locale = resource.asLocale;
      expect(locale.values['menu.home'], 'Home');
    });

    test('parses a valid template', () {
      final resource = TdcParserV2.parse(templateInput);
      expect(resource.type, 'template');
      expect(resource.id, 'linux-admin');
      final template = resource.asTemplate;
      expect(template.modules.length, 2);
      expect(template.moduleCount, 3);
      expect(template.quizPerModule, 2);
      expect(template.totalXp, 150);
    });

    test('parses a valid asset_pack', () {
      final resource = TdcParserV2.parse(assetPackInput);
      expect(resource.type, 'asset_pack');
      expect(resource.id, 'linux-icons');
      final pack = resource.asAssetPack;
      expect(pack.assets.length, 2);
      expect(pack.assets.first.type, 'icon');
    });

    test('round-trips all five types logically', () {
      final inputs = [courseInput, cheatSheetInput, localeInput, templateInput, assetPackInput];
      for (final source in inputs) {
        final resource = TdcParserV2.parse(source);
        final serialized = TdcSerializerV2.serialize(resource);
        final reparsed = TdcParserV2.parse(serialized);
        expect(reparsed.type, resource.type);
        expect(reparsed.id, resource.id);
        expect(reparsed.title, resource.title);
      }
    });

    test('throws on missing tdc-version', () {
      expect(() => TdcParserV2.parse('type: course\n\ncourse "x" {}'), throwsA(isA<TdcParseException>()));
    });

    test('throws on malformed block', () {
      expect(() => TdcParserV2.parse('tdc-version: 2\ntype: course\n\ncourse "x" { title }'), throwsA(isA<TdcParseException>()));
    });
  });
}
