import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../home/home_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {


  late AnimationController _controller;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textAnimation;



  @override
  void initState() {

    super.initState();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );


    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );


    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );


    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );


    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );


    _controller.forward();



    Future.delayed(
      const Duration(seconds: 4),
      () {

        if (!mounted) return;


        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration:
                const Duration(milliseconds: 900),

            pageBuilder:
                (_, animation, secondaryAnimation) =>
                    const HomeScreen(),

            transitionsBuilder:
                (_, animation, secondaryAnimation, child) {

              return FadeTransition(
                opacity: animation,
                child: child,
              );

            },

          ),
        );

      },

    );

  }



  @override
  void dispose() {

    _controller.dispose();

    super.dispose();

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
          AppColors.background,


      body: Stack(

        alignment:
            Alignment.center,


        children: [



          // Halo lumineux IA

          AnimatedBuilder(

            animation:
                _glowAnimation,


            builder:
                (context, child) {


              return Container(

                width:
                    420 * _glowAnimation.value,


                height:
                    420 * _glowAnimation.value,


                decoration:
                    BoxDecoration(

                  shape:
                      BoxShape.circle,


                  gradient:
                      RadialGradient(

                    colors: [

                      AppColors.primary.withOpacity(
                        0.35 *
                            _glowAnimation.value,
                      ),


                      AppColors.secondary.withOpacity(
                        0.20 *
                            _glowAnimation.value,
                      ),


                      Colors.transparent,

                    ],

                  ),

                ),

              );


            },

          ),




          // Contenu principal centré

          Center(

            child: Column(

              mainAxisAlignment:
                  MainAxisAlignment.center,


              crossAxisAlignment:
                  CrossAxisAlignment.center,


              children: [



                // Logo Eloqia AI

                FadeTransition(

                  opacity:
                      _fadeAnimation,


                  child: ScaleTransition(

                    scale:
                        _scaleAnimation,


                    child: Container(

                      width:
                          330,


                      height:
                          330,


                      alignment:
                          Alignment.center,


                      decoration:
                          BoxDecoration(

                        shape:
                            BoxShape.circle,


                        boxShadow: [

                          BoxShadow(

                            color:
                                AppColors.primary.withOpacity(0.55),


                            blurRadius:
                                90,


                            spreadRadius:
                                20,

                          ),

                        ],

                      ),



                      child: Image.asset(

                        "assets/branding/logo/logo_concept_v1.png",


                        width:
                            300,


                        height:
                            300,


                        fit:
                            BoxFit.contain,

                      ),

                    ),

                  ),

                ),




                const SizedBox(height: 45),




                // Texte

                FadeTransition(

                  opacity:
                      _textAnimation,


                  child: Column(

                    children: [



                      Text(

                        "ELOQIA AI",


                        style:
                            TextStyle(

                          color:
                              Colors.white,


                          fontSize:
                              42,


                          fontWeight:
                              FontWeight.bold,


                          letterSpacing:
                              5,


                          shadows: [

                            Shadow(

                              color:
                                  AppColors.primary,


                              blurRadius:
                                  25,

                            ),

                          ],

                        ),

                      ),



                      const SizedBox(height: 14),



                      Text(

                        "Your AI language academy",


                        style:
                            TextStyle(

                          color:
                              Colors.white.withOpacity(0.75),


                          fontSize:
                              16,


                          letterSpacing:
                              2,

                        ),

                      ),

                    ],

                  ),

                ),


              ],

            ),

          ),

        ],

      ),

    );

  }

}