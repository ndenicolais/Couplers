import 'package:couplers/services/auth_service.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();

  Future<void> resetPassword(
      BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      final email = emailController.text.trim();
      if (emailController.text.isNotEmpty) {
        final emailToReset = await _authService.resetPassword(email);
        if (context.mounted) {
          showSuccessToast(
            context,
            '${AppLocalizations.of(context)!.reset_password_toast_success} $emailToReset',
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (context.mounted) {
        if (e is Exception && errorMessage.contains("email_not_found")) {
          errorMessage = AppLocalizations.of(context)!
              .reset_password_toast_error_email_not_found;
        }
      }
      if (context.mounted) {
        if (e is Exception && errorMessage.contains("reset_failed")) {
          errorMessage =
              AppLocalizations.of(context)!.reset_password_toast_error_password;
        }
      }
      if (context.mounted) {
        showErrorToast(context, errorMessage);
      }
    }
  }
}
