import 'package:flutter/material.dart';

import 'app_colors.dart';



class AppShadows {

  AppShadows._();



  // ============================================================
  // 🌌 ELOQIA AI SHADOW SYSTEM
  // ============================================================


  static const List<BoxShadow> card = [

    BoxShadow(

      color: AppColors.shadow,

      blurRadius: 30,

      offset: Offset(0, 15),

    ),

  ];



  static const List<BoxShadow> glow = [

    BoxShadow(

      color: AppColors.glow,

      blurRadius: 40,

      spreadRadius: 8,

    ),

  ];



  static const List<BoxShadow> purpleGlow = [

    BoxShadow(

      color: AppColors.aura,

      blurRadius: 45,

      spreadRadius: 10,

    ),

  ];

}