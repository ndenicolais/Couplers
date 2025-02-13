import 'package:couplers/models/user_model.dart';
import 'package:couplers/screens/user/user_adder_screen.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:couplers/models/couple_model.dart';
import 'package:couplers/services/auth_service.dart';

class SignupController extends GetxController {
  final AuthService _authService = AuthService();
  final email1Controller = TextEditingController();
  final email2Controller = TextEditingController();
  final passwordController = TextEditingController();
  var passwordVisible = false.obs;

  void togglePasswordVisibility() {
    passwordVisible.value = !passwordVisible.value;
  }

  Future<void> register(
      BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      if (email1Controller.text.isNotEmpty &&
          email2Controller.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        UserModel user1 = UserModel(email: email1Controller.text);
        UserModel user2 = UserModel(email: email2Controller.text);
        CoupleModel couple = CoupleModel(
          user1: user1,
          user2: user2,
        );

        User? registeredUser = await _authService.signup(
          couple,
          passwordController.text,
        );

        if (registeredUser != null) {
          if (context.mounted) {
            showSuccessToast(
              context,
              AppLocalizations.of(context)!.signup_toast_success,
            );
          }
          Get.to(
            () => UserAdderScreen(userId: registeredUser.uid),
            transition: Transition.rightToLeft,
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (context.mounted) {
        if (e is Exception &&
            errorMessage.contains("personal_email_already_register")) {
          errorMessage = AppLocalizations.of(context)!
              .signup_toast_error_personal_email_already_register;
        }
      }
      if (context.mounted) {
        if (e is Exception &&
            errorMessage.contains("personal_email_register_as_partner_email")) {
          errorMessage = AppLocalizations.of(context)!
              .signup_toast_error_personal_email_exist_as_partner;
        }
      }
      if (context.mounted) {
        if (e is Exception &&
            errorMessage.contains("partner_email_already_register")) {
          errorMessage = AppLocalizations.of(context)!
              .signup_toast_error_partner_email_already_register;
        }
      }
      if (context.mounted) {
        if (e is Exception &&
            errorMessage.contains("partner_email_register_as_personal_email")) {
          errorMessage = AppLocalizations.of(context)!
              .signup_toast_error_partner_email_exist_as_personal;
        }
      }

      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }
    }
  }
}
