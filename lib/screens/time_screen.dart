import 'package:couplers/models/couple_model.dart';
import 'package:couplers/screens/user/user_controller.dart';
import 'package:couplers/utils/time_utils.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_time_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});

  @override
  TimeScreenState createState() => TimeScreenState();
}

class TimeScreenState extends State<TimeScreen> {
  final UserController homepageController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBody(context),
                  SizedBox(height: 30.h),
                  _buildBottomIcon(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int calculateTotalDays(DateTime fromDate) {
    final currentDate = DateTime.now();
    return currentDate.difference(fromDate).inDays;
  }

  String _getLabel(String label, int value, BuildContext context) {
    if (value == 1) {
      if (label == AppLocalizations.of(context)!.time_screen_date_years) {
        return AppLocalizations.of(context)!.time_screen_date_year;
      }
      if (label == AppLocalizations.of(context)!.time_screen_date_months) {
        return AppLocalizations.of(context)!.time_screen_date_month;
      }
      if (label == AppLocalizations.of(context)!.time_screen_date_days) {
        return AppLocalizations.of(context)!.time_screen_date_day;
      }
      if (label == AppLocalizations.of(context)!.time_screen_date_hours) {
        return AppLocalizations.of(context)!.time_screen_date_hour;
      }
      if (label == AppLocalizations.of(context)!.time_screen_date_minutes) {
        return AppLocalizations.of(context)!.time_screen_date_minute;
      }
      if (label == AppLocalizations.of(context)!.time_screen_date_seconds) {
        return AppLocalizations.of(context)!.time_screen_date_second;
      }
      return label;
    }
    return label;
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
        AppLocalizations.of(context)!.time_screen_title,
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
      if (homepageController.isLoading.value) {
        return _buildLoadingIndicator(context);
      } else if (homepageController.hasError.value) {
        return _buildErrorState(context);
      } else {
        final coupleModel = homepageController.coupleData.value;
        if (coupleModel != null) {
          return _buildMainContent(coupleModel);
        } else {
          return _buildEmptyState(context);
        }
      }
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
        AppLocalizations.of(context)!.time_screen_error_state,
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
        AppLocalizations.of(context)!.time_screen_empty_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMainContent(CoupleModel coupleModel) {
    String userName1 = coupleModel.user1.name!;
    String userName2 = coupleModel.user2.name!;
    DateTime coupleDate = coupleModel.coupleDate!;
    Map<String, int> dateTime = TimeUtils.calculateCoupleTime(coupleDate);

    final totalDays = calculateTotalDays(coupleDate);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 12.h,
      children: [
        _buildTextSection(
            context,
            AppLocalizations.of(context)!.time_screen_text_a,
            22.sp,
            Theme.of(context).colorScheme.tertiary),
        _buildDynamicTitle(context, userName1, userName2),
        _buildTextSection(
            context,
            AppLocalizations.of(context)!.time_screen_text_b,
            22.sp,
            Theme.of(context).colorScheme.tertiary),
        _buildDateText(context, coupleDate),
        _buildTextSection(
            context,
            AppLocalizations.of(context)!.time_screen_text_c,
            22.sp,
            Theme.of(context).colorScheme.tertiary),
        _buildTotalDaysSection(totalDays),
        _buildTextSection(
            context,
            AppLocalizations.of(context)!.time_screen_text_d,
            22.sp,
            Theme.of(context).colorScheme.tertiary),
        _buildTimeUnits(context, dateTime),
      ],
    );
  }

  Widget _buildDynamicTitle(
    BuildContext context,
    String userName1,
    String userName2,
  ) {
    return Text(
      '$userName1 & $userName2',
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 44.sp,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildDateText(BuildContext context, DateTime coupleDate) {
    return Text(
      DateFormat('dd/MM/yyyy').format(coupleDate),
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 32.sp,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildTextSection(
    BuildContext context,
    String text,
    double fontSize,
    Color color,
  ) {
    return Text(
      text,
      style: GoogleFonts.josefinSans(
        color: color,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildTotalDaysSection(int totalDays) {
    return Text(
      '$totalDays ${AppLocalizations.of(context)!.time_screen_text_e}',
      style: GoogleFonts.josefinSans(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 32.sp,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildTimeUnits(BuildContext context, Map<String, int> dateTime) {
    if (dateTime.isEmpty) return Container();

    return Column(
      children: [
        CustomTimeDisplay(
          label: _getLabel(AppLocalizations.of(context)!.time_screen_date_years,
              dateTime['years'] ?? 0, context),
          value: dateTime['years'] ?? 0,
        ),
        CustomTimeDisplay(
          label: _getLabel(
              AppLocalizations.of(context)!.time_screen_date_months,
              dateTime['months'] ?? 0,
              context),
          value: dateTime['months'] ?? 0,
        ),
        CustomTimeDisplay(
          label: _getLabel(AppLocalizations.of(context)!.time_screen_date_days,
              dateTime['days'] ?? 0, context),
          value: dateTime['days'] ?? 0,
        ),
        CustomTimeDisplay(
          label: _getLabel(AppLocalizations.of(context)!.time_screen_date_hours,
              dateTime['hours'] ?? 0, context),
          value: dateTime['hours'] ?? 0,
        ),
        CustomTimeDisplay(
          label: _getLabel(
              AppLocalizations.of(context)!.time_screen_date_minutes,
              dateTime['minutes'] ?? 0,
              context),
          value: dateTime['minutes'] ?? 0,
        ),
        CustomTimeDisplay(
          label: _getLabel(
              AppLocalizations.of(context)!.time_screen_date_seconds,
              dateTime['seconds'] ?? 0,
              context),
          value: dateTime['seconds'] ?? 0,
        ),
      ],
    );
  }

  Widget _buildBottomIcon(BuildContext context) {
    return Icon(
      MingCuteIcons.mgc_love_fill,
      size: 120.sp,
      color: Theme.of(context).colorScheme.secondary,
    );
  }
}
