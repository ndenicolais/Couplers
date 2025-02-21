import 'package:couplers/utils/constants.dart';
import 'package:couplers/widgets/custom_expansiontile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20.h,
              children: [
                _buildContactSection(
                  context,
                  title: AppLocalizations.of(context)!
                      .support_screen_contacts_text,
                  description: AppLocalizations.of(context)!
                      .support_screen_contacts_decription,
                  contactInfo: AppLocalizations.of(context)!
                      .support_screen_contacts_info,
                  icon: MingCuteIcons.mgc_mail_send_line,
                  onTap: () => _launchEmail(),
                ),
                Divider(color: Theme.of(context).colorScheme.tertiaryFixed),
                _buildFaqSection(context),
                Divider(color: Theme.of(context).colorScheme.tertiaryFixed),
                _buildContactSection(
                  context,
                  title: AppLocalizations.of(context)!
                      .support_screen_documentation_text,
                  description: AppLocalizations.of(context)!
                      .support_screen_documentation_decription,
                  contactInfo: AppLocalizations.of(context)!
                      .support_screen_documentation_info,
                  icon: MingCuteIcons.mgc_book_6_line,
                  onTap: () => _launchDocumentation(),
                ),
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
        AppLocalizations.of(context)!.support_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildContactSection(
    BuildContext context, {
    required String title,
    required String description,
    required String contactInfo,
    required IconData icon,
    required Function onTap,
  }) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 30.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            contactInfo,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              MingCuteIcons.mgc_question_line,
              color: Theme.of(context).colorScheme.secondary,
              size: 30.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              AppLocalizations.of(context)!.support_screen_faq_text,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          AppLocalizations.of(context)!.support_screen_faq_decription,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 10.h),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q1,
          answer: AppLocalizations.of(context)!.support_screen_faq_a1,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q2,
          answer: AppLocalizations.of(context)!.support_screen_faq_a2,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q3,
          answer: AppLocalizations.of(context)!.support_screen_faq_a3,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q4,
          answer: AppLocalizations.of(context)!.support_screen_faq_a4,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q5,
          answer: AppLocalizations.of(context)!.support_screen_faq_a5,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q7,
          answer: AppLocalizations.of(context)!.support_screen_faq_a7,
        ),
        CustomExpansionTile(
          title: AppLocalizations.of(context)!.support_screen_faq_q9,
          answer: AppLocalizations.of(context)!.support_screen_faq_a9,
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    if (await launchUrlString(AppConstants.uriMail.toString())) {
      return;
    } else {
      throw 'Impossible to open email client';
    }
  }

  Future<void> _launchDocumentation() async {
    if (await launchUrlString(AppConstants.uriGithubDocumentation.toString())) {
      return;
    } else {
      throw 'Impossible to open documentation.';
    }
  }
}
