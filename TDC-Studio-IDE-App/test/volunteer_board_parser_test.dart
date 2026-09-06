// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/data/volunteer_board_fallback.dart';
import 'package:tdc_studio/models/volunteer_task.dart';
import 'package:tdc_studio/services/volunteer_board_parser.dart';

void main() {
  test('parse fallback board yields TDC tasks', () {
    final tasks = VolunteerBoardParser.parse(volunteerBoardFallbackMarkdown);
    expect(tasks.length, greaterThanOrEqualTo(10));
    expect(tasks.first.id, 'TDC-001');
    expect(tasks.first.isLibre, isTrue);
  });

  test('fromGitlabIssue maps state and assignee', () {
    final open = VolunteerTask.fromGitlabIssue({
      'iid': 42,
      'state': 'opened',
      'title': 'Template Docker',
      'description': 'Entrées Docker',
      'labels': ['benevolat', 'wishlist', 'P2'],
      'assignees': <dynamic>[],
      'web_url': 'https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/42',
    });
    expect(open.id, '#42');
    expect(open.isLibre, isTrue);
    expect(open.priority, 'P2');
    expect(open.isIdea, isTrue);

    final taken = VolunteerTask.fromGitlabIssue({
      'iid': 9,
      'state': 'opened',
      'title': 'Empty state quiz',
      'description': '',
      'labels': ['benevolat', 'bug'],
      'assignees': [
        {'username': 'CavaleriCristina'},
      ],
      'web_url': 'https://gitlab.com/x/-/issues/9',
    });
    expect(taken.isEnCours, isTrue);
    expect(taken.takenBy, '@CavaleriCristina');
    expect(taken.isBug, isTrue);

    final done = VolunteerTask.fromGitlabIssue({
      'iid': 1,
      'state': 'closed',
      'title': 'Done',
      'description': '',
      'labels': ['benevolat'],
      'assignees': <dynamic>[],
      'web_url': 'https://gitlab.com/x/-/issues/1',
    });
    expect(done.isFait, isTrue);
  });
}
