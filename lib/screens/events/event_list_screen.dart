import 'package:cached_network_image/cached_network_image.dart';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/screens/events/event_adder_screen.dart';
import 'package:couplers/screens/events/event_details_screen.dart';
import 'package:couplers/services/event_service.dart';
import 'package:couplers/utils/event_category_translations.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<EventListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final EventService _eventService = EventService();
  List<EventModel> events = [];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool isAscending = false;
  String? selectedCategory;
  int? selectedYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _buildBody(context),
      endDrawer: _buildEndDrawer(context),
      floatingActionButton: _buildAddEventButton(context),
    );
  }

  List<DropdownMenuItem<String>> _getCategoryDropdownItems(
      List<EventModel> events) {
    final categories = events.map((event) => event.category).toSet().toList();
    categories.sort();

    return categories.map((category) {
      return DropdownMenuItem(
        value: category,
        child: ListTile(
          leading: Icon(
            EventModel.categoryIconMap[category]!,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            getTranslatedEventCategory(context, category),
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<DropdownMenuItem<int>> _getYearDropdownItems(List<EventModel> events) {
    final years = events.map((event) => event.startDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));

    return years.map((year) {
      return DropdownMenuItem(
        value: year,
        child: Text(
          year.toString(),
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      );
    }).toList();
  }

  List<EventModel> _filterAndSortEvents(List<EventModel> events) {
    if (searchQuery.isNotEmpty) {
      events = events.where((event) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        final matchesTitle = event.title.toLowerCase().contains(lowerCaseQuery);
        final matchesLocation = event.locations
            .any((location) => location.toLowerCase().contains(lowerCaseQuery));
        return matchesTitle || matchesLocation;
      }).toList();
    }

    if (selectedCategory != null && selectedCategory != 'All') {
      events =
          events.where((event) => event.category == selectedCategory).toList();
    }

    if (selectedYear != null) {
      events = events
          .where((event) => event.startDate.year == selectedYear)
          .toList();
    }

    events.sort((a, b) {
      int comparison = a.startDate.compareTo(b.startDate);
      if (comparison == 0) {
        comparison = a.addedDate.compareTo(b.addedDate);
      }
      return isAscending ? comparison : -comparison;
    });

    return events;
  }

  void _resetFilters() {
    searchQuery = '';
    selectedCategory = 'All';
    selectedYear = null;
    isAscending = false;
    _searchController.clear();
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
        AppLocalizations.of(context)!.events_list_screen_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [
        Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(
                MingCuteIcons.mgc_settings_6_line,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            );
          },
        ),
      ],
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

  Widget _buildErrorState(BuildContext context, Object? error) {
    return Center(
      child: SizedBox(
        width: 320.w,
        child: Text(
          '${AppLocalizations.of(context)!.events_list_screen_error_state} $error',
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320.w,
        child: Text(
          AppLocalizations.of(context)!.events_list_screen_empty_state,
          style: GoogleFonts.josefinSans(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 24.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _eventService.getEvents(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error);
        }

        var events = snapshot.data ?? [];
        events = _filterAndSortEvents(events);

        if (events.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildEventList(context, events);
      },
    );
  }

  Widget _buildEventList(BuildContext context, List<EventModel> events) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      child: ListView(
        children: events.map((event) {
          return _buildEventCard(context, event);
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(event.startDate);
    final double cardHeight = ScreenUtil().screenWidth > 600 ? 260.h : 160.h;

    return InkWell(
      onTap: () {
        Get.to(
          () => EventDetailsScreen(eventId: event.id!),
          transition: Transition.fade,
          duration: const Duration(milliseconds: 500),
        );
      },
      child: Card(
        color: event.getColor().withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            event.images != null
                ? ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20.r),
                      topLeft: Radius.circular(20.r),
                    ),
                    child: SizedBox(
                      height: cardHeight,
                      width: double.infinity,
                      child: _buildEventImage(context, event.images!.first),
                    ),
                  )
                : const SizedBox.shrink(),
            Container(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      event.getIcon(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              event.title,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 16.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildFavoriteButton(context, event),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(BuildContext context, String imageUrl) {
    return FutureBuilder<Widget>(
      future: _buildImage(context, imageUrl),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CustomLoader(
              width: 50.w,
              height: 50.h,
            ),
          );
        } else if (snapshot.hasError) {
          return Icon(
            MingCuteIcons.mgc_close_fill,
            color: Theme.of(context).colorScheme.secondary,
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }

  Future<Widget> _buildImage(BuildContext context, String imageUrl) async {
    if (imageUrl.startsWith('http')) {
      final fileInfo = await DefaultCacheManager().getFileFromCache(imageUrl);
      if (fileInfo != null) {
        return Image.file(
          fileInfo.file,
          width: double.infinity,
          height: 160.h,
          fit: BoxFit.cover,
        );
      } else {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 160.h,
          fit: BoxFit.cover,
        );
      }
    } else {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 160.h,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildFavoriteButton(BuildContext context, EventModel event) {
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

  Drawer _buildEndDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.primary,
      width: MediaQuery.of(context).size.width * 0.6,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                _buildDrawerHeader(context),
                _buildFilterSearchField(context),
                SizedBox(height: 10.h),
                _buildFilterOrderTile(context),
                StreamBuilder<List<EventModel>>(
                  stream: _eventService.getEvents(currentUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    var events = snapshot.data ?? [];
                    return _buildFilterCategoryTile(context, events);
                  },
                ),
                StreamBuilder<List<EventModel>>(
                  stream: _eventService.getEvents(currentUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    var events = snapshot.data ?? [];
                    return _buildFilterYearTile(context, events);
                  },
                ),
              ],
            ),
          ),
          _buildResetButton(context),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Padding _buildDrawerHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Text(
        AppLocalizations.of(context)!.events_list_screen_filter_title,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Padding _buildFilterSearchField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!
              .events_list_screen_filter_label_search,
          hintText: AppLocalizations.of(context)!
              .events_list_screen_filter_hint_search,
          prefixIcon: Icon(
            MingCuteIcons.mgc_search_2_line,
            color: Theme.of(context).colorScheme.secondary,
          ),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    MingCuteIcons.mgc_close_fill,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  onPressed: _resetFilters,
                  visualDensity: VisualDensity.compact,
                ),
        ),
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.tertiary,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  ExpansionTile _buildFilterOrderTile(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 22.r),
      leading: Icon(
        isAscending
            ? MingCuteIcons.mgc_sort_ascending_line
            : MingCuteIcons.mgc_sort_descending_line,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        isAscending
            ? AppLocalizations.of(context)!.events_list_screen_order_ascending
            : AppLocalizations.of(context)!.events_list_screen_order_descending,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      children: [
        ListTile(
          leading: Icon(
            isAscending
                ? MingCuteIcons.mgc_sort_descending_line
                : MingCuteIcons.mgc_sort_ascending_line,
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(
            isAscending
                ? AppLocalizations.of(context)!
                    .events_list_screen_order_descending
                : AppLocalizations.of(context)!
                    .events_list_screen_order_ascending,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          onTap: () {
            setState(() {
              isAscending = !isAscending;
            });
            Get.back();
          },
        ),
      ],
    );
  }

  ExpansionTile _buildFilterCategoryTile(
      BuildContext context, List<EventModel> events) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 22.r),
      leading: Icon(
        MingCuteIcons.mgc_list_check_3_fill,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        AppLocalizations.of(context)!.events_list_screen_filter_category,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      children: _getCategoryDropdownItems(events)
          .map((DropdownMenuItem<String> item) {
        return ListTile(
          title: item.child,
          onTap: () {
            setState(() {
              selectedCategory = item.value;
            });
            Get.back();
          },
        );
      }).toList(),
    );
  }

  ExpansionTile _buildFilterYearTile(
      BuildContext context, List<EventModel> events) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 22.r),
      leading: Icon(
        MingCuteIcons.mgc_calendar_2_line,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        AppLocalizations.of(context)!.events_list_screen_filter_years,
        style: GoogleFonts.josefinSans(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      children: _getYearDropdownItems(events).map((DropdownMenuItem<int> item) {
        return ListTile(
          title: item.child,
          onTap: () {
            setState(() {
              selectedYear = item.value;
            });
            Get.back();
          },
        );
      }).toList(),
    );
  }

  Padding _buildResetButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: SizedBox(
        width: 150.w,
        height: 50.h,
        child: MaterialButton(
          color: Theme.of(context).colorScheme.secondary,
          textColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          onPressed: () {
            setState(() {
              _resetFilters();
            });
          },
          child: Text(
            AppLocalizations.of(context)!.events_list_screen_filter_reset,
            style: GoogleFonts.josefinSans(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEventButton(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      elevation: 0,
      onPressed: () {
        Get.to(
          () => const EventAdderScreen(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      },
      child: const Icon(MingCuteIcons.mgc_add_fill),
    );
  }
}
