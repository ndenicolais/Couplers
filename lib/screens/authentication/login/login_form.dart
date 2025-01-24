import 'package:couplers/widgets/custom_textfield.dart';
import 'package:couplers/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final BuildContext context;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final RxBool passwordVisible;
  final bool rememberMe;
  final void Function() togglePasswordVisibility;
  final void Function() onLogin;

  const LoginForm({
    super.key,
    required this.context,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordVisible,
    required this.rememberMe,
    required this.togglePasswordVisibility,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          _buildTextField(
            emailController,
            AppLocalizations.of(context)!.login_form_email,
            AppLocalizations.of(context)!.login_form_email_field,
            MingCuteIcons.mgc_mail_fill,
            TextInputType.emailAddress,
            TextInputAction.next,
          ),
          SizedBox(height: 20.h),
          _buildPasswordField(
            passwordController,
            AppLocalizations.of(context)!.login_form_password,
            AppLocalizations.of(context)!.login_form_password_field,
            MingCuteIcons.mgc_lock_fill,
            TextInputType.text,
            TextInputAction.done,
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
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
        validator: (val) => val?.emailValidationError(context),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    String hint,
    IconData prefixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
          obscureText: !passwordVisible.value,
          validator: (val) => val?.passwordValidationError(context),
        ),
      ),
    );
  }
}
