import 'dart:convert';
import 'package:couplers/l10n/l10n.dart';
import 'package:couplers/screens/intro_screen.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>> loadConfig() async {
  final configString = await rootBundle.loadString('config.json');
  return json.decode(configString);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await loadConfig();

  await Supabase.initialize(
    url: config['supabaseUrl'],
    anonKey: config['supabaseAnonKey'],
  );

  await initializeApp();
}

Future<void> initializeApp() async {
  await Firebase.initializeApp();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedLocale = prefs.getString('language_code');
  final ThemeNotifier themeNotifier =
      await ThemeNotifier.loadThemeFromPreferences();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: MyApp(savedLocale: savedLocale),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? savedLocale;

  const MyApp({super.key, this.savedLocale});

  Locale? _determineLocale() {
    if (savedLocale != null && savedLocale!.isNotEmpty) {
      try {
        return Locale(savedLocale!);
      } catch (e) {
        debugPrint('Invalid locale format: $savedLocale');
      }
    }
    return Get.deviceLocale;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return ScreenUtilInit(
              designSize: Size(constraints.maxWidth, constraints.maxHeight),
              splitScreenMode: true,
              minTextAdapt: true,
              child: Consumer<ThemeNotifier>(
                builder: (context, themeNotifier, child) {
                  Locale? initialLocale = _determineLocale();
                  return GetMaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: themeNotifier.currentTheme,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    locale: initialLocale,
                    supportedLocales: L10n.all,
                    home: const IntroScreen(),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
