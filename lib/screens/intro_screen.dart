import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/onboarding/onboarding_screen.dart';
import 'package:couplers/screens/home_screen.dart';
import 'package:couplers/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  IntroScreenState createState() => IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(context),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startSplashScreen();
  }

  Future<void> _startSplashScreen() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _checkRememberMe();
  }

  Future<void> _loadUserData(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('couple').doc(userId).get();
      if (userDoc.exists) {
        // Load user data into local memory or app template
      } else {
        throw Exception("User data not found");
      }
    } catch (e) {
      _logger.e("Failed to load user data: $e");
      rethrow;
    }
  }

  Future<void> _checkRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    bool rememberMe = prefs.getBool('remember_me') ?? false;

    if (!onboardingCompleted) {
      Get.to(
        () => const OnboardingScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    } else {
      if (rememberMe) {
        String? userId = prefs.getString('user_id');
        if (userId != null) {
          try {
            await _loadUserData(userId);
            Get.to(
              () => const HomeScreen(),
              transition: Transition.fade,
              duration: const Duration(milliseconds: 500),
            );
          } catch (e) {
            Get.to(
              () => const WelcomeScreen(),
              transition: Transition.fade,
              duration: const Duration(milliseconds: 500),
            );
          }
        } else {
          Get.to(
            () => const WelcomeScreen(),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 500),
          );
        }
      } else {
        Get.to(
          () => const WelcomeScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo_app.png',
          width: 280.w,
          height: 280.h,
        ),
        Text(
          AppLocalizations.of(context)!.intro_title,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 60.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
