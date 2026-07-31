import 'package:flutter/material.dart';

import 'app_colors.dart';



class AppTheme {

  AppTheme._();



  static ThemeData get darkTheme {


    return ThemeData(

      useMaterial3: true,


      brightness: Brightness.dark,


      scaffoldBackgroundColor:
          AppColors.background,



      colorScheme: const ColorScheme.dark(

        primary:
            AppColors.primary,

        secondary:
            AppColors.secondary,

        surface:
            AppColors.surface,

        error:
            AppColors.error,

      ),




      // ============================================================
      // ✨ TYPOGRAPHY
      // ============================================================


      textTheme: const TextTheme(


        displayLarge: TextStyle(

          color:
              AppColors.textPrimary,

          fontSize:
              42,

          fontWeight:
              FontWeight.w900,

          letterSpacing:
              -1.5,

        ),



        headlineLarge: TextStyle(

          color:
              AppColors.textPrimary,

          fontSize:
              28,

          fontWeight:
              FontWeight.w800,

        ),



        headlineMedium: TextStyle(

          color:
              AppColors.textPrimary,

          fontSize:
              22,

          fontWeight:
              FontWeight.w700,

        ),



        bodyLarge: TextStyle(

          color:
              AppColors.textPrimary,

          fontSize:
              16,

          height:
              1.5,

        ),



        bodyMedium: TextStyle(

          color:
              AppColors.textSecondary,

          fontSize:
              14,

          height:
              1.5,

        ),


      ),






      // ============================================================
      // 📱 APP BAR
      // ============================================================


      appBarTheme: const AppBarTheme(

        backgroundColor:
            AppColors.background,


        elevation:
            0,


        centerTitle:
            true,


        iconTheme: IconThemeData(

          color:
              AppColors.textPrimary,

        ),



        titleTextStyle: TextStyle(

          color:
              AppColors.textPrimary,


          fontSize:
              20,


          fontWeight:
              FontWeight.bold,

        ),

      ),






      // ============================================================
      // 🔘 BUTTONS
      // ============================================================


      elevatedButtonTheme:
          ElevatedButtonThemeData(

        style:
            ElevatedButton.styleFrom(


          backgroundColor:
              AppColors.primary,


          foregroundColor:
              AppColors.background,



          elevation:
              8,



          padding:
              const EdgeInsets.symmetric(

            horizontal:
                28,

            vertical:
                16,

          ),



          shape:
              RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(22),

          ),


        ),

      ),







      // ============================================================
      // 🪟 CARDS LIQUID GLASS
      // ============================================================


      cardTheme:
          CardThemeData(


        color:
            AppColors.surface,


        elevation:
            12,


        margin:
            EdgeInsets.zero,


        shape:
            RoundedRectangleBorder(


          borderRadius:
              BorderRadius.circular(28),


          side:
              const BorderSide(

            color:
                AppColors.glassBorder,

          ),

        ),


      ),







      // ============================================================
      // 📝 TEXT FIELDS
      // ============================================================


      inputDecorationTheme:
          InputDecorationTheme(


        filled:
            true,


        fillColor:
            AppColors.surface,



        hintStyle:
            const TextStyle(

          color:
              AppColors.textMuted,

        ),




        border:
            OutlineInputBorder(


          borderRadius:
              BorderRadius.circular(22),


          borderSide:
              BorderSide.none,


        ),




        enabledBorder:
            OutlineInputBorder(


          borderRadius:
              BorderRadius.circular(22),


          borderSide:
              const BorderSide(

            color:
                AppColors.glassBorder,

          ),


        ),





        focusedBorder:
            OutlineInputBorder(


          borderRadius:
              BorderRadius.circular(22),


          borderSide:
              const BorderSide(

            color:
                AppColors.primary,

            width:
                2,

          ),


        ),


      ),







      // ============================================================
      // 📊 PROGRESS BAR
      // ============================================================


      progressIndicatorTheme:
          const ProgressIndicatorThemeData(


        color:
            AppColors.primary,


        linearTrackColor:
            AppColors.surface,


      ),




      // ============================================================
      // 🔄 DIVIDERS
      // ============================================================


      dividerTheme:
          const DividerThemeData(


        color:
            AppColors.glassBorder,


        thickness:
            1,

      ),



    );

  }


}