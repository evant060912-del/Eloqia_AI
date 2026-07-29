import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';


class TutorCard extends StatelessWidget {

  const TutorCard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(26),


      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(32),


        gradient: LinearGradient(

          colors: [

            AppColors.primary.withValues(alpha: 0.18),

            AppColors.secondary.withValues(alpha: 0.18),

          ],


          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),



        border: Border.all(

          color: AppColors.primary.withValues(alpha: 0.35),

          width: 1.2,

        ),



        boxShadow: [

          BoxShadow(

            color: AppColors.primary.withValues(alpha: 0.18),

            blurRadius: 35,

            spreadRadius: 5,

          ),

        ],

      ),



      child: Column(

        children: [



          // Avatar temporaire de Mia
          Container(

            width: 100,

            height: 100,


            decoration: BoxDecoration(

              shape: BoxShape.circle,


              color: Colors.white.withValues(alpha: 0.08),


              border: Border.all(

                color: AppColors.primary.withValues(alpha: 0.5),

                width: 2,

              ),


              boxShadow: [

                BoxShadow(

                  color: AppColors.primary.withValues(alpha: 0.25),

                  blurRadius: 25,

                ),

              ],

            ),



            child: const Center(

              child: Text(

                "🌴",

                style: TextStyle(

                  fontSize: 50,

                ),

              ),

            ),

          ),




          const SizedBox(height: 22),




          // Nom

          Text(

            "Mia",

            style: TextStyle(

              color: AppColors.primary,

              fontSize: 34,

              fontWeight: FontWeight.w900,

            ),

          ),




          const SizedBox(height: 6),




          Text(

            "Californian English Tutor",

            style: TextStyle(

              color: AppColors.textSecondary,

              fontSize: 16,

            ),

          ),




          const SizedBox(height: 18),




          // Statut

          Container(

            padding: const EdgeInsets.symmetric(

              horizontal: 16,

              vertical: 8,

            ),


            decoration: BoxDecoration(

              color: Colors.green.withValues(alpha: 0.15),

              borderRadius: BorderRadius.circular(20),

            ),



            child: const Row(

              mainAxisSize: MainAxisSize.min,

              children: [


                Icon(

                  Icons.circle,

                  color: Colors.green,

                  size: 10,

                ),



                SizedBox(width: 8),



                Text(

                  "ONLINE",

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 12,

                    fontWeight: FontWeight.bold,

                  ),

                ),


              ],

            ),

          ),




          const SizedBox(height: 22),





          Text(

            "\"I'm ready to help you improve your English ✨\"",

            textAlign: TextAlign.center,


            style: TextStyle(

              color: Colors.white.withValues(alpha: 0.85),

              fontSize: 15,

              fontStyle: FontStyle.italic,

            ),

          ),




          const SizedBox(height: 25),




          // Informations

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceAround,


            children: [


              _InfoItem(

                icon: "🎯",

                text: "Conversation",

              ),



              _InfoItem(

                icon: "🌎",

                text: "American",

              ),



              _InfoItem(

                icon: "⭐",

                text: "Beginner",

              ),


            ],

          ),




          const SizedBox(height: 28),




          SizedBox(

            width: double.infinity,

            height: 52,


            child: ElevatedButton(

              onPressed: () {},



              style: ElevatedButton.styleFrom(

                backgroundColor: AppColors.primary,

                foregroundColor: Colors.black,

                elevation: 0,


                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(30),

                ),

              ),



              child: const Text(

                "START LESSON 🚀",

                style: TextStyle(

                  fontWeight: FontWeight.bold,

                  letterSpacing: 1,

                ),

              ),

            ),

          ),



        ],

      ),

    );

  }

}





class _InfoItem extends StatelessWidget {


  final String icon;

  final String text;



  const _InfoItem({

    required this.icon,

    required this.text,

  });



  @override
  Widget build(BuildContext context) {


    return Column(

      children: [


        Text(

          icon,

          style: const TextStyle(

            fontSize: 22,

          ),

        ),



        const SizedBox(height: 6),



        Text(

          text,

          style: TextStyle(

            color: AppColors.textSecondary,

            fontSize: 11,

          ),

        ),


      ],

    );

  }

}