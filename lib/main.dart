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

  const EloqiaApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      // Supprime le bandeau DEBUG
      debugShowCheckedModeBanner: false,


      // Nom officiel de l'application
      title: "Eloqia AI",


      // Thème global
      theme: AppTheme.darkTheme,


      // Première page
      home: const SplashScreen(),

    );

  }

}
