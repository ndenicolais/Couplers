import 'package:couplers/models/event_model.dart';
import 'package:couplers/screens/events/event_details_screen.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/services/user_service.dart';
import 'package:couplers/utils/date_calculation.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EventService _eventService = EventService();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String eventTypeName = '';
  String? selectedEventType;
  bool isEditing = false;
  List<EventModel> _events = [];
  DateTime? coupleDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Column(
        children: [
          _buildCalendar(context),
          _buildEventStream(context),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadCoupleDate();
  }

  Future<void> _loadEvents() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final events = await _eventService.getEvents(currentUser.uid).first;
      setState(() {
        _events = events;
      });
    }
  }

  Future<void> _loadCoupleDate() async {
    DateTime? date = await UserService().getCoupleDate();
    if (mounted) {
      setState(() {
        coupleDate = date;
      });
    }
  }

  List<Map<String, String>> _getCelebrationsForDay(
      BuildContext context, DateTime date) {
    Locale locale = Localizations.localeOf(context);
    if (coupleDate == null) {
      return [];
    }

    final anniversaries = DateCalculations.calculateAnniversaries(
      coupleDate!,
      AppLocalizations.of(context)!.milestones_screen_card_anniversary,
      locale,
    );
    final dayversaries = DateCalculations.calculateDayversaries(
      coupleDate!,
      AppLocalizations.of(context)!.milestones_screen_card_dayversary,
      locale,
    );

    final celebrations = anniversaries.where((anniversary) {
      final anniversaryDate = DateFormat('dd MMMM yyyy', locale.toString())
          .parse(anniversary['date']!);
      return isSameDay(date, anniversaryDate);
    }).toList();

    celebrations.addAll(dayversaries.where((dayversary) {
      final dayversaryDate = DateFormat('dd MMMM yyyy', locale.toString())
          .parse(dayversary['date']!);
      return isSameDay(date, dayversaryDate);
    }).toList());

    return celebrations;
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
        AppLocalizations.of(context)!.calendar_screen_title,
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

  Widget _buildCalendar(BuildContext context) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(1990, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      locale: Get.locale?.toString() ?? 'en_US',
      weekendDays: const [DateTime.sunday],
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: GoogleFonts.josefinSans(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      calendarStyle: CalendarStyle(
        todayTextStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiaryFixed,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        outsideTextStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14.sp,
        ),
        weekendTextStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        defaultTextStyle: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 14.sp,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryFixed,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final eventMarkers = _buildEventsMarker(date, events);
          final milestoneMarkers = _buildMilestonesMarkers(date);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              eventMarkers,
              milestoneMarkers,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventStream(BuildContext context) {
    return Expanded(
      child: StreamBuilder<List<EventModel>>(
        stream: _eventService.getEvents(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator(context);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            if (_selectedDay != null &&
                _getCelebrationsForDay(context, _selectedDay!).isNotEmpty) {
              return _buildEventListView([], context);
            } else {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.calendar_screen_empty_month,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 20.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
          }

          final events = snapshot.data!;
          final currentMonth = _focusedDay.month;
          final currentYear = _focusedDay.year;
          final filteredEvents = events.where((event) {
            final eventMonth = event.startDate.month;
            final eventYear = event.startDate.year;

            return eventMonth == currentMonth && eventYear == currentYear;
          }).toList();

          filteredEvents.sort((a, b) => b.startDate.compareTo(a.startDate));

          return _buildEventListView(filteredEvents, context);
        },
      ),
    );
  }

  Widget _buildEventListView(
    List<EventModel> filteredEvents,
    BuildContext context,
  ) {
    Locale locale = Localizations.localeOf(context);
    final selectedEvents = filteredEvents.where((event) {
      if (_selectedDay == null) {
        return false;
      }

      if (event.endDate != null) {
        return _selectedDay!
                .isAfter(event.startDate.subtract(const Duration(days: 1))) &&
            _selectedDay!.isBefore(event.endDate!.add(const Duration(days: 1)));
      }
      return isSameDay(event.startDate, _selectedDay);
    }).toList();

    final celebrations =
        _getCelebrationsForDay(context, _selectedDay ?? DateTime.now())
            .where((celebration) {
      final celebrationDate = DateFormat('dd MMMM yyyy', locale.toString())
          .parse(celebration['date']!);
      return celebrationDate.month == _focusedDay.month &&
          celebrationDate.year == _focusedDay.year;
    }).toList();

    if (selectedEvents.isEmpty && celebrations.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.calendar_screen_empty_day,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 20.sp,
          ),
        ),
      );
    }

    final allItems = [
      ...selectedEvents.map((event) => {
            'type': 'event',
            'data': event,
          }),
      ...celebrations.map((celebration) => {
            'type': 'celebration',
            'data': celebration,
          }),
    ];

    return ListView.builder(
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];

        if (item['type'] == 'event') {
          final event = item['data'] as EventModel;
          return GestureDetector(
            onTap: () {
              Get.to(
                () => EventDetailsScreen(eventId: event.id!),
                transition: Transition.fade,
                duration: const Duration(milliseconds: 500),
              );
            },
            child: Card(
              elevation: 0,
              color: event.getColor().withValues(alpha: 0.3),
              margin: EdgeInsets.all(8.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(
                  color: event.getColor(),
                  width: 1.w,
                ),
              ),
              child: ListTile(
                leading: event.getIcon(
                    color: Theme.of(context).colorScheme.tertiary),
                title: Text(
                  event.title,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(event.startDate),
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 16.sp,
                  ),
                ),
                trailing: Icon(
                  MingCuteIcons.mgc_right_fill,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
          );
        } else {
          final celebration = item['data'] as Map<String, String>;
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondary,
            margin: EdgeInsets.all(8.r),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: ListTile(
              leading: Icon(
                celebration.containsKey('anniversary')
                    ? MingCuteIcons.mgc_anniversary_fill
                    : MingCuteIcons.mgc_love_fill,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                celebration['anniversary'] ?? celebration['dayversary']!,
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              subtitle: Text(
                celebration['date']!,
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              trailing: Icon(
                celebration.containsKey('anniversary')
                    ? MingCuteIcons.mgc_anniversary_fill
                    : MingCuteIcons.mgc_love_fill,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    final eventsForDay = _events.where((event) {
      if (event.endDate != null) {
        return date
                .isAfter(event.startDate.subtract(const Duration(days: 0))) &&
            date.isBefore(event.endDate!.add(const Duration(days: 1)));
      }
      return isSameDay(event.startDate, date);
    }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 16.w,
      height: 16.h,
      child: eventsForDay.isNotEmpty
          ? Stack(
              children: List.generate(
                eventsForDay.length,
                (index) {
                  Color eventColor = eventsForDay[index].getColor();
                  return Positioned(
                    left: index * 6,
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: eventColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildMilestonesMarkers(DateTime date) {
    Locale locale = Localizations.localeOf(context);
    if (coupleDate == null) {
      return Container();
    }

    final anniversaries = DateCalculations.calculateAnniversaries(
      coupleDate!,
      AppLocalizations.of(context)!.milestones_screen_card_anniversary,
      locale,
    );
    final dayversaries = DateCalculations.calculateDayversaries(
      coupleDate!,
      AppLocalizations.of(context)!.milestones_screen_card_dayversary,
      locale,
    );

    final celebrationForDay = anniversaries.where((anniversary) {
      final anniversaryDate = DateFormat('dd MMMM yyyy', locale.toString())
          .parse(anniversary['date']!);
      return isSameDay(date, anniversaryDate);
    }).toList();

    celebrationForDay.addAll(dayversaries.where((dayversary) {
      final dayversaryDate = DateFormat('dd MMMM yyyy', locale.toString())
          .parse(dayversary['date']!);
      return isSameDay(date, dayversaryDate);
    }).toList());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 16.w,
      height: 16.h,
      child: celebrationForDay.isNotEmpty
          ? Stack(
              children: List.generate(
                celebrationForDay.length,
                (index) {
                  return Positioned(
                    left: index * 6,
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}
