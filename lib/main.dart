import 'package:flutter/material.dart';

import 'app/persistent_app_controller.dart';
import 'features/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PersistentAppController appController =
      PersistentAppController.instance;

  await appController.restore();

  runApp(
    const EloqiaApp(),
  );
}

class EloqiaApp extends StatelessWidget {
  const EloqiaApp({
    super.key,
  });

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