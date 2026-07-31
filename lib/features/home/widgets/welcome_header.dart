import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // App identity
        const Text(
          'ELOQIA AI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Your personal AI English teacher',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 35),


        // Welcome message
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Welcome back, Evan 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Ready to continue your English journey?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                ],
              ),
            ),


            _HeaderIcon(
              icon: Icons.notifications_none_rounded,
            ),

          ],
        ),
      ],
    );
  }
}


class _HeaderIcon extends StatelessWidget {

  final IconData icon;

  const _HeaderIcon({
    required this.icon,
  });


  @override
  Widget build(BuildContext context) {

    return Container(
      width: 48,
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),

      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}