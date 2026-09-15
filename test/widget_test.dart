// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_orcamento/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Constrói o app removendo o const de UserAccountInfo
    await tester.pumpWidget(MeuAppOrcamento(
      isLoggedIn: false,
      initialUserInfo: UserAccountInfo(
        email: 'teste@orcafacil.com',
        displayName: 'Teste',
      ),
    ));

    // Verifica se o app carrega a tela inicial e exibe o nome do aplicativo
    expect(find.text('OrçaFácil PRO'), findsOneWidget);
  });
}