import 'package:couplers/screens/authentication/reset_password/reset_password_controller.dart';
import 'package:couplers/screens/authentication/reset_password/reset_password_form.dart';
import 'package:couplers/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ResetPasswordController controller = Get.put(ResetPasswordController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTopImage(),
                  SizedBox(height: 50.h),
                  _buildTextDescription(),
                  SizedBox(height: 50.h),
                  ResetPasswordForm(
                      context: context,
                      formKey: _formKey,
                      emailController: controller.emailController),
                  SizedBox(height: 20.h),
                  _buildResetButton(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
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
        AppLocalizations.of(context)!.reset_password_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildTopImage() {
    return Image.asset(
      'assets/images/logo_app.png',
      width: 180.w,
      height: 180.h,
    );
  }

  Widget _buildTextDescription() {
    return SizedBox(
      width: 320.w,
      child: Text(
        AppLocalizations.of(context)!.reset_password_screen_description,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 24.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResetButton(ResetPasswordController controller) {
    return CustomButton(
      title: AppLocalizations.of(context)!.reset_password_screen_text,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.primary,
      onPressed: () => controller.resetPassword(context, _formKey),
    );
  }
}
