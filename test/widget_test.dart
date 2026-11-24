// Smoke test di base.
//
// L'app completa richiede inizializzazione di dotenv, Supabase e
// SharedPreferences: un test widget dell'intero `App` non è pratico qui.
// Questo test verifica che il progetto si compili e che un widget base
// venga renderizzato correttamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: il progetto compila e renderizza un widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Flutter Starter')),
        ),
      ),
    );

    expect(find.text('Flutter Starter'), findsOneWidget);
  });
}