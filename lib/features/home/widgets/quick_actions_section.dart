import 'package:flutter/material.dart';


class QuickActionsSection extends StatelessWidget {

  const QuickActionsSection({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        _buildHeader(),

        const SizedBox(height: 24),


        GridView.builder(

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),


          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: 2,

            crossAxisSpacing: 16,

            mainAxisSpacing: 16,

            childAspectRatio: 0.90,

          ),


          itemCount: quickActions.length,


          itemBuilder: (context, index) {

            final action = quickActions[index];


            return QuickActionCard(

              icon: action.icon,

              title: action.title,

              description: action.description,

              gradient: action.gradient,

            );

          },

        ),

      ],

    );

  }



  Widget _buildHeader() {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,


      children: [

        Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [

            const Text(

              "Quick Actions",

              style: TextStyle(

                color: Colors.white,

                fontSize: 28,

                fontWeight: FontWeight.w800,

                letterSpacing: -0.6,

              ),

            ),


            const SizedBox(height: 6),


            Text(

              "Your personalized English journey",

              style: TextStyle(

                color: Colors.white.withValues(alpha: 0.65),

                fontSize: 14,

              ),

            ),

          ],

        ),


        Container(

          padding: const EdgeInsets.all(10),


          decoration: BoxDecoration(

            shape: BoxShape.circle,

            color: Colors.white.withValues(alpha: 0.10),

          ),


          child: const Icon(

            Icons.auto_awesome_rounded,

            color: Colors.white,

            size: 24,

          ),

        ),

      ],

    );

  }

}





class QuickActionData {


  final IconData icon;

  final String title;

  final String description;

  final List<Color> gradient;



  const QuickActionData({

    required this.icon,

    required this.title,

    required this.description,

    required this.gradient,

  });

}





const List<QuickActionData> quickActions = [


  QuickActionData(

    icon: Icons.record_voice_over_rounded,

    title: "Conversation",

    description: "Speak naturally with your AI tutor",

    gradient: [

      Color(0xFF2563EB),

      Color(0xFF7C3AED),

    ],

  ),



  QuickActionData(

    icon: Icons.auto_stories_rounded,

    title: "Vocabulary",

    description: "Expand your English vocabulary",

    gradient: [

      Color(0xFF8B5CF6),

      Color(0xFFEC4899),

    ],

  ),



  QuickActionData(

    icon: Icons.edit_note_rounded,

    title: "Grammar",

    description: "Improve your accuracy",

    gradient: [

      Color(0xFFEC4899),

      Color(0xFFF97316),

    ],

  ),



  QuickActionData(

    icon: Icons.headphones_rounded,

    title: "Listening",

    description: "Train your understanding",

    gradient: [

      Color(0xFF06B6D4),

      Color(0xFF2563EB),

    ],

  ),



  QuickActionData(

    icon: Icons.draw_rounded,

    title: "Writing",

    description: "Create essays and improve style",

    gradient: [

      Color(0xFF10B981),

      Color(0xFF14B8A6),

    ],

  ),



  QuickActionData(

    icon: Icons.school_rounded,

    title: "Academic",

    description: "Master advanced English skills",

    gradient: [

      Color(0xFFF59E0B),

      Color(0xFFEF4444),

    ],

  ),

];

class QuickActionCard extends StatefulWidget {

  final IconData icon;

  final String title;

  final String description;

  final List<Color> gradient;



  const QuickActionCard({

    super.key,

    required this.icon,

    required this.title,

    required this.description,

    required this.gradient,

  });



  @override
  State<QuickActionCard> createState() =>
      _QuickActionCardState();

}





class _QuickActionCardState extends State<QuickActionCard> {

  bool isPressed = false;



  void _changeState(bool value) {

    setState(() {

      isPressed = value;

    });

  }



  @override
  Widget build(BuildContext context) {


    return GestureDetector(

      onTapDown: (_) => _changeState(true),

      onTapUp: (_) => _changeState(false),

      onTapCancel: () => _changeState(false),



      child: AnimatedScale(

        scale: isPressed ? 0.96 : 1,

        duration: const Duration(milliseconds: 180),



        child: AnimatedContainer(

          duration: const Duration(milliseconds: 300),


          padding: const EdgeInsets.all(18),



          decoration: BoxDecoration(


            borderRadius: BorderRadius.circular(32),



            gradient: LinearGradient(

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,


              colors: [

                widget.gradient.first.withValues(alpha: 0.85),

                widget.gradient.last.withValues(alpha: 0.55),

              ],

            ),



            border: Border.all(

              color: Colors.white.withValues(alpha: 0.20),

              width: 1.2,

            ),



            boxShadow: [

              BoxShadow(

                color: widget.gradient.first
                    .withValues(alpha: 0.30),

                blurRadius: 30,

                offset: const Offset(0, 15),

              ),


              BoxShadow(

                color: Colors.black.withValues(alpha: 0.35),

                blurRadius: 25,

                offset: const Offset(0, 12),

              ),

            ],

          ),



          child: Column(


            crossAxisAlignment: CrossAxisAlignment.start,


            mainAxisAlignment:
                MainAxisAlignment.center,



            children: [


              Container(

                width: 56,

                height: 56,



                decoration: BoxDecoration(


                  shape: BoxShape.circle,


                  color: Colors.white.withValues(alpha: 0.16),



                  border: Border.all(

                    color: Colors.white.withValues(alpha: 0.25),

                  ),


                  boxShadow: [

                    BoxShadow(

                      color: Colors.white.withValues(alpha: 0.12),

                      blurRadius: 20,

                    ),

                  ],

                ),



                child: Icon(

                  widget.icon,

                  color: Colors.white,

                  size: 30,

                ),

              ),




              const SizedBox(height: 18),




              Text(

                widget.title,


                maxLines: 1,


                overflow: TextOverflow.ellipsis,



                style: const TextStyle(


                  color: Colors.white,


                  fontSize: 18,


                  fontWeight: FontWeight.w800,


                  letterSpacing: -0.3,


                ),

              ),




              const SizedBox(height: 8),




              Text(

                widget.description,



                maxLines: 2,


                overflow: TextOverflow.ellipsis,



                style: TextStyle(


                  color: Colors.white.withValues(alpha: 0.80),


                  fontSize: 13,


                  height: 1.4,

                ),

              ),



              const SizedBox(height: 14),




              Row(

                children: [


                  Text(

                    "Explore",

                    style: TextStyle(

                      color: Colors.white.withValues(alpha: 0.90),

                      fontSize: 12,

                      fontWeight: FontWeight.w600,

                    ),

                  ),


                  const SizedBox(width: 6),


                  Icon(

                    Icons.arrow_forward_rounded,

                    color: Colors.white.withValues(alpha: 0.90),

                    size: 16,

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }

}