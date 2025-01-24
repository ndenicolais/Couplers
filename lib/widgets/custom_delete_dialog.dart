import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onCancelPressed;
  final VoidCallback onConfirmPressed;

  const DeleteDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onCancelPressed,
    required this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      title: Text(
        title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18.sp,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancelPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).colorScheme.tertiaryFixed,
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.custom_delete_dialog_cancel,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14.sp,
            ),
          ),
        ),
        TextButton(
          onPressed: onConfirmPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.custom_delete_dialog_confirm,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }
}
