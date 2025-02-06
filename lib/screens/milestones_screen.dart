import 'package:couplers/services/user_service.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:couplers/theme/theme_notifier.dart';
import 'package:couplers/utils/date_calculation.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:provider/provider.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  MilestonesScreenState createState() => MilestonesScreenState();
}

class MilestonesScreenState extends State<MilestonesScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  DateTime? coupleDate;
  late TabController tabController;
  double sliderValueAnniversary = 0;
  double sliderValueDayversary = 0;

  bool isCoupleDateAvailable() {
    return coupleDate != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!isCoupleDateAvailable()) {
      return Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: _buildLoadingIndicator(context),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(context, tabController),
            _buildTabBarView(
              context,
              tabController,
              sliderValueAnniversary,
              getAnniversaries,
              sliderValueDayversary,
              getDayversaries,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCoupleDate();
    tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadCoupleDate() async {
    DateTime? date = await _userService.getCoupleDate();

    if (date != null) {
      setState(() {
        coupleDate = date;
        sliderValueAnniversary = _calculateSliderValueAnniversary(coupleDate!);
        sliderValueDayversary = _calculateSliderValueDayversary(coupleDate!);
      });
    }
  }

  double _calculateSliderValueAnniversary(DateTime coupleDate) {
    DateTime today = DateTime.now();
    DateTime nextAnniversary =
        DateTime(today.year, coupleDate.month, coupleDate.day);

    if (nextAnniversary.isBefore(today)) {
      nextAnniversary =
          DateTime(today.year + 1, coupleDate.month, coupleDate.day);
    }

    int daysRemaining = nextAnniversary.difference(today).inDays;
    return 365 - daysRemaining.toDouble();
  }

  double _calculateSliderValueDayversary(DateTime coupleDate) {
    DateTime today = DateTime.now();
    int daysDiff = today.difference(coupleDate).inDays;

    int nextDayversaryDay = (daysDiff ~/ 100 + 1) * 100;
    DateTime nextDayversary = coupleDate.add(Duration(days: nextDayversaryDay));

    int daysRemaining = nextDayversary.difference(today).inDays;
    return 100 - daysRemaining.toDouble();
  }

  List<Map<String, String>> getAnniversaries() {
    Locale locale = Localizations.localeOf(context);
    if (coupleDate != null) {
      return DateCalculations.calculateAnniversaries(
        coupleDate!,
        AppLocalizations.of(context)!.milestones_screen_card_anniversary,
        locale,
      );
    }
    return [];
  }

  List<Map<String, String>> getDayversaries() {
    Locale locale = Localizations.localeOf(context);
    if (coupleDate != null) {
      return DateCalculations.calculateDayversaries(
        coupleDate!,
        AppLocalizations.of(context)!.milestones_screen_card_dayversary,
        locale,
      );
    }
    return [];
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
        AppLocalizations.of(context)!.milestones_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }
}

Widget _buildLoadingIndicator(BuildContext context) {
  return Center(
    child: CustomLoader(
      width: 50.w,
      height: 50.h,
    ),
  );
}

Widget _buildTabBar(BuildContext context, TabController tabController) {
  return TabBar(
    controller: tabController,
    indicatorColor: Theme.of(context).colorScheme.tertiary,
    indicatorWeight: 8.w,
    labelColor: Theme.of(context).colorScheme.tertiary,
    labelStyle: GoogleFonts.josefinSans(
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelColor: Theme.of(context).colorScheme.secondary,
    unselectedLabelStyle: GoogleFonts.josefinSans(
      fontSize: 16.sp,
    ),
    tabs: [
      _buildAnniversaryTab(context),
      _buildDayversaryTab(context),
    ],
  );
}

Widget _buildAnniversaryTab(BuildContext context) {
  return Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          MingCuteIcons.mgc_anniversary_fill,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(AppLocalizations.of(context)!
            .milestones_screen_tab_anniversary_title),
      ],
    ),
  );
}

Widget _buildDayversaryTab(BuildContext context) {
  return Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          MingCuteIcons.mgc_love_fill,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(AppLocalizations.of(context)!
            .milestones_screen_tab_dayversary_title),
      ],
    ),
  );
}

Widget _buildTabBarView(
  BuildContext context,
  TabController tabController,
  double sliderValueAnniversary,
  Function calculateAnniversaries,
  sliderValueDayversary,
  Function calculateDayversaries,
) {
  return Expanded(
    child: TabBarView(
      controller: tabController,
      children: [
        _buildDateTabAnniversary(
          context,
          sliderValueAnniversary,
          calculateAnniversaries,
        ),
        _buildDateTabDayversary(
          context,
          sliderValueDayversary,
          calculateDayversaries,
        )
      ],
    ),
  );
}

Widget _buildDateTabAnniversary(
  BuildContext context,
  double sliderValueAnniversary,
  Function calculateAnniversaries,
) {
  return DateTab(
    sliderValue: sliderValueAnniversary,
    sliderMaxValue: 365,
    subtitleText:
        AppLocalizations.of(context)!.milestones_screen_tab_anniversary_b,
    leadingIcon: MingCuteIcons.mgc_anniversary_fill,
    items: calculateAnniversaries(),
  );
}

Widget _buildDateTabDayversary(
  BuildContext context,
  double sliderValueDayversary,
  Function calculateDayversaries,
) {
  return DateTab(
    sliderValue: sliderValueDayversary,
    sliderMaxValue: 100,
    subtitleText:
        AppLocalizations.of(context)!.milestones_screen_tab_dayversary_b,
    leadingIcon: MingCuteIcons.mgc_love_fill,
    items: calculateDayversaries(),
  );
}

class DateTab extends StatelessWidget {
  final double sliderValue;
  final int sliderMaxValue;
  final String subtitleText;
  final IconData leadingIcon;
  final List<Map<String, String>> items;

  const DateTab({
    super.key,
    required this.sliderValue,
    required this.sliderMaxValue,
    required this.subtitleText,
    required this.leadingIcon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDarkMode = themeNotifier.isDarkMode;
    return Column(
      children: [
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.milestones_screen_tab_all_miss,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '${(sliderMaxValue - sliderValue).toStringAsFixed(0)} ${AppLocalizations.of(context)!.milestones_screen_tab_all_days}',
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              subtitleText,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          min: 0,
          max: sliderMaxValue.toDouble(),
          divisions: sliderMaxValue,
          label: sliderValue.toStringAsFixed(0),
          onChanged: (value) {},
          activeColor: Theme.of(context).colorScheme.secondary,
          inactiveColor: Theme.of(context).colorScheme.tertiary,
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        MingCuteIcons.mgc_black_board_2_line,
                        size: 50.sp,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        AppLocalizations.of(context)!
                            .milestones_screen_tab_all_empty,
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 18.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: items.asMap().entries.map(
                    (entry) {
                      int index = entry.key;
                      Map<String, String> item = entry.value;
                      return SizedBox(
                        height: 140.h,
                        child: Card(
                          color: cardColors[index % cardColors.length],
                          elevation: 5,
                          margin: EdgeInsets.all(8.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                leadingIcon,
                                size: 50.sp,
                                color: isDarkMode
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                item['anniversary'] ?? item['dayversary'] ?? '',
                                style: GoogleFonts.josefinSans(
                                  color: isDarkMode
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                item['date'] ?? '',
                                style: GoogleFonts.josefinSans(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiaryFixed,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
        ),
      ],
    );
  }
}
