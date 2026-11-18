import 'dart:convert';

import 'package:eloqia_ai/features/system/system_status.dart';
import 'package:eloqia_ai/features/system/system_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('no server address: explains how to launch', () async {
    final SystemStatus status = await SystemStatus.check(apiUrl: '');
    expect(status.allOk, isFalse);
    expect(status.checks.single.state, 'not_configured');
    expect(status.checks.single.message, contains('ELOQIA_API_URL'));
  });

  test('reads OpenAI and Cartesia states from the server', () async {
    final MockClient client = MockClient((http.Request request) async {
      if (request.url.path == '/health') {
        return http.Response('{"status":"ok"}', 200);
      }
      return http.Response(
        jsonEncode(<String, Object>{
          'status': 'attention',
          'openai': <String, String>{'state': 'ok', 'message': 'fine'},
          'cartesia': <String, String>{
            'state': 'no_credit',
            'message': 'Cartesia has no credit left.',
          },
        }),
        200,
      );
    });
    final SystemStatus status = await SystemStatus.check(
      apiUrl: 'http://localhost:8000',
      client: client,
    );
    expect(status.checks.map((ServiceCheck c) => c.state), <String>[
      'ok',
      'ok',
      'no_credit',
    ]);
    expect(status.allOk, isFalse);
  });

  test('a stopped server is reported as unreachable', () async {
    final MockClient client = MockClient(
      (http.Request request) async => throw Exception('refused'),
    );
    final SystemStatus status = await SystemStatus.check(
      apiUrl: 'http://localhost:8000',
      client: client,
    );
    expect(status.checks.single.state, 'unreachable');
  });

  testWidgets('the screen lists each check', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SystemStatusScreen(
          checker: () async => const SystemStatus(<ServiceCheck>[
            ServiceCheck('Eloqia server', 'ok', 'The server is running.'),
            ServiceCheck('Cartesia (Mia’s voice)', 'no_credit', 'No credit.'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Something needs attention:'), findsOneWidget);
    expect(find.text('No credit.'), findsOneWidget);
  });
}
