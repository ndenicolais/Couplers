import 'package:couplers/models/event_model.dart';
import 'package:couplers/screens/events/event_details_screen.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  final EventService _eventService = EventService();
  String? selectedCategory;
  List<EventModel> currentFilteredEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _buildBody(context),
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
        AppLocalizations.of(context)!.favorites_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [
        IconButton(
          icon: Icon(
            MingCuteIcons.mgc_filter_2_fill,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () {
            _showCategoryFilterBottomSheet(context);
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getFavoriteEvents(_eventService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(context);
        }

        var events = snapshot.data ?? [];
        if (selectedCategory != null && selectedCategory != 'All') {
          events = events
              .where((event) => event.category == selectedCategory)
              .toList();
        }
        events.sort(
          (a, b) {
            int comparison = b.addedDate.compareTo(a.addedDate);
            if (comparison != 0) {
              return comparison;
            } else {
              return b.startDate.compareTo(a.startDate);
            }
          },
        );

        if (events.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildEventList(events, context);
      },
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.favorites_screen_empty_state,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 24.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events, BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event, context);
      },
    );
  }

  Widget _buildEventCard(EventModel event, BuildContext context) {
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
          leading: event.getIcon(color: Theme.of(context).colorScheme.tertiary),
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
          trailing: _buildFavoriteButton(event, context),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(EventModel event, BuildContext context) {
    return IconButton(
      icon: Icon(
        event.isFavorite
            ? MingCuteIcons.mgc_heart_fill
            : MingCuteIcons.mgc_heart_line,
        color: Theme.of(context).colorScheme.secondary,
      ),
      onPressed: () {
        _eventService.toggleFavoriteStatus(event.id!, !event.isFavorite);
      },
    );
  }

  void _showCategoryFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: EventModel.categoryFilter.map((String category) {
                return ListTile(
                  leading: Icon(
                    category == 'All'
                        ? MingCuteIcons.mgc_list_check_fill
                        : EventModel.categoryIconMap[category]!,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  title: Text(
                    getTranslatedEventCategory(context, category),
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
