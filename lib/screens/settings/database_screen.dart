import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/couple_model.dart';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/services/user_service.dart';
import 'package:couplers/utils/date_calculation.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  DatabasePageState createState() => DatabasePageState();
}

class DatabasePageState extends State<DatabasePage> {
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final EventService _eventService = EventService();
  String? userEmail1;
  String? userEmail2;
  DateTime? coupleDate;
  int? eventCount;
  Map<int, int>? eventCountPerYear = {};
  int? anniversaryCount;
  int? dayversaryCount;
  Map<String, int>? eventCountByCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.h,
              children: [
                _buildUserInfoCard(context),
                _buildAchievementsCard(context),
                _buildEventsCard(context),
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
    _loadCoupleData();
    _loadCoupleDate();
    _loadEventCountByCategory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEventData();
  }

  Future<void> _loadCoupleData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('couple')
        .doc(currentUser!.uid)
        .get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;
      CoupleModel couple = CoupleModel.fromFirestore(data);

      setState(() {
        userEmail1 = couple.user1.email;
        userEmail2 = couple.user2.email;
      });
    }
  }

  Future<void> _loadCoupleDate() async {
    DateTime? date = await _userService.getCoupleDate();
    if (mounted) {
      setState(() {
        coupleDate = date;
      });
    }
  }

  Future<void> _loadEventData() async {
    Locale locale = Localizations.localeOf(context);
    if (currentUser != null) {
      int count = await _eventService.getEventCount();
      Map<int, int> countPerYear = await _eventService.getEventCountPerYear();
      var sortedCountPerYear = Map.fromEntries(countPerYear.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)));
      if (mounted) {
        List<Map<String, String>> anniversaryList =
            DateCalculations.calculateAnniversaries(
          coupleDate!,
          AppLocalizations.of(context)!.milestones_screen_card_dayversary,
          locale,
        );
        List<Map<String, String>> dayversaryList =
            DateCalculations.calculateDayversaries(
          coupleDate!,
          AppLocalizations.of(context)!.milestones_screen_card_dayversary,
          locale,
        );

        setState(() {
          eventCount = count;
          eventCountPerYear = sortedCountPerYear;
          anniversaryCount = anniversaryList.length;
          dayversaryCount = dayversaryList.length;
        });
      }
    }
  }

  Future<void> _loadEventCountByCategory() async {
    if (currentUser != null) {
      Map<String, int> countByCategory =
          await _eventService.countEventsByCategory();
      setState(() {
        eventCountByCategory = countByCategory;
      });
    }
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
        AppLocalizations.of(context)!.database_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryFixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.database_screen_user_title,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),
            Text(
              AppLocalizations.of(context)!.database_screen_user_email_private,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18.sp,
              ),
            ),
            Text(
              '$userEmail1',
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context)!.database_screen_user_email_partner,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18.sp,
              ),
            ),
            Text(
              '$userEmail2',
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context)!.database_screen_user_creation_date,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18.sp,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy')
                  .format(currentUser!.metadata.creationTime!),
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryFixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.database_screen_milestones_title,
              style: GoogleFonts.josefinSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),
            Row(
              spacing: 10.w,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .database_screen_milestones_anniversaries,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  '${anniversaryCount ?? 'Loading...'}',
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              spacing: 10.w,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .database_screen_milestones_dayversaries,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  '${dayversaryCount ?? 'Loading...'}',
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCard(BuildContext context) {
    if (eventCountByCategory == null) {
      return _buildLoadingIndicator(context);
    }

    List<Widget> countWidgets = [];
    eventCountByCategory!.forEach((category, eventCount) {
      String translatedCategory = getTranslatedEventCategory(context, category);
      countWidgets.add(
        Column(
          children: [
            Row(
              children: [
                Icon(
                  EventModel.categoryIconMap[category]!,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                SizedBox(width: 10.w),
                Text(
                  translatedCategory,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '$eventCount',
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.w),
          ],
        ),
      );
    });

    return Card(
      color: Theme.of(context).colorScheme.tertiaryFixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.database_screen_events_title,
              style: GoogleFonts.josefinSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.database_screen_events_totals,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${eventCount ?? 'Loading...'}',
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.database_screen_events_by_year,
              style: GoogleFonts.josefinSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),
            if (eventCountPerYear != null)
              ...eventCountPerYear!.entries.map(
                (entry) => Row(
                  children: [
                    Text(
                      '${entry.key}',
                      style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '${entry.value}',
                      style: GoogleFonts.josefinSans(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.database_screen_events_by_category,
              style: GoogleFonts.josefinSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.secondary),
            ...countWidgets,
          ],
        ),
      ),
    );
  }
}
