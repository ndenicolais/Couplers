import 'package:couplers/screens/settings/info_screen.dart';
import 'package:couplers/screens/settings/policy_screen.dart';
import 'package:couplers/screens/settings/settings_screen.dart';
import 'package:couplers/screens/settings/support_screen.dart';
import 'package:couplers/screens/user/user_screen.dart';
import 'package:couplers/services/auth_service.dart';
import 'package:couplers/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:share_plus/share_plus.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.primary,
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                DrawerHeader(
                  child: Image.asset(
                    'assets/images/logo_app.png',
                    width: 150.w,
                    height: 150.h,
                  ),
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_user_heart_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_us,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    final userId = authService.currentUser?.uid ?? '';
                    Get.to(
                      () => UserScreen(userId: userId),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_settings_5_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_settings,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    Get.to(
                      () => const SettingsScreen(),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_information_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_info,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    Get.to(
                      () => const InfoScreen(),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_file_certificate_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_policy,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    Get.to(
                      () => PolicyScreen(),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_group_3_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_support,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    Get.to(
                      () => const SupportScreen(),
                      transition: Transition.leftToRight,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(MingCuteIcons.mgc_share_2_line,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(
                    AppLocalizations.of(context)!.drawer_share,
                    style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onTap: () {
                    Share.share(AppConstants.uriGithubLink.toString());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
