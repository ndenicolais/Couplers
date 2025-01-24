import 'package:couplers/screens/home_screen.dart';
import 'package:couplers/screens/welcome_screen.dart';
import 'package:couplers/services/auth_service.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var passwordVisible = false.obs;
  var rememberMe = false.obs;

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  Future<void> login(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      User? user = await _authService.login(
        emailController.text,
        passwordController.text,
        rememberMe.value,
      );

      if (user != null) {
        if (context.mounted) {
          showSuccessToast(
            context,
            AppLocalizations.of(context)!.login_toast_success,
          );
        }
        Get.to(() => const HomepageScreen(), transition: Transition.fade);
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (context.mounted) {
        if (e is Exception && errorMessage.contains("email_not_found")) {
          errorMessage =
              AppLocalizations.of(context)!.login_toast_error_email_not_found;
        }
      }
      if (context.mounted) {
        if (e is Exception && errorMessage.contains("invalid_password")) {
          errorMessage =
              AppLocalizations.of(context)!.login_toast_error_invalid_password;
        }
      }
      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authService.logout();
      emailController.clear();
      passwordController.clear();
      rememberMe.value = false;

      if (context.mounted) {
        showSuccessToast(context, "A presto!");
      }

      Get.offAll(() => const WelcomeScreen(),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500));
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, "Errore durante il logout");
      }
    }
  }
}
