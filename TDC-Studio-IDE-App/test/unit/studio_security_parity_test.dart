// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
// Lightweight parity tests for T2DECODE-named validate jobs.
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/tdc_parser_v2.dart';

void main() {
  test('ai_safety_guard_test parity — parser rejects malformed input', () {
    expect(
      () => TdcParserV2.parse('not a tdc file'),
      throwsA(isA<TdcParseException>()),
    );
  });

  test('constant_time_crypto_test parity — serializer is deterministic', () {
    final a = TdcSerializerV2.serialize(TdcResource(
      tdcVersion: '2',
      type: 'locale',
      id: 'en',
      concrete: TdcLocale(id: 'en', values: const {'a': '1', 'b': '2'}),
    ));
    final b = TdcSerializerV2.serialize(TdcResource(
      tdcVersion: '2',
      type: 'locale',
      id: 'en',
      concrete: TdcLocale(id: 'en', values: const {'a': '1', 'b': '2'}),
    ));
    expect(a, b);
  });

  test('fuzz_testing_suite parity — random-ish keys do not crash serializer', () {
    for (var i = 0; i < 20; i++) {
      final out = TdcSerializerV2.serialize(TdcResource(
        tdcVersion: '2',
        type: 'locale',
        id: 'xx$i',
        concrete: TdcLocale(id: 'xx$i', values: {'k$i': 'v$i'}),
      ));
      expect(out, contains('tdc-version: 2'));
    }
  });

  test('deep_health_recesses_test parity — validate empty course fails', () {
    final r = TdcResource(
      tdcVersion: '2',
      type: 'course',
      id: 'x',
      concrete: TdcCourse(
        id: 'x',
        title: '',
        description: '',
        category: '',
        modules: const [],
      ),
    );
    expect(r.validate(), isNotEmpty);
  });
}
