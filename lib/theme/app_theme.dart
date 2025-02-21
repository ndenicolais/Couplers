import 'package:couplers/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.lightLinen,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return ThemeData(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.lightLinen,
        onPrimary: AppColors.lightLinen,
        secondary: AppColors.lightBrick,
        onSecondary: AppColors.lightLinen,
        tertiary: AppColors.charcoal,
        onTertiary: AppColors.lightBrick,
        tertiaryFixed: AppColors.sunset,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(AppColors.lightLinen),
        checkColor: WidgetStateProperty.all(AppColors.lightBrick),
        side: const BorderSide(
          color: AppColors.sunset,
          width: 1,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkGold,
        surfaceTintColor: AppColors.sunset,
        headerBackgroundColor: AppColors.lightLinen,
        headerForegroundColor: AppColors.darkBrick,
        weekdayStyle: GoogleFonts.josefinSans(
          color: AppColors.lightLinen,
        ),
        dayForegroundColor: WidgetStateProperty.all(AppColors.charcoal),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.charcoal),
        todayForegroundColor: WidgetStateProperty.all(AppColors.lightLinen),
        yearForegroundColor: WidgetStateProperty.all(AppColors.darkBrick),
        dividerColor: AppColors.charcoal,
        cancelButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.darkBrick),
          foregroundColor: WidgetStateProperty.all(AppColors.sunset),
          elevation: WidgetStateProperty.all(5),
        ),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.lightLinen),
          foregroundColor: WidgetStateProperty.all(AppColors.darkBrick),
          elevation: WidgetStateProperty.all(5),
        ),
      ),
      dividerColor: AppColors.charcoal,
      dividerTheme: const DividerThemeData(color: AppColors.charcoal),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.josefinSans(
          color: AppColors.lightBrick,
        ),
        hintStyle: GoogleFonts.josefinSans(
          color: AppColors.charcoal,
        ),
        errorStyle: GoogleFonts.josefinSans(
          color: AppColors.lightBrick,
          fontWeight: FontWeight.bold,
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.lightBrick,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.charcoal,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.charcoal,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.lightBrick,
          foregroundColor: AppColors.lightLinen,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: AppColors.sunset,
        selectionHandleColor: AppColors.lightBrick,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.josefinSans(),
        displayMedium: GoogleFonts.josefinSans(),
        displaySmall: GoogleFonts.josefinSans(),
        headlineLarge: GoogleFonts.josefinSans(),
        headlineMedium: GoogleFonts.josefinSans(),
        headlineSmall: GoogleFonts.josefinSans(),
        titleLarge: GoogleFonts.josefinSans(),
        titleMedium: GoogleFonts.josefinSans(),
        titleSmall: GoogleFonts.josefinSans(),
        bodyLarge: GoogleFonts.josefinSans(color: AppColors.lightBrick),
        bodyMedium: GoogleFonts.josefinSans(),
        bodySmall: GoogleFonts.josefinSans(),
        labelLarge: GoogleFonts.josefinSans(),
        labelMedium: GoogleFonts.josefinSans(),
        labelSmall: GoogleFonts.josefinSans(),
      ),
    );
  }

  static ThemeData darkTheme() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: AppColors.darkBrick,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.darkBrick,
        onPrimary: AppColors.darkBrick,
        secondary: AppColors.sunset,
        onSecondary: AppColors.darkBrick,
        tertiary: AppColors.lightLinen,
        onTertiary: AppColors.sunset,
        tertiaryFixed: AppColors.darkGold,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(AppColors.darkBrick),
        checkColor: WidgetStateProperty.all(AppColors.lightLinen),
        side: const BorderSide(
          color: AppColors.sunset,
          width: 1,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkGold,
        surfaceTintColor: AppColors.darkBrick,
        headerBackgroundColor: AppColors.darkBrick,
        headerForegroundColor: AppColors.lightLinen,
        weekdayStyle: GoogleFonts.josefinSans(
          color: AppColors.darkBrick,
        ),
        dayForegroundColor: WidgetStateProperty.all(AppColors.lightLinen),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.lightLinen),
        todayForegroundColor: WidgetStateProperty.all(AppColors.darkBrick),
        yearForegroundColor: WidgetStateProperty.all(AppColors.lightLinen),
        dividerColor: AppColors.darkGold,
        cancelButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.darkBrick),
          foregroundColor: WidgetStateProperty.all(AppColors.lightLinen),
        ),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.lightLinen),
          foregroundColor: WidgetStateProperty.all(AppColors.darkBrick),
        ),
      ),
      dividerColor: AppColors.darkGold,
      dividerTheme: const DividerThemeData(color: AppColors.darkGold),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.josefinSans(
          color: AppColors.lightLinen,
        ),
        hintStyle: GoogleFonts.josefinSans(
          color: AppColors.sunset,
        ),
        errorStyle: GoogleFonts.josefinSans(
          color: AppColors.lightBrick,
          fontWeight: FontWeight.bold,
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.lightBrick,
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.lightLinen,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.lightLinen,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.sunset,
          foregroundColor: AppColors.darkBrick,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: AppColors.lightLinen,
        selectionHandleColor: AppColors.lightLinen,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.josefinSans(),
        displayMedium: GoogleFonts.josefinSans(),
        displaySmall: GoogleFonts.josefinSans(),
        headlineLarge: GoogleFonts.josefinSans(),
        headlineMedium: GoogleFonts.josefinSans(),
        headlineSmall: GoogleFonts.josefinSans(),
        titleLarge: GoogleFonts.josefinSans(),
        titleMedium: GoogleFonts.josefinSans(),
        titleSmall: GoogleFonts.josefinSans(),
        bodyLarge: GoogleFonts.josefinSans(color: AppColors.darkGold),
        bodyMedium: GoogleFonts.josefinSans(),
        bodySmall: GoogleFonts.josefinSans(),
        labelLarge: GoogleFonts.josefinSans(),
        labelMedium: GoogleFonts.josefinSans(),
        labelSmall: GoogleFonts.josefinSans(),
      ),
    );
  }
}
