import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension ExtString on String {
  String? emailValidationError(BuildContext context) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
    String message = '';

    if (!emailRegExp.hasMatch(this)) {
      if (!contains('@')) {
        message +=
            '${AppLocalizations.of(context)?.validator_email_missing_special}';
      }

      if (!contains('.')) {
        message +=
            '\n${AppLocalizations.of(context)?.validator_email_missing_dot}';
      }
    }

    return message.isNotEmpty ? message : null;
  }

  bool isValidEmail(BuildContext context) {
    return emailValidationError(context) == null;
  }

  String? passwordValidationError(BuildContext context) {
    final passwordRegExp = RegExp(
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[+!@#\><*~]).{8,}$');
    String message = '';

    if (!passwordRegExp.hasMatch(this)) {
      if (!RegExp(r'[A-Z]').hasMatch(this)) {
        message +=
            '${AppLocalizations.of(context)?.validator_password_missing_upper}';
      }

      if (!RegExp(r'[a-z]').hasMatch(this)) {
        message +=
            '\n${AppLocalizations.of(context)?.validator_password_missing_lower}';
      }

      if (!RegExp(r'\d').hasMatch(this)) {
        message +=
            '\n${AppLocalizations.of(context)?.validator_password_missing_digit}';
      }

      if (!RegExp(r'[+!@#\><*~]').hasMatch(this)) {
        message +=
            '\n${AppLocalizations.of(context)?.validator_password_missing_special}';
      }

      if (length < 8) {
        message +=
            '\n${AppLocalizations.of(context)?.validator_password_missing_lenght}';
      }
    }

    return message.isNotEmpty ? message : null;
  }

  bool isValidPassword(BuildContext context) {
    return passwordValidationError(context) == null;
  }
}
