import 'package:flutter/material.dart';

import 'features/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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