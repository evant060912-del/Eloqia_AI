import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/tutor_card.dart';
import 'widgets/quick_actions_section.dart';



class HomeScreen extends StatelessWidget {

  const HomeScreen({
    super.key,
  });



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,


      body: SafeArea(

        child: Stack(

          children: [


            _buildBackground(),



            SingleChildScrollView(

              physics:
                  const BouncingScrollPhysics(),


              padding:
                  const EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    50,
                  ),



              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,



                children: [



                  _buildHeader(),



                  const SizedBox(
                    height: 45,
                  ),



                  _buildWelcome(),



                  const SizedBox(
                    height: 35,
                  ),



                  _buildStatsCard(),



                  const SizedBox(
                    height: 45,
                  ),




                  const Text(

                    "Your AI Tutor",

                    style: TextStyle(

                      color:
                          AppColors.textPrimary,

                      fontSize:
                          28,

                      fontWeight:
                          FontWeight.w900,

                    ),

                  ),



                  const SizedBox(
                    height: 18,
                  ),



                  const TutorCard(),



                  const SizedBox(
                    height: 45,
                  ),




                  const Text(

                    "Learning Progress",

                    style: TextStyle(

                      color:
                          AppColors.textPrimary,

                      fontSize:
                          28,

                      fontWeight:
                          FontWeight.w900,

                    ),

                  ),



                  const SizedBox(
                    height: 18,
                  ),



                  _buildProgressCard(),



                  const SizedBox(
                    height: 45,
                  ),



                  const QuickActionsSection(),



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

          top:
              -120,

          right:
              -100,


          child: Container(

            width:
                300,

            height:
                300,


            decoration:

                BoxDecoration(

              shape:
                  BoxShape.circle,


              color:
                  AppColors.primary
                      .withValues(
                        alpha: 0.14,
                      ),

            ),

          ),

        ),




        Positioned(

          bottom:
              150,

          left:
              -130,


          child: Container(

            width:
                280,

            height:
                280,


            decoration:

                BoxDecoration(

              shape:
                  BoxShape.circle,


              color:
                  AppColors.secondary
                      .withValues(
                        alpha: 0.12,
                      ),

            ),

          ),

        ),


      ],

    );

  }







  Widget _buildHeader() {


    return Row(

      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,


      children: [



        Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [



            Text(

              "ELOQIA AI",


              style: TextStyle(

                color:
                    AppColors.primary,


                fontSize:
                    34,


                fontWeight:
                    FontWeight.w900,


                letterSpacing:
                    5,

              ),

            ),



            const SizedBox(
              height: 8,
            ),




            Text(

              "YOUR PERSONAL AI LANGUAGE ACADEMY",


              style: TextStyle(

                color:
                    AppColors.textSecondary,


                fontSize:
                    10,


                letterSpacing:
                    2.2,

              ),

            ),

          ],

        ),




        Container(

          padding:
              const EdgeInsets.all(13),


          decoration:

              BoxDecoration(

            shape:
                BoxShape.circle,


            color:
                AppColors.glass,


            border:
                Border.all(

              color:
                  AppColors.glassBorder,

            ),

          ),



          child: const Icon(

            Icons.person_outline_rounded,


            color:
                AppColors.primary,


            size:
                28,

          ),

        ),

      ],

    );

  }







  Widget _buildWelcome() {


    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,


      children: [


        const Text(

          "Welcome back 👋",


          style:

              TextStyle(

            color:
                AppColors.textPrimary,


            fontSize:
                36,


            fontWeight:
                FontWeight.w900,


            letterSpacing:
                -1,

          ),

        ),




        const SizedBox(
          height: 12,
        ),




        Text(

          "Continue your English evolution with your personal AI academy.",


          style:

              TextStyle(

            color:
                AppColors.textSecondary,


            fontSize:
                16,


            height:
                1.5,

          ),

        ),

      ],

    );

  }







  Widget _buildStatsCard() {


    return Container(

      padding:
          const EdgeInsets.all(24),


      decoration:

          BoxDecoration(

        color:
            AppColors.glass,


        borderRadius:
            BorderRadius.circular(32),



        border:
            Border.all(

          color:
              AppColors.glassBorder,

        ),


        boxShadow: const [

          BoxShadow(

            color:
                AppColors.shadow,


            blurRadius:
                35,


            offset:
                Offset(0, 18),

          ),

        ],

      ),



      child: const Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceAround,


        children: [


          _StatItem(
            icon: "🔥",
            value: "0",
            title: "Streak",
          ),


          _StatItem(
            icon: "⭐",
            value: "0",
            title: "XP",
          ),


          _StatItem(
            icon: "🏆",
            value: "1",
            title: "Level",
          ),

        ],

      ),

    );

  }






  Widget _buildProgressCard() {


    return Container(

      padding:
          const EdgeInsets.all(24),


      decoration:

          BoxDecoration(

        color:
            AppColors.surface,


        borderRadius:
            BorderRadius.circular(30),


        border:
            Border.all(

          color:
              AppColors.glassBorder,

        ),

      ),



      child: const Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [


          Text(

            "English Evolution",

            style:

                TextStyle(

              color:
                  AppColors.textPrimary,


              fontSize:
                  22,


              fontWeight:
                  FontWeight.w900,

            ),

          ),



          SizedBox(
            height: 10,
          ),



          Text(

            "Your journey from A1 to C2 starts here ✨",

            style:

                TextStyle(

              color:
                  AppColors.textSecondary,

            ),

          ),

        ],

      ),

    );

  }


}





class _StatItem extends StatelessWidget {


  final String icon;

  final String value;

  final String title;



  const _StatItem({

    required this.icon,

    required this.value,

    required this.title,

  });



  @override
  Widget build(BuildContext context) {


    return Column(

      children: [


        Text(

          icon,

          style:
              const TextStyle(
                fontSize: 26,
              ),

        ),


        const SizedBox(
          height: 8,
        ),


        Text(

          value,

          style:

              const TextStyle(

            color:
                AppColors.primary,


            fontSize:
                24,


            fontWeight:
                FontWeight.w900,

          ),

        ),



        Text(

          title,

          style:

              const TextStyle(

            color:
                AppColors.textSecondary,


            fontSize:
                12,

          ),

        ),

      ],

    );

  }

}