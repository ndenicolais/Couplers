import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.r),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(context),
                SizedBox(height: 20.h),
                _buildAppName(context),
                SizedBox(height: 20.h),
                _buildDescription(context),
                SizedBox(height: 20.h),
                _buildCredits(context),
                SizedBox(height: 20.h),
                _buildVersion(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
        AppLocalizations.of(context)!.info_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo_app.png',
        width: 180.w,
        height: 180.h,
      ),
    );
  }

  Widget _buildAppName(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.info_screen_origin_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          AppLocalizations.of(context)!.info_screen_origin_description,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.info_screen_description_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          AppLocalizations.of(context)!.info_screen_description_description,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildCredits(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.info_screen_credits_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_a_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_a_value,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_b_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_b_value,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_c_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_c_value,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_d_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_credits_d_value,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildVersion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.info_screen_version_text,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.info_screen_version_value,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
