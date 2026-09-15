// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_orcamento/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MeuAppOrcamento());

    // Verify that our app builds successfully and shows the main title.
    expect(find.text('Orçamentos & Recibos'), findsOneWidget);
  });
}