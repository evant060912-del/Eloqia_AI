import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),

        gradient: LinearGradient(
          colors: [
            const Color(0xFF111827),
            const Color(0xFF1F2937),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _buildTitle(),

          const SizedBox(height: 24),

          Row(
            children: [

              Expanded(
                child: _ProgressCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak',
                  value: '7 Days',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _ProgressCard(
                  icon: Icons.star_rounded,
                  title: 'Level',
                  value: 'B2',
                ),
              ),

            ],
          ),


          const SizedBox(height: 12),


          Row(
            children: [

              Expanded(
                child: _ProgressCard(
                  icon: Icons.bolt_rounded,
                  title: 'XP',
                  value: '2450',
                ),
              ),


              const SizedBox(width: 12),


              Expanded(
                child: _ProgressCard(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Speaking',
                  value: '45 min',
                ),
              ),

            ],
          ),


          const SizedBox(height: 24),


          _buildSkillAnalysis(),

        ],
      ),
    );
  }



  Widget _buildTitle() {

    return Row(
      children: [

        const Icon(
          Icons.insights_rounded,
          color: Colors.white,
          size: 28,
        ),


        const SizedBox(width: 12),


        const Text(
          'Your Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

      ],
    );
  }



  Widget _buildSkillAnalysis() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          'Learning Intelligence',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),


        const SizedBox(height: 18),


        _SkillProgress(
          name: 'Vocabulary',
          percentage: 0.72,
        ),


        const SizedBox(height: 14),


        _SkillProgress(
          name: 'Grammar',
          percentage: 0.56,
        ),


        const SizedBox(height: 14),


        _SkillProgress(
          name: 'Speaking',
          percentage: 0.68,
        ),

      ],
    );
  }
}





class _ProgressCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;


  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.value,
  });



  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),


      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),

      ),


      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),


          const SizedBox(height: 12),


          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),


          const SizedBox(height: 4),


          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }
}





class _SkillProgress extends StatelessWidget {

  final String name;
  final double percentage;


  const _SkillProgress({
    required this.name,
    required this.percentage,
  });



  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),


            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),

          ],
        ),


        const SizedBox(height: 8),


        ClipRRect(

          borderRadius: BorderRadius.circular(20),


          child: LinearProgressIndicator(

            value: percentage,

            minHeight: 8,

            backgroundColor:
                Colors.white.withValues(alpha: 0.10),

            valueColor:
                const AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),

          ),
        ),

      ],
    );
  }
}