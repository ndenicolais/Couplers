import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isOutline;

  const CustomButton({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220.w,
      height: 60.h,
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.r),
          side: isOutline ? BorderSide(color: textColor) : BorderSide.none,
        ),
        color: backgroundColor,
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.josefinSans(
              color: textColor,
              fontSize: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}
