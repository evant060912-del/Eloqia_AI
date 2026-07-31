import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';


class TutorCard extends StatefulWidget {

  const TutorCard({
    super.key,
  });


  @override
  State<TutorCard> createState() => _TutorCardState();

}



class _TutorCardState extends State<TutorCard>
    with SingleTickerProviderStateMixin {


  late AnimationController _controller;


  late Animation<double> _pulseAnimation;



  @override
  void initState() {

    super.initState();


    _controller = AnimationController(

      duration: const Duration(
        seconds: 3,
      ),

      vsync: this,

    )..repeat(
      reverse: true,
    );



    _pulseAnimation = Tween<double>(

      begin: 0.95,

      end: 1.05,

    ).animate(

      CurvedAnimation(

        parent: _controller,

        curve: Curves.easeInOut,

      ),

    );


  }



  @override
  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override
  Widget build(BuildContext context) {


    return AnimatedBuilder(

      animation: _pulseAnimation,


      builder: (context, child) {


        return Container(

          width: double.infinity,


          padding: const EdgeInsets.all(24),


          decoration: BoxDecoration(


            borderRadius:
                BorderRadius.circular(32),



            gradient: LinearGradient(

              colors: [

                AppColors.surfaceElevated
                    .withValues(alpha: 0.95),

                AppColors.surface
                    .withValues(alpha: 0.85),

              ],


              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

            ),




            border: Border.all(

              color:
                  AppColors.glassBorder,

              width: 1.2,

            ),




            boxShadow: [


              BoxShadow(

                color:
                    AppColors.glow
                        .withValues(alpha: 0.35),

                blurRadius: 35,

                spreadRadius: 2,

              ),



              const BoxShadow(

                color:
                    AppColors.shadow,

                blurRadius: 30,

                offset:
                    Offset(0, 15),

              ),


            ],


          ),



          child: ClipRRect(

            borderRadius:
                BorderRadius.circular(32),



            child: BackdropFilter(

              filter: ImageFilter.blur(

                sigmaX: 15,

                sigmaY: 15,

              ),


              child: Column(

                children: [


                  _buildBadge(),



                  const SizedBox(
                    height: 22,
                  ),



                  Transform.scale(

                    scale:
                        _pulseAnimation.value,


                    child:
                        _buildAvatar(),

                  ),



                  const SizedBox(
                    height: 20,
                  ),



                  const Text(

                    "Mia",

                    style: TextStyle(

                      color:
                          AppColors.textPrimary,

                      fontSize: 32,

                      fontWeight:
                          FontWeight.w900,

                    ),

                  ),



                  const SizedBox(
                    height: 6,
                  ),



                  Text(

                    "Californian English AI Tutor 🇺🇸",

                    style: TextStyle(

                      color:
                          AppColors.primary,

                      fontSize: 14,

                      fontWeight:
                          FontWeight.w600,

                    ),

                  ),



                  const SizedBox(
                    height: 18,
                  ),



                  const Text(

                    "Your friendly AI companion helping you improve your English naturally from A1 to C2.",


                    textAlign:
                        TextAlign.center,


                    style: TextStyle(

                      color:
                          AppColors.textSecondary,

                      fontSize: 15,

                      height: 1.5,

                    ),

                  ),




                  const SizedBox(
                    height: 24,
                  ),



                  _buildLevel(),




                  const SizedBox(
                    height: 25,
                  ),




                  _buildButton(),


                ],

              ),

            ),

          ),

        );

      },

    );

  }






  Widget _buildBadge() {


    return Container(

      padding:
          const EdgeInsets.symmetric(

            horizontal: 16,

            vertical: 8,

          ),


      decoration: BoxDecoration(

        color:
            AppColors.glass,


        borderRadius:
            BorderRadius.circular(30),


        border: Border.all(

          color:
              AppColors.glassBorder,

        ),

      ),



      child: const Row(

        mainAxisSize:
            MainAxisSize.min,


        children: [


          Icon(

            Icons.auto_awesome,

            color:
                AppColors.primary,

            size:
                16,

          ),


          SizedBox(
            width: 8,
          ),


          Text(

            "AI LANGUAGE TUTOR",

            style: TextStyle(

              color:
                  AppColors.textPrimary,

              fontSize:
                  11,

              fontWeight:
                  FontWeight.w800,

              letterSpacing:
                  1.5,

            ),

          ),


        ],

      ),

    );


  }







  Widget _buildAvatar() {


    return Container(

      width:
          120,


      height:
          120,



      decoration: BoxDecoration(

        shape:
            BoxShape.circle,


        gradient:
            const LinearGradient(

              colors: [

                AppColors.primary,

                AppColors.secondary,

              ],

            ),



        boxShadow: [

          BoxShadow(

            color:
                AppColors.aura,

            blurRadius:
                35,

            spreadRadius:
                8,

          ),

        ],


      ),



      child: const Center(

        child: Icon(

          Icons.face_retouching_natural,

          size:
              65,

          color:
              Colors.white,

        ),

      ),

    );


  }







  Widget _buildLevel() {


    return Container(

      padding:
          const EdgeInsets.symmetric(

            horizontal: 22,

            vertical: 12,

          ),


      decoration: BoxDecoration(

        color:
            AppColors.glass,


        borderRadius:
            BorderRadius.circular(20),


        border: Border.all(

          color:
              AppColors.glassBorder,

        ),

      ),



      child: const Row(

        mainAxisAlignment:
            MainAxisAlignment.center,


        children: [


          Icon(

            Icons.school_rounded,

            color:
                AppColors.xp,

            size:
                20,

          ),


          SizedBox(
            width: 10,
          ),



          Text(

            "English Level : A1 → C2",

            style: TextStyle(

              color:
                  AppColors.textPrimary,

              fontWeight:
                  FontWeight.w700,

            ),

          ),


        ],

      ),

    );


  }







  Widget _buildButton() {


    return Container(

      width:
          double.infinity,


      height:
          55,



      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(20),


        gradient:
            const LinearGradient(

              colors: [

                AppColors.primary,

                AppColors.secondary,

              ],

            ),


        boxShadow: [

          BoxShadow(

            color:
                AppColors.primary
                    .withValues(alpha: 0.35),

            blurRadius:
                20,

          ),

        ],


      ),



      child: const Center(

        child: Row(

          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [


            Icon(

              Icons.chat_bubble_outline_rounded,

              color:
                  Colors.white,

            ),



            SizedBox(

              width:
                  10,

            ),



            Text(

              "Start conversation",

              style: TextStyle(

                color:
                    Colors.white,

                fontSize:
                    16,

                fontWeight:
                    FontWeight.w800,

              ),

            ),


          ],


        ),

      ),

    );


  }


}