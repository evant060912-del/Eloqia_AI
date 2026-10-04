import 'package:flutter/material.dart';

class HeroTutorCard extends StatelessWidget {
  const HeroTutorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(26),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),

        gradient: LinearGradient(
          colors: [
            const Color(0xFF5B8CFF).withValues(alpha: 0.35),
            const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            const Color(0xFF111827).withValues(alpha: 0.85),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),


        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),


        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _buildHeader(),

          const SizedBox(height: 28),

          _buildTutorDescription(),

          const SizedBox(height: 30),

          _buildActionButton(),
        ],
      ),
    );
  }



  Widget _buildHeader() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(
              children: [

                const Text(
                  'Mia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),


                const SizedBox(width: 10),


                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),


                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),

                    borderRadius: BorderRadius.circular(30),
                  ),


                  child: const Text(
                    'ONLINE',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 10),


            Text(
              'Your personal AI English teacher',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 15,
              ),
            ),
          ],
        ),



        Container(

          width: 82,
          height: 82,


          decoration: BoxDecoration(

            shape: BoxShape.circle,


            gradient: const LinearGradient(

              colors: [

                Color(0xFF60A5FA),

                Color(0xFFA78BFA),

              ],

            ),


            boxShadow: [

              BoxShadow(

                color: const Color(0xFF60A5FA)
                    .withValues(alpha: 0.45),

                blurRadius: 30,

              ),

            ],

          ),


          child: const Icon(

            Icons.face_retouching_natural_rounded,

            color: Colors.white,

            size: 42,

          ),
        ),
      ],
    );
  }





  Widget _buildTutorDescription() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'American English',

          style: TextStyle(

            color: Colors.white,

            fontSize: 18,

            fontWeight: FontWeight.w600,

          ),

        ),



        const SizedBox(height: 12),



        Text(

          'Practice natural conversations, improve your confidence, and learn English with a warm AI companion designed around your goals.',

          style: TextStyle(

            color: Colors.white.withValues(alpha: 0.80),

            fontSize: 15,

            height: 1.6,

          ),

        ),
      ],
    );
  }





  Widget _buildActionButton() {

    return SizedBox(

      width: double.infinity,


      child: ElevatedButton.icon(

        onPressed: () {},


        icon: const Icon(

          Icons.chat_rounded,

        ),


        label: const Text(

          'Start a conversation',

        ),


        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.white,

          foregroundColor: Colors.black,


          padding: const EdgeInsets.symmetric(

            vertical: 17,

          ),


          elevation: 0,


          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(22),

          ),


          textStyle: const TextStyle(

            fontSize: 16,

            fontWeight: FontWeight.bold,

          ),

        ),

      ),

    );
  }
}