import 'package:flutter/material.dart';


class EloqiaBottomNavBar extends StatelessWidget {

  final int currentIndex;
  final ValueChanged<int> onTap;


  const EloqiaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });



  static const List<_NavigationItem> items = [

    _NavigationItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),

    _NavigationItem(
      icon: Icons.graphic_eq_rounded,
      label: 'Talk',
    ),

    _NavigationItem(
      icon: Icons.auto_stories_rounded,
      label: 'Learn',
    ),

    _NavigationItem(
      icon: Icons.insights_rounded,
      label: 'Progress',
    ),

    _NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),

  ];



  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: 20,
      ),


      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),


      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(38),


        gradient: LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [

            Colors.white.withValues(alpha: 0.16),

            Colors.white.withValues(alpha: 0.05),

          ],

        ),


        border: Border.all(

          color: Colors.white.withValues(alpha: 0.20),

          width: 1.2,

        ),


        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.45),

            blurRadius: 40,

            offset: const Offset(0, 20),

          ),


          BoxShadow(

            color: Colors.blueAccent.withValues(alpha: 0.10),

            blurRadius: 60,

          ),

        ],

      ),



      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceAround,


        children: List.generate(

          items.length,

          (index) {

            return _NavigationButton(

              item: items[index],

              selected: currentIndex == index,

              onTap: () => onTap(index),

            );

          },

        ),

      ),

    );

  }

}





class _NavigationButton extends StatelessWidget {


  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;



  const _NavigationButton({

    required this.item,

    required this.selected,

    required this.onTap,

  });



  @override
  Widget build(BuildContext context) {


    return GestureDetector(

      onTap: onTap,


      child: AnimatedContainer(

        duration: const Duration(milliseconds: 350),


        curve: Curves.easeOut,


        padding: const EdgeInsets.symmetric(

          horizontal: 14,

          vertical: 8,

        ),



        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(26),


          gradient: selected

              ? LinearGradient(

                  colors: [

                    Colors.blueAccent.withValues(alpha: 0.35),

                    Colors.purpleAccent.withValues(alpha: 0.25),

                  ],

                )

              : null,



          boxShadow: selected

              ? [

                  BoxShadow(

                    color: Colors.blueAccent.withValues(alpha: 0.35),

                    blurRadius: 25,

                  ),

                ]

              : null,

        ),



        child: Column(

          mainAxisSize: MainAxisSize.min,


          children: [


            AnimatedScale(

              scale: selected ? 1.15 : 1,

              duration: const Duration(milliseconds: 300),


              child: Icon(

                item.icon,

                size: 25,


                color: selected

                    ? Colors.white

                    : Colors.white.withValues(alpha: 0.45),

              ),

            ),



            const SizedBox(height: 5),



            AnimatedDefaultTextStyle(

              duration: const Duration(milliseconds: 300),


              style: TextStyle(

                fontSize: 11,

                fontWeight: selected

                    ? FontWeight.bold

                    : FontWeight.normal,


                color: selected

                    ? Colors.white

                    : Colors.white.withValues(alpha: 0.45),

              ),


              child: Text(item.label),

            ),

          ],

        ),

      ),

    );

  }

}





class _NavigationItem {


  final IconData icon;

  final String label;



  const _NavigationItem({

    required this.icon,

    required this.label,

  });

}