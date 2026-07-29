import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:eloqia_ai/main.dart';


void main() {

  testWidgets(
    'Eloqia AI application starts successfully',
    (WidgetTester tester) async {


      await tester.pumpWidget(
        const EloqiaApp(),
      );


      // Vérifie que MaterialApp existe
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );


      // Vérifie que l'identité Eloqia apparaît
      expect(
        find.text('Eloqia AI'),
        findsOneWidget,
      );


      // Vérifie que l'écran possède un bouton principal
      expect(
        find.text('Begin your journey'),
        findsOneWidget,
      );

    },
  );

}