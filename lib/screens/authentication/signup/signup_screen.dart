import 'package:couplers/screens/authentication/login/login_screen.dart';
import 'package:couplers/screens/authentication/signup/signup_controller.dart';
import 'package:couplers/screens/authentication/signup/signup_form.dart';
import 'package:couplers/widgets/custom_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final SignupController controller = Get.put(SignupController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20.h,
                children: [
                  _buildLogo(),
                  SizedBox(height: 20.h),
                  SignupForm(
                    context: context,
                    formKey: _formKey,
                    email1Controller: controller.email1Controller,
                    email2Controller: controller.email2Controller,
                    passwordController: controller.passwordController,
                    passwordVisible: controller.passwordVisible,
                    togglePasswordVisibility:
                        controller.togglePasswordVisibility,
                  ),
                  _buildPasswordNote(context),
                  _buildButton(context, controller),
                  _buildLoginText(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          MingCuteIcons.mgc_large_arrow_left_fill,
          color: Theme.of(context).colorScheme.secondary,
        ),
        onPressed: () {
          Get.back();
        },
      ),
      title: Text(
        AppLocalizations.of(context)!.signup_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo_app.png',
      width: 180.w,
      height: 180.h,
    );
  }

  Widget _buildButton(BuildContext context, SignupController controller) {
    return CustomButton(
      title: AppLocalizations.of(context)!.signup_screen_text,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.primary,
      onPressed: () => controller.register(context, _formKey),
    );
  }

  Widget _buildLoginText(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: AppLocalizations.of(context)!.signup_screen_account,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 14.sp,
        ),
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!.signup_screen_login,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.off(
                    () => const LoginScreen(),
                    transition: Transition.fade,
                    duration: const Duration(milliseconds: 500),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordNote(BuildContext context) {
    return SizedBox(
      width: 320.w,
      child: Text(
        AppLocalizations.of(context)!.signup_form_password_tip,
        textAlign: TextAlign.center,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}
