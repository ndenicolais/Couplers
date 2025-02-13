import 'package:couplers/onboarding/onboarding_items.dart';
import 'package:couplers/screens/home_screen.dart';
import 'package:couplers/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late OnboardingItems onboardingItems;
  final int _totalPages = 4;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onboardingItems = OnboardingItems(context);
  }

  void _nextPage() {
    if (_pageController.page!.toInt() < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _checkRememberMe();
    }
  }

  void _skip() {
    _checkRememberMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              onPageChanged: (index) => setState(
                  () => isLastPage = onboardingItems.items.length - 1 == index),
              controller: _pageController,
              itemCount: onboardingItems.items.length,
              itemBuilder: (context, index) {
                final item = onboardingItems.items[index];
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 180.w,
                        height: 180.h,
                        child: item.image,
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 70.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 60.h),
                        child: Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.josefinSans(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 30.r,
              left: 0.r,
              right: 0.r,
              child: isLastPage
                  ? Center(
                      child: SizedBox(
                        width: 220.w,
                        height: 60.h,
                        child: MaterialButton(
                          onPressed: () async {
                            final pres = await SharedPreferences.getInstance();
                            pres.setBool("onboarding_completed", true);
                            _checkRememberMe();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.r),
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary),
                          ),
                          color: Theme.of(context).colorScheme.secondary,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.onboarding_finish,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _skip,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.onboarding_skip,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Center(
                            child: SmoothPageIndicator(
                              controller: _pageController,
                              count: _totalPages,
                              effect: WormEffect(
                                dotWidth: 10.w,
                                dotHeight: 10.h,
                                spacing: 16.r,
                                radius: 8.r,
                                activeDotColor:
                                    Theme.of(context).colorScheme.tertiaryFixed,
                                dotColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _nextPage,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.onboarding_next,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      Get.offAll(
        () => const HomeScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    } else {
      Get.offAll(
        () => const WelcomeScreen(),
        transition: Transition.fade,
        duration: const Duration(milliseconds: 500),
      );
    }
  }
}
