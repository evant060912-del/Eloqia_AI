import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/tutor_card.dart';


class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,


      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),


          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,


            children: [


              const SizedBox(height: 20),



              Text(

                "ELOQIA AI",

                style: TextStyle(

                  color: AppColors.primary,

                  fontSize: 32,

                  fontWeight: FontWeight.bold,

                  letterSpacing: 3,

                ),

              ),



              const SizedBox(height: 35),



              Text(

                "Welcome back 👋",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 28,

                  fontWeight: FontWeight.bold,

                ),

              ),



              const SizedBox(height: 8),



              Text(

                "Your AI English Academy",

                style: TextStyle(

                  color: AppColors.textSecondary,

                  fontSize: 16,

                ),

              ),



              const SizedBox(height: 40),



              const TutorCard(),



              const SizedBox(height: 40),



              Text(

                "Your progress",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 22,

                  fontWeight: FontWeight.bold,

                ),

              ),



              const SizedBox(height: 15),



              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(20),


                decoration: BoxDecoration(

                  color: Colors.white.withOpacity(0.05),

                  borderRadius: BorderRadius.circular(20),

                ),


                child: Text(

                  "Progress system coming soon 🚀",

                  style: TextStyle(

                    color: AppColors.textSecondary,

                  ),

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }

}
