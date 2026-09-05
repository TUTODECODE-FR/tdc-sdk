// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/data/volunteer_board_fallback.dart';
import 'package:tdc_studio/services/volunteer_board_parser.dart';

void main() {
  test('parse fallback board yields TDC tasks', () {
    final tasks = VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown);
    expect(tasks.length, greaterThanOrEqualTo(10));
    expect(tasks.first.id, 'TDC-001');
    expect(tasks.first.isLibre, isTrue);
  });

  test('claimInMarkdown updates Pris par and status', () {
    final updated = VolunteerBoardParser.claimInMarkdown(
      markdown: volunteerBoardFallbackMarkdown,
      taskId: 'TDC-001',
      username: 'cristina',
    );
    final tasks = VolunteerBoardParser.parse(updated);
    final t = tasks.firstWhere((e) => e.id == 'TDC-001');
    expect(t.status, 'En cours');
    expect(t.takenBy, '@cristina');
    expect(t.isLibre, isFalse);
  });
}
