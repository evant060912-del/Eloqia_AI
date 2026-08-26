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

      await tester.pump(const Duration(milliseconds: 500));


      // Vérifie que MaterialApp existe
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );


      // Vérifie que l'identité Eloqia apparaît
      expect(
        find.text('ELOQIA AI'),
        findsOneWidget,
      );


    },
  );

}