import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';


class MiaScreen extends StatefulWidget {
  const MiaScreen({super.key});


  @override
  State<MiaScreen> createState() => _MiaScreenState();
}



class _MiaScreenState extends State<MiaScreen>
    with SingleTickerProviderStateMixin {


  late final AnimationController _animationController;


  @override
  void initState() {
    super.initState();


    _animationController = AnimationController(

      vsync: this,

      duration: const Duration(seconds: 3),

    )..repeat(reverse: true);

  }



  @override
  void dispose() {

    _animationController.dispose();

    super.dispose();

  }




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
          AppColors.background,


      body: SafeArea(

        child: Stack(

          children: [


            _buildBackground(),



            SingleChildScrollView(

              physics:
                  const BouncingScrollPhysics(),


              padding:
                  const EdgeInsets.all(24),



              child: Column(

                children: [


                  const SizedBox(height: 30),



                  _buildMiaAvatar(),



                  const SizedBox(height: 35),



                  _buildWelcome(),



                  const SizedBox(height: 30),



                  _buildStatus(),



                  const SizedBox(height: 35),



                  _buildConversationButton(),



                  const SizedBox(height: 35),



                  _buildProgressCard(),


                ],

              ),

            ),

          ],

        ),

      ),

    );

  }






  Widget _buildBackground() {


    return Stack(

      children: [


        Positioned(

          top: -120,

          right: -100,

          child: Container(

            width: 280,

            height: 280,


            decoration: BoxDecoration(

              shape:
                  BoxShape.circle,


              color:
                  AppColors.primary.withValues(
                    alpha: 0.12,
                  ),

            ),

          ),

        ),



        Positioned(

          bottom: -100,

          left: -100,

          child: Container(

            width: 260,

            height: 260,


            decoration: BoxDecoration(

              shape:
                  BoxShape.circle,


              color:
                  AppColors.secondary.withValues(
                    alpha: 0.12,
                  ),

            ),

          ),

        ),


      ],

    );

  }






  Widget _buildMiaAvatar() {


    return AnimatedBuilder(

      animation:
          _animationController,


      builder:
          (context, child) {


        final glow =
            30 +
            (_animationController.value * 20);



        return Container(

          padding:
              EdgeInsets.all(
                12 +
                (_animationController.value * 6),
              ),



          decoration:
              BoxDecoration(


            shape:
                BoxShape.circle,



            boxShadow: [


              BoxShadow(

                color:
                    AppColors.primary.withValues(
                      alpha: 0.45,
                    ),


                blurRadius:
                    glow,


                spreadRadius:
                    8,

              ),


            ],


          ),



          child:
              child,

        );

      },



      child: Container(

        height:
            150,


        width:
            150,



        decoration:
            const BoxDecoration(


          shape:
              BoxShape.circle,



          gradient:
              LinearGradient(


            colors: [

              AppColors.primary,

              AppColors.secondary,

            ],


          ),


        ),



        child:
            const Icon(

          Icons.smart_toy_rounded,


          color:
              Colors.white,


          size:
              75,


        ),


      ),

    );

  }







  Widget _buildWelcome() {


    return Column(

      children: [


        const Text(

          "Hi Evan 👋",

          textAlign:
              TextAlign.center,


          style:
              TextStyle(

            color:
                AppColors.textPrimary,


            fontSize:
                34,


            fontWeight:
                FontWeight.w900,


          ),

        ),



        const SizedBox(height: 8),



        const Text(

          "I'm Mia",

          style:
              TextStyle(

            color:
                AppColors.primary,


            fontSize:
                28,


            fontWeight:
                FontWeight.w800,


          ),

        ),



        const SizedBox(height: 12),



        const Text(

          "Your Californian English Tutor 🇺🇸",

          textAlign:
              TextAlign.center,


          style:
              TextStyle(

            color:
                AppColors.textSecondary,


            fontSize:
                17,


          ),

        ),


      ],

    );

  }








  Widget _buildStatus() {


    return Container(

      padding:
          const EdgeInsets.symmetric(

        horizontal:
            18,

        vertical:
            10,

      ),


      decoration:
          BoxDecoration(

        color:
            AppColors.success.withValues(
              alpha: 0.15,
            ),


        borderRadius:
            BorderRadius.circular(30),


        border:
            Border.all(

          color:
              AppColors.success,

        ),


      ),



      child:
          const Text(

        "● Mia is ready to teach",


        style:
            TextStyle(

          color:
              AppColors.success,


          fontWeight:
              FontWeight.bold,


        ),

      ),

    );

  }








  Widget _buildConversationButton() {


    return GestureDetector(


      onTap: () {},



      child: Container(

        height:
            65,


        width:
            double.infinity,



        decoration:
            BoxDecoration(


          borderRadius:
              BorderRadius.circular(35),



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
                  AppColors.glow,


              blurRadius:
                  30,


            ),


          ],


        ),



        child:
            const Row(

          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [


            Icon(

              Icons.mic_rounded,

              color:
                  Colors.white,

            ),



            SizedBox(width: 12),



            Text(

              "Start Conversation",


              style:
                  TextStyle(

                color:
                    Colors.white,


                fontSize:
                    18,


                fontWeight:
                    FontWeight.w800,


              ),

            ),


          ],


        ),


      ),

    );

  }









  Widget _buildProgressCard() {


    return Container(

      width:
          double.infinity,


      padding:
          const EdgeInsets.all(24),



      decoration:
          BoxDecoration(


        color:
            AppColors.glass,


        borderRadius:
            BorderRadius.circular(30),



        border:
            Border.all(

          color:
              AppColors.glassBorder,


        ),


      ),



      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [


          const Text(

            "Today's Progress",


            style:
                TextStyle(

              color:
                  AppColors.textPrimary,


              fontSize:
                  22,


              fontWeight:
                  FontWeight.w800,


            ),

          ),



          const SizedBox(height: 22),



          ClipRRect(

            borderRadius:
                BorderRadius.circular(20),


            child:
                const LinearProgressIndicator(

              value:
                  0.7,


              minHeight:
                  12,


              backgroundColor:
                  AppColors.surface,


              valueColor:
                  AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),


            ),

          ),



          const SizedBox(height: 18),



          const Text(

            "700 XP earned today ⭐",


            style:
                TextStyle(

              color:
                  AppColors.xp,


              fontWeight:
                  FontWeight.bold,


            ),

          ),


        ],

      ),

    );

  }

}

