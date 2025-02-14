import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/services/map_service.dart';
import 'package:couplers/utils/permission_helper.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Logger _logger = Logger();
  String currentUserId = "";
  final MapService _mapService = MapService();
  List<Marker> _markers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();
  final List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FmMap(
        mapOptions: MapOptions(
          initialCenter: const LatLng(41.9099533, 12.371192),
          initialZoom: 5.5.r,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        markers: _markers,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _checkLocationPermission();
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      _loadMarkers();
    } else {
      _logger.d('User not logged in');
    }
  }

  Future<void> _checkLocationPermission() async {
    await requestLocationPermission(context, _loadMarkers);
  }

  void _loadMarkers() async {
    if (currentUserId.isEmpty) {
      _logger.w("User ID is empty. Cannot load markers.");
      return;
    }

    try {
      _logger.i("Loading markers for the user $currentUserId.");

      final markers = await _mapService
          .loadMarkersFromFirestore((docId, data, numberOfEvents) {
        _logger.d("Marker: ID=$docId, Data=$data, Eventi=$numberOfEvents");

        _showMarkerOptions(docId, data, numberOfEvents);
      });
      _logger.d("Total of markers loaded: ${markers.length}");

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      _logger.e("Error while loading markers: $e");
    }
  }

  void _filterEvents(String query) async {
    try {
      final events = await _mapService.searchEvents(query);
      setState(() {
        _filteredEvents = events;
        _isSearching = query.isNotEmpty;
        _logger.d("Filtered events: ${_filteredEvents.length} events found");

        if (_filteredEvents.isNotEmpty) {
          _showEventsBottomSheet(_filteredEvents);
        } else {
          showErrorToast(context,
              '${AppLocalizations.of(context)!.map_screen_error_events_location} $query');
        }
      });
    } catch (e) {
      _logger.e("Error while filtering events: $e");
    }
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredEvents = _allEvents;

      if (_filteredEvents.isNotEmpty) {
        _showEventsBottomSheet(_filteredEvents);
      }

      _logger.d(
          "Search cleared and markers updated: ${_filteredEvents.length} events");
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  AppBar _buildAppBar() {
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
      title: _isSearching
          ? TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .map_screen_title_label_search,
                  hintText: AppLocalizations.of(context)!
                      .map_screen_title_hint_search,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            MingCuteIcons.mgc_close_fill,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: _clearSearch,
                        )),
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (query) {
                _filterEvents(query.trim());
              },
            )
          : Text(
              AppLocalizations.of(context)!.map_screen_title_standard,
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.secondary,
      actions: [
        IconButton(
          icon: Icon(
            MingCuteIcons.mgc_search_line,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
            });
            if (_isSearching) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FocusScope.of(context).requestFocus(_focusNode);
              });
            } else {
              _searchController.clear();
              _loadMarkers();
              _clearSearch;
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CustomLoader(
        width: 50.w,
        height: 50.h,
      ),
    );
  }

  void _showMarkerOptions(
      String markerId, Map<String, dynamic> data, LatLng position) async {
    final eventsListFuture = _mapService.loadEventsForMarker(position);
    final numberOfEvents = await _mapService.getEventCountForMarker(position);
    final Set<String> locations =
        await _mapService.getEventLocationsForMarker(position);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.primary,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                MingCuteIcons.mgc_location_fill,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: Text(
                locations.join(', '),
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${AppLocalizations.of(context)!.map_screen_sheet_title} $numberOfEvents',
                style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.tertiary),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  builder: (context) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: eventsListFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingIndicator();
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .map_screen_sheet_error,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 24.sp,
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .map_screen_sheet_empty,
                              style: GoogleFonts.josefinSans(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 24.sp,
                              ),
                            ),
                          );
                        } else {
                          List<Map<String, dynamic>> eventsList =
                              snapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: eventsList.length,
                            itemBuilder: (context, index) {
                              var event = eventsList[index];
                              DateTime eventDate =
                                  (event['startDate'] as Timestamp).toDate();

                              return ListTile(
                                title: Text(
                                  event['title'],
                                  style: GoogleFonts.josefinSans(
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  eventDate.toLocal().toString().split(' ')[0],
                                  style: GoogleFonts.josefinSans(
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEventsBottomSheet(List<EventModel> events) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.primary,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (events.isEmpty)
                Center(
                  child: Text(
                    AppLocalizations.of(context)!
                        .map_screen_error_events_location,
                    style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 22.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    var event = events[index];
                    DateTime eventDate = event.startDate;

                    return ListTile(
                      title: Text(
                        event.title,
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        eventDate.toLocal().toString().split(' ')[0],
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _loadMarkers();
                  });
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r))),
                child: Text(
                  AppLocalizations.of(context)!.map_screen_sheet_close,
                  style: GoogleFonts.josefinSans(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
