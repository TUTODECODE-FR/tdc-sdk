// Basic Flutter widget test for the unified TDC Studio launcher.
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_studio/main.dart';

void main() {
  testWidgets('TDC Studio launcher shows two modes', (WidgetTester tester) async {
    await tester.pumpWidget(const TdcStudioApp());

    expect(find.text('TDC Studio'), findsOneWidget);
    expect(find.text('Éditeur de Cours'), findsOneWidget);
    expect(find.text('Dev & Traduction'), findsOneWidget);
  });
}
