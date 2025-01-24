import 'package:couplers/screens/authentication/login/login_controller.dart';
import 'package:couplers/screens/settings/account_screen.dart';
import 'package:couplers/screens/settings/delete_account_screen.dart';
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
                _buildSwitchSetting(
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
                _buildSettingOption(
                  context,
                  icon: MingCuteIcons.mgc_translate_2_line,
                  title: AppLocalizations.of(context)!
                      .settings_screen_language_text,
                  onTap: () {
                    _showLanguageDialog(context);
                  },
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
                  icon: MingCuteIcons.mgc_user_info_line,
                  title: 'Account',
                  onTap: () {
                    Get.to(
                      () => const AccountInfoPage(),
                      transition: Transition.leftToRight,
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
                      transition: Transition.leftToRight,
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.settings_screen_language_dialog_title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    checkColor: Theme.of(context).colorScheme.primary,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    value: Get.locale?.languageCode == 'en',
                    onChanged: (value) {
                      if (value != null && value) {
                        _saveLanguagePreference('en');

                        Get.updateLocale(const Locale('en'));
                        Get.back();
                      }
                    },
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .settings_screen_language_dialog_english,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    checkColor: Theme.of(context).colorScheme.primary,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    value: Get.locale?.languageCode == 'it',
                    onChanged: (value) {
                      if (value != null && value) {
                        _saveLanguagePreference('it');
                        Get.updateLocale(const Locale('it'));
                        Get.back();
                      }
                    },
                  ),
                  Text(
                    AppLocalizations.of(context)!
                        .settings_screen_language_dialog_italian,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      required Function() onTap}) {
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

  Widget _buildSwitchSetting(BuildContext context,
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
}
