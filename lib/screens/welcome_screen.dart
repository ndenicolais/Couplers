import 'package:couplers/screens/authentication/login/login_screen.dart';
import 'package:couplers/screens/authentication/signup/signup_screen.dart';
import 'package:couplers/widgets/custom_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(30.r),
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  _buildTitle(context),
                  const Spacer(flex: 2),
                  _buildLogo(context),
                  const Spacer(flex: 2),
                  _buildLoginButton(context),
                  SizedBox(height: 20.h),
                  _buildSignupButton(context),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.welcome_text,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 60.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Image.asset(
      'assets/images/logo_app.png',
      width: 280.w,
      height: 280.h,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return CustomButton(
      title: AppLocalizations.of(context)!.welcome_login,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.primary,
      isOutline: false,
      onPressed: () {
        Get.to(
          () => const LoginScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500),
        );
      },
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return CustomButton(
      title: AppLocalizations.of(context)!.welcome_signup,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.secondary,
      isOutline: true,
      onPressed: () {
        Get.to(
          () => const SignupScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500),
        );
      },
    );
  }
}
