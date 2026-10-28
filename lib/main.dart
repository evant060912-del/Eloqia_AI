import 'package:flutter/material.dart';

import 'app/persistent_app_controller.dart';
import 'features/splash/splash_screen.dart';
import 'services/voice/backend_speech_transport.dart';
import 'services/voice/voice_output_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PersistentAppController appController =
      PersistentAppController.instance;

  try {
    await appController.restore();
  } on Object catch (error, stackTrace) {
    // Never block startup: the splash then routes to onboarding.
    debugPrint('ELOQIA ERROR: local data restore failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Mia's Cartesia voice, served by the Eloqia backend. Without
  // --dart-define=ELOQIA_VOICE_API_URL=..., Mia stays silent (no crash).
  // When account sign-in exists, pass its token getter here.
  final BackendCloudSpeechTransport? speech =
      BackendCloudSpeechTransport.fromEnvironment(accessTokenProvider: null);
  if (speech != null) {
    MiaVoice.configure(speech);
  }

  runApp(const EloqiaApp());
}

class EloqiaApp extends StatelessWidget {
  const EloqiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eloqia AI',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
