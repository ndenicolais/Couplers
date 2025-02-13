import 'package:couplers/models/couple_model.dart';
import 'package:couplers/screens/authentication/login/login_controller.dart';
import 'package:couplers/screens/calendar_screen.dart';
import 'package:couplers/screens/milestones_screen.dart';
import 'package:couplers/screens/events/event_list_screen.dart';
import 'package:couplers/screens/favorites_screen.dart';
import 'package:couplers/screens/user/user_controller.dart';
import 'package:couplers/screens/map_screen.dart';
import 'package:couplers/screens/notes/notes_screen.dart';
import 'package:couplers/screens/time_screen.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/utils/custom_icons.dart';
import 'package:couplers/widgets/custom_drawer.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final UserController userController = Get.put(UserController());
  final LoginController loginController = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
            appBar: _buildAppBar(context),
            drawer: const CustomDrawer(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            body: _buildBody(context),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(int index) {
    final screens = [
      const TimeScreen(),
      const MilestonesScreen(),
      const CalendarScreen(),
      const MapScreen(),
      const FavoritesScreen(),
      const NotesScreen(),
    ];

    Get.to(
      () => screens[index],
      transition: Transition.fade,
      duration: const Duration(milliseconds: 500),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.home_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return _buildLoadingIndicator(context);
      } else if (userController.hasError.value) {
        return _buildErrorState(context);
      } else if (userController.coupleData.value == null) {
        return _buildEmptyState(context);
      }

      final coupleData = userController.coupleData.value!;
      return _buildMainContent(context, coupleData);
    });
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.home_screen_error_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.home_screen_empty_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, CoupleModel coupleData) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.r),
          child: Column(
            children: [
              _buildWelcomeText(context),
              _buildPartnerNames(context, coupleData),
              SizedBox(height: 20.h),
              _buildMemoriesCard(context),
              SizedBox(height: 10.h),
              _buildGridView(context),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.home_screen_welcome_text,
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.tertiary,
        fontSize: 32.sp,
      ),
    );
  }

  Widget _buildPartnerNames(BuildContext context, CoupleModel coupleData) {
    return Text(
      '${coupleData.user1.name ?? AppLocalizations.of(context)!.home_screen_welcome_user1_default} ${AppLocalizations.of(context)!.home_screen_welcome_user_union} ${coupleData.user2.name ?? AppLocalizations.of(context)!.home_screen_welcome_user2_default}',
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 36.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMemoriesCard(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDarkMode = themeNotifier.isDarkMode;
    final double cardHeight = ScreenUtil().screenWidth > 600 ? 300.h : 150.h;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(
          () => const EventListScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      },
      child: SizedBox(
        height: cardHeight,
        child: Card(
          color: AppColors.lightBrick,
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CouplersIcons.iconhomememories,
                  size: 48.sp,
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 8.h),
                Text(
                  AppLocalizations.of(context)!.home_menu_events,
                  style: GoogleFonts.josefinSans(
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDarkMode = themeNotifier.isDarkMode;
    final List<Map<String, dynamic>> localizedItems = [
      {
        'icon': CouplersIcons.iconhometime,
        'label': AppLocalizations.of(context)!.home_menu_time,
        'color': AppColors.homeRedLight,
      },
      {
        'icon': CouplersIcons.iconhomedates,
        'label': AppLocalizations.of(context)!.home_menu_milestones,
        'color': AppColors.homeRedLight,
      },
      {
        'icon': CouplersIcons.iconhomecalendar,
        'label': AppLocalizations.of(context)!.home_menu_calendar,
        'color': AppColors.homeRedMedium,
      },
      {
        'icon': CouplersIcons.iconhomemap,
        'label': AppLocalizations.of(context)!.home_menu_map,
        'color': AppColors.homeRedMedium,
      },
      {
        'icon': CouplersIcons.iconhomefavorites,
        'label': AppLocalizations.of(context)!.home_menu_favorites,
        'color': AppColors.homeRedDark,
      },
      {
        'icon': CouplersIcons.iconhomenotes,
        'label': AppLocalizations.of(context)!.home_menu_notes,
        'color': AppColors.homeRedDark,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 5.h,
        childAspectRatio: 1.2,
      ),
      itemCount: localizedItems.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToScreen(index);
          },
          child: Card(
            color: localizedItems[index]['color'],
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    localizedItems[index]['icon'],
                    size: 48.sp,
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    localizedItems[index]['label'],
                    style: GoogleFonts.josefinSans(
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 18.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
