import 'dart:async';

import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../../theme/app_colors.dart';


class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

}


class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {


  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;


  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;


  final List<String> _loadingMessages = [

    "Initializing Eloqia AI...",
    "Loading language intelligence...",
    "Preparing AI tutors...",
    "Creating your learning universe...",

  ];


  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _navigationTimer;



  @override
  void initState() {

    super.initState();


    _fadeController = AnimationController(

      duration: const Duration(seconds: 2),

      vsync: this,

    );


    _fadeAnimation = CurvedAnimation(

      parent: _fadeController,

      curve: Curves.easeInOut,

    );



    _scaleController = AnimationController(

      duration: const Duration(seconds: 2),

      vsync: this,

    );


    _scaleAnimation = Tween<double>(

      begin: 0.75,

      end: 1,

    ).animate(

      CurvedAnimation(

        parent: _scaleController,

        curve: Curves.easeOutBack,

      ),

    );



    _pulseController = AnimationController(

      duration: const Duration(seconds: 2),

      vsync: this,

    )
      ..repeat(reverse: true);



    _pulseAnimation = Tween<double>(

      begin: 0.95,

      end: 1.05,

    ).animate(

      CurvedAnimation(

        parent: _pulseController,

        curve: Curves.easeInOut,

      ),

    );



    _fadeController.forward();
    _scaleController.forward();



    _startLoadingMessages();

    _goToHome();

  }



  void _startLoadingMessages() {


    _messageTimer = Timer.periodic(

      const Duration(milliseconds: 900),

      (timer) {


        if (!mounted) return;


        setState(() {

          _messageIndex =
              (_messageIndex + 1) % _loadingMessages.length;

        });


      },

    );


  }




  void _goToHome() {


    _navigationTimer = Timer(

      const Duration(seconds: 5),

      () {


        if (!mounted) return;


        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) => const HomeScreen(),

          ),

        );


      },

    );


  }





  @override
  void dispose() {


    _fadeController.dispose();

    _scaleController.dispose();

    _pulseController.dispose();


    _messageTimer?.cancel();

    _navigationTimer?.cancel();


    super.dispose();

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      body: Container(


        decoration: const BoxDecoration(


          gradient: LinearGradient(

            colors: [

              Color(0xFF020617),

              Color(0xFF071A33),

              Color(0xFF001F3F),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),



        child: Stack(


          children: [



            Center(


              child: AnimatedBuilder(


                animation: _pulseAnimation,


                builder: (context, child) {


                  return Container(


                    width: 240 * _pulseAnimation.value,

                    height: 240 * _pulseAnimation.value,


                    decoration: BoxDecoration(


                      shape: BoxShape.circle,


                      boxShadow: [


                        BoxShadow(


                          color: AppColors.primary.withOpacity(0.45),

                          blurRadius: 100,

                          spreadRadius: 25,


                        ),


                      ],


                    ),


                  );


                },


              ),


            ),




            Center(


              child: FadeTransition(


                opacity: _fadeAnimation,


                child: ScaleTransition(


                  scale: _scaleAnimation,


                  child: Column(


                    mainAxisAlignment: MainAxisAlignment.center,


                    children: [



                      AnimatedBuilder(


                        animation: _pulseAnimation,


                        builder: (context, child) {


                          return Transform.scale(


                            scale: _pulseAnimation.value,


                            child: Text(


                              "ELOQIA",


                              style: TextStyle(


                                color: AppColors.primary,

                                fontSize: 52,

                                fontWeight: FontWeight.w900,

                                letterSpacing: 10,


                                shadows: [


                                  Shadow(

                                    color: AppColors.primary,

                                    blurRadius: 25,

                                  ),

                                ],


                              ),


                            ),


                          );


                        },


                      ),



                      const SizedBox(height: 5),



                      Text(


                        "AI",


                        style: TextStyle(


                          color: AppColors.secondary,

                          fontSize: 30,

                          fontWeight: FontWeight.bold,

                          letterSpacing: 14,


                        ),


                      ),




                      const SizedBox(height: 30),




                      Text(


                        "Your AI language academy",


                        style: TextStyle(


                          color: AppColors.textSecondary,

                          fontSize: 16,


                        ),


                      ),




                      const SizedBox(height: 50),




                      SizedBox(


                        width: 220,


                        child: LinearProgressIndicator(


                          minHeight: 5,


                          backgroundColor: Colors.white12,


                          color: AppColors.primary,


                        ),


                      ),




                      const SizedBox(height: 18),




                      AnimatedSwitcher(


                        duration: const Duration(milliseconds: 400),


                        child: Text(


                          _loadingMessages[_messageIndex],


                          key: ValueKey(_messageIndex),


                          style: TextStyle(


                            color: AppColors.textSecondary,

                            fontSize: 13,


                          ),


                        ),


                      ),



                    ],


                  ),


                ),


              ),


            ),


          ],


        ),


      ),


    );


  }


}