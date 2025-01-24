import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:couplers/utils/validator.dart';
import 'package:couplers/widgets/custom_textfield.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final BuildContext context;
  final TextEditingController email1Controller;
  final TextEditingController email2Controller;
  final TextEditingController passwordController;
  final RxBool passwordVisible;
  final VoidCallback togglePasswordVisibility;

  const SignupForm({
    super.key,
    required this.context,
    required this.formKey,
    required this.email1Controller,
    required this.email2Controller,
    required this.passwordController,
    required this.passwordVisible,
    required this.togglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _buildTextField(
            email1Controller,
            AppLocalizations.of(context)!.signup_form_private_email,
            AppLocalizations.of(context)!.signup_form_private_email_field,
            MingCuteIcons.mgc_mail_fill,
            TextInputType.emailAddress,
            TextCapitalization.none,
            TextInputAction.next,
            (val) => val?.emailValidationError(context),
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            email2Controller,
            AppLocalizations.of(context)!.signup_form_partner_email,
            AppLocalizations.of(context)!.signup_form_partner_email_field,
            MingCuteIcons.mgc_mail_fill,
            TextInputType.emailAddress,
            TextCapitalization.none,
            TextInputAction.next,
            (val) => val?.emailValidationError(context),
          ),
          SizedBox(height: 20.h),
          _buildPasswordField(
            passwordController,
            AppLocalizations.of(context)!.signup_form_password,
            AppLocalizations.of(context)!.signup_form_password_field,
            MingCuteIcons.mgc_lock_fill,
            TextInputType.text,
            TextCapitalization.none,
            TextInputAction.done,
            (val) => val?.passwordValidationError(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData prefixIcon,
    TextInputType keyboardType,
    TextCapitalization textCapitalization,
    TextInputAction textInputAction,
    String? Function(String?) validator,
  ) {
    return SizedBox(
      width: 320.w,
      child: CustomTextField(
        controller: controller,
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    String hint,
    IconData prefixIcon,
    TextInputType keyboardType,
    TextCapitalization textCapitalization,
    TextInputAction textInputAction,
    String? Function(String?) validator,
  ) {
    return SizedBox(
      width: 320.w,
      child: Obx(
        () => CustomTextField(
          controller: controller,
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: Obx(
            () => IconButton(
              icon: Icon(
                passwordVisible.value
                    ? MingCuteIcons.mgc_eye_fill
                    : MingCuteIcons.mgc_eye_close_fill,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: togglePasswordVisibility,
            ),
          ),
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: !passwordVisible.value,
          validator: validator,
        ),
      ),
    );
  }
}
