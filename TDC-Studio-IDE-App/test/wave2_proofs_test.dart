// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
/// Proofs for Wave 2 audit: export v2, templates, recent projects, placement.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdc_studio/data/templates/cheat_sheet_templates.dart';
import 'package:tdc_studio/data/templates/course_templates.dart';
import 'package:tdc_studio/services/export_paths.dart';
import 'package:tdc_studio/services/recent_projects_service.dart';
import 'package:tdc_studio/tdc_parser_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Export v2', () {
    test('course serialize starts with tdc-version: 2', () {
      final resource = CourseTemplates.linuxAdmin();
      final out = TdcSerializerV2.serialize(resource);
      expect(out, contains('tdc-version: 2'));
      expect(out, contains('type: course'));
      final versionLine = out
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.startsWith('tdc-version'));
      expect(versionLine, 'tdc-version: 2');
    });

    test('cheat sheet serialize starts with tdc-version: 2', () {
      final out = TdcSerializerV2.serialize(CheatSheetTemplates.sshBasics());
      expect(out, contains('tdc-version: 2'));
      expect(out, contains('type: cheat_sheet'));
    });

    test('locale serialize starts with tdc-version: 2', () {
      final resource = TdcResource(
        tdcVersion: '2',
        type: 'locale',
        id: 'en',
        concrete: TdcLocale(id: 'en', values: {
          'menu.home': 'Home',
          'menu.tools': 'Tools',
        }),
      );
      final out = TdcSerializerV2.serialize(resource);
      expect(out, contains('tdc-version: 2'));
      expect(out, contains('type: locale'));
      expect(out, contains('menu.home: "Home"'));
      expect(out, contains('menu.tools: "Tools"'));
    });
  });

  group('Templates', () {
    test('course templates grid has Linux / Network / Incident', () {
      final titles = CourseTemplates.all.map((t) => t.asCourse.title).toList();
      expect(titles.length, 3);
      expect(titles.any((t) => t.toLowerCase().contains('linux')), isTrue);
      expect(titles.any((t) => t.toLowerCase().contains('réseau') || t.toLowerCase().contains('network')), isTrue);
      expect(titles.any((t) => t.toLowerCase().contains('incident')), isTrue);
    });

    test('cheat sheet templates has SSH / Nmap / Git', () {
      final ids = CheatSheetTemplates.all.map((t) => t.id).toList();
      expect(ids, containsAll(['ssh-basics', 'nmap-scan', 'git-essentials']));
    });

    test('applying course template yields modules + quiz', () {
      final course = CourseTemplates.linuxAdmin().asCourse;
      expect(course.modules, isNotEmpty);
      final questions = course.modules.fold<int>(0, (s, m) => s + m.questions.length);
      expect(questions, greaterThan(0));
    });
  });

  group('Export placement by category', () {
    test('course path uses category folder', () {
      expect(
        ExportPlacement.forCourse(category: 'linux', id: 'intro-linux'),
        'T2DECODE/assets/courses/linux/intro-linux.tdc',
      );
    });

    test('cheat sheet path uses category folder', () {
      expect(
        ExportPlacement.forCheatSheet(category: 'network', id: 'nmap-scan'),
        'T2DECODE/assets/cheat_sheets/network/nmap-scan.tdc',
      );
    });
  });

  group('Recent projects', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('add then load persists across "reopen"', () async {
      await RecentProjectsService.add(RecentProject(
        path: '/tmp/intro-linux.tdc',
        id: 'intro-linux',
        title: 'Linux & Admin',
        type: 'course',
        category: 'linux',
        modifiedAt: DateTime.now(),
      ));
      await RecentProjectsService.add(RecentProject(
        path: '/tmp/nmap-scan.tdc',
        id: 'nmap-scan',
        title: 'Nmap',
        type: 'cheat_sheet',
        category: 'network',
        modifiedAt: DateTime.now(),
      ));

      final loaded = await RecentProjectsService.load();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'nmap-scan'); // most recent first
      expect(loaded.any((p) => p.id == 'intro-linux'), isTrue);
    });

    test('duplicate path moves to front without duplicating', () async {
      await RecentProjectsService.add(RecentProject(
        path: '/tmp/a.tdc',
        id: 'a',
        title: 'A',
        type: 'course',
        modifiedAt: DateTime.now(),
      ));
      await RecentProjectsService.add(RecentProject(
        path: '/tmp/b.tdc',
        id: 'b',
        title: 'B',
        type: 'course',
        modifiedAt: DateTime.now(),
      ));
      await RecentProjectsService.add(RecentProject(
        path: '/tmp/a.tdc',
        id: 'a',
        title: 'A updated',
        type: 'course',
        modifiedAt: DateTime.now(),
      ));

      final loaded = await RecentProjectsService.load();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'a');
      expect(loaded.first.title, 'A updated');
    });
  });

  group('Course export checklist', () {
    test('blocks empty course', () {
      final check = CourseExportCheck.validate(
        id: '',
        title: '',
        description: '',
        moduleCount: 0,
        questionCount: 0,
        syntaxOk: true,
      );
      expect(check.ok, isFalse);
      expect(check.errors.length, greaterThanOrEqualTo(4));
    });

    test('passes filled course', () {
      final check = CourseExportCheck.validate(
        id: 'intro-linux',
        title: 'Linux',
        description: 'Desc',
        moduleCount: 1,
        questionCount: 2,
        syntaxOk: true,
      );
      expect(check.ok, isTrue);
    });
  });
}
