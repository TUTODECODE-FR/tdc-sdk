// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/widgets/tdc_highlighting_controller.dart';

void main() {
  test('highlights TDC keywords, strings and comments', () {
    final controller = TdcHighlightingController(
      text: '// comment\ntdc-version: 2\ntype: course\ncourse "x" {\n  title: "Hello"\n}\n',
    );
    final span = controller.buildHighlightedSpan();
    final colors = <Color?>[];
    void collect(InlineSpan s) {
      if (s is TextSpan) {
        colors.add(s.style?.color);
        s.children?.forEach(collect);
      }
    }
    collect(span);

    expect(colors, contains(TdcHighlightingController.keywordColor));
    expect(colors, contains(TdcHighlightingController.stringColor));
    expect(colors, contains(TdcHighlightingController.commentColor));
    expect(colors, contains(TdcHighlightingController.operatorColor));
  });
}
