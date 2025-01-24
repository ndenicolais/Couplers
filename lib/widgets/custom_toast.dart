import 'package:couplers/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:toastification/toastification.dart';

// Function to show custom toast
void showCustomToast({
  required BuildContext context,
  required String title,
  Color? titleColor,
  ToastificationType? type,
  Color? primaryColor,
  Color? backgroundColor,
  required IconData icon,
  Color? iconColor,
  Duration autoCloseDuration = const Duration(seconds: 3),
}) {
  toastification.show(
    context: context,
    type: type,
    style: ToastificationStyle.flatColored,
    title: Text(
      title,
      style: GoogleFonts.josefinSans(color: titleColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
    alignment: Alignment.bottomCenter,
    autoCloseDuration: autoCloseDuration,
    primaryColor: primaryColor,
    backgroundColor: backgroundColor,
    icon: Icon(icon, color: iconColor),
    borderRadius: BorderRadius.circular(100.r),
    showProgressBar: false,
  );
}

// Function to show success custom toast
void showSuccessToast(BuildContext context, String title) {
  showCustomToast(
    context: context,
    title: title,
    titleColor: AppColors.toastLightGreen,
    type: ToastificationType.success,
    icon: MingCuteIcons.mgc_check_fill,
    iconColor: AppColors.toastLightGreen,
    primaryColor: AppColors.toastDarkGreen,
    backgroundColor: AppColors.toastDarkGreen,
  );
}

// Function to show error custom toast
void showErrorToast(BuildContext context, String title) {
  showCustomToast(
    context: context,
    title: title,
    titleColor: AppColors.toastLightRed,
    type: ToastificationType.error,
    icon: MingCuteIcons.mgc_warning_line,
    iconColor: AppColors.toastLightRed,
    primaryColor: AppColors.toastDarkRed,
    backgroundColor: AppColors.toastDarkRed,
  );
}
