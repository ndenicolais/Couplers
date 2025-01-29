import 'package:couplers/screens/authentication/login/login_controller.dart';
import 'package:couplers/screens/settings/database_screen.dart';
import 'package:couplers/screens/settings/delete_account_screen.dart';
import 'package:couplers/screens/user/users_details_screen.dart';
import 'package:couplers/services/auth_service.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.settings_screen_general_title,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildThemeSwitch(
                  context,
                  icon: MingCuteIcons.mgc_moon_line,
                  title:
                      AppLocalizations.of(context)!.settings_screen_theme_text,
                  value: Provider.of<ThemeNotifier>(context).isDarkMode,
                  onChanged: (bool newValue) {
                    Provider.of<ThemeNotifier>(context, listen: false)
                        .switchTheme();
                  },
                ),
                _buildLanguageSwitch(
                  context,
                  icon: MingCuteIcons.mgc_world_2_line,
                  title: AppLocalizations.of(context)!
                      .settings_screen_language_text,
                  currentValue: Get.locale?.languageCode ?? 'en',
                  onChanged: (String newValue) {
                    _saveLanguagePreference(newValue);
                    Get.updateLocale(Locale(newValue));
                  },
                  options: ['en', 'it'],
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context)!.settings_screen_account_title,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildSettingOption(
                  context,
                  icon: MingCuteIcons.mgc_user_heart_line,
                  title:
                      AppLocalizations.of(context)!.settings_screen_users_title,
                  onTap: () {
                    final userId = authService.currentUser?.uid ?? '';
                    Get.to(
                      () => UsersDetailsScreen(userId: userId),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                _buildSettingOption(
                  context,
                  icon: MingCuteIcons.mgc_coin_2_line,
                  title: AppLocalizations.of(context)!
                      .settings_screen_database_title,
                  onTap: () {
                    Get.to(
                      () => const DatabasePage(),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
                _buildSettingOption(
                  context,
                  icon: MingCuteIcons.mgc_exit_line,
                  title:
                      AppLocalizations.of(context)!.settings_screen_logout_text,
                  onTap: () {
                    controller.logout(context);
                  },
                ),
                _buildSettingOption(
                  context,
                  icon: MingCuteIcons.mgc_delete_2_line,
                  title:
                      AppLocalizations.of(context)!.settings_screen_delete_text,
                  onTap: () {
                    Get.to(
                      () => const DeleteAccountScreen(),
                      transition: Transition.rightToLeft,
                      duration: const Duration(milliseconds: 500),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference().then((languageCode) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<String> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code') ?? '';
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    setState(() {});
    Get.updateLocale(Locale(languageCode));
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
        AppLocalizations.of(context)!.settings_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildSettingOption(BuildContext context,
      {required IconData icon,
      required String title,
      required Function() onTap,
      String? selectedOption}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 25.sp,
              color: Theme.of(context).colorScheme.secondary,
            ),
            SizedBox(width: 15.w),
            Text(
              title,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 16.sp,
              ),
            ),
            const Spacer(),
            if (selectedOption != null)
              Text(
                selectedOption,
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 16.sp,
                ),
              ),
            SizedBox(width: 15.w),
            Icon(
              MingCuteIcons.mgc_right_fill,
              size: 18.sp,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context,
      {required IconData icon,
      required String title,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return SizedBox(
      child: Row(
        children: [
          Icon(
            icon,
            size: 25.sp,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 15.w),
          Text(
            title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 16.sp,
            ),
          ),
          const Spacer(),
          Text(
            value
                ? AppLocalizations.of(context)!.settings_screen_theme_on_text
                : AppLocalizations.of(context)!.settings_screen_theme_off_text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.tertiary,
            inactiveThumbColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Theme.of(context).colorScheme.tertiaryFixed,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitch(BuildContext context,
      {required IconData icon,
      required String title,
      required String currentValue,
      required ValueChanged<String> onChanged,
      required List<String> options}) {
    return SizedBox(
      child: Row(
        children: [
          Icon(
            icon,
            size: 25.sp,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 15.w),
          Text(
            title,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 16.sp,
            ),
          ),
          const Spacer(),
          Text(
            currentValue == 'en'
                ? AppLocalizations.of(context)!
                    .settings_screen_language_english_text
                : AppLocalizations.of(context)!
                    .settings_screen_language_italian_text,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(width: 15.w),
          Switch(
            value: currentValue == 'it',
            onChanged: (bool value) {
              onChanged(value ? 'it' : 'en');
            },
            activeColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.tertiary,
            inactiveThumbColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Theme.of(context).colorScheme.tertiaryFixed,
          ),
        ],
      ),
    );
  }
}
