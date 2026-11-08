import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// What the app can say about Mia's services, for the System status screen.
class ServiceCheck {
  const ServiceCheck(this.name, this.state, this.message);

  final String name;

  /// ok, missing, invalid_key, no_credit, rate_limited, not_found,
  /// unreachable, error, not_configured.
  final String state;
  final String message;

  bool get ok => state == 'ok';
}

class SystemStatus {
  const SystemStatus(this.checks);

  final List<ServiceCheck> checks;

  bool get allOk => checks.every((ServiceCheck c) => c.ok);

  static const String launchHint =
      'Start the backend (see README), then launch the app with '
      '--dart-define=ELOQIA_API_URL=http://localhost:8000 '
      '--dart-define=ELOQIA_VOICE_API_URL=http://localhost:8000';

  /// Checks the configured backend, then OpenAI and Cartesia through it.
  static Future<SystemStatus> check({
    required String apiUrl,
    http.Client? client,
  }) async {
    if (apiUrl.isEmpty) {
      return const SystemStatus(<ServiceCheck>[
        ServiceCheck(
          'App configuration',
          'not_configured',
          'The app was started without the server address, so Mia cannot '
              'chat, review or speak. $launchHint',
        ),
      ]);
    }
    final http.Client http0 = client ?? http.Client();
    try {
      final Uri base = Uri.parse(apiUrl);
      final http.Response health = await http0
          .get(base.resolve('/health'))
          .timeout(const Duration(seconds: 6));
      if (health.statusCode != 200) {
        return SystemStatus(<ServiceCheck>[
          ServiceCheck(
            'Eloqia server',
            'error',
            'The server answered ${health.statusCode}. Restart it and look at '
                'its console for errors.',
          ),
        ]);
      }
      final http.Response diag = await http0
          .get(base.resolve('/v1/system/diagnostics'))
          .timeout(const Duration(seconds: 20));
      final Object? json = jsonDecode(diag.body);
      if (diag.statusCode != 200 || json is! Map) {
        return const SystemStatus(<ServiceCheck>[
          ServiceCheck('Eloqia server', 'ok', 'The server is running.'),
          ServiceCheck(
            'Diagnostics',
            'error',
            'This server version cannot run diagnostics: update the backend.',
          ),
        ]);
      }
      ServiceCheck read(String key, String name) {
        final Object? item = json[key];
        if (item is! Map) return ServiceCheck(name, 'error', 'No answer.');
        return ServiceCheck(name, '${item['state']}', '${item['message']}');
      }

      return SystemStatus(<ServiceCheck>[
        const ServiceCheck('Eloqia server', 'ok', 'The server is running.'),
        read('openai', 'OpenAI (chat, reviews, feedback)'),
        read('cartesia', 'Cartesia (Mia’s voice)'),
      ]);
    } on Object {
      return const SystemStatus(<ServiceCheck>[
        ServiceCheck(
          'Eloqia server',
          'unreachable',
          'The server does not answer. Is it running? (In the backend '
              'folder: uvicorn app.api:app --port 8000)',
        ),
      ]);
    } finally {
      if (client == null) http0.close();
    }
  }
}
