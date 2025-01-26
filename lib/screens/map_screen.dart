import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/services/map_service.dart';
import 'package:couplers/widgets/custom_loader.dart';
import 'package:couplers/widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Logger _logger = Logger();
  String currentUserId = "";
  final MapService _mapService = MapService();
  bool _isLocationGranted = false;
  List<Marker> _markers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: _isLocationGranted
          ? FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(41.9099533, 12.371192),
                initialZoom: 5.5.r,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            )
          : Center(
              child: Text(
                AppLocalizations.of(context)!.map_screen_error_permission,
                style: GoogleFonts.josefinSans(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 20.sp,
                ),
              ),
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
    PermissionStatus locationPermission = await Permission.location.request();

    if (locationPermission.isGranted) {
      setState(() {
        _isLocationGranted = true;
      });
      _loadMarkers();
    } else if (locationPermission.isDenied) {
      setState(() {
        _isLocationGranted = false;
      });
      if (mounted) {
        showErrorToast(
          context,
          AppLocalizations.of(context)!.map_screen_error_permission,
        );
      }
    } else if (locationPermission.isPermanentlyDenied) {
      if (mounted) {
        showErrorToast(
          context,
          AppLocalizations.of(context)!.map_screen_error_permission_permanent,
        );
      }
      openAppSettings();
    }
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

  void _showMarkerOptions(
      String markerId, Map<String, dynamic> data, int numberOfEvents) async {
    if (data['locations'] != null && data['locations'].isNotEmpty) {
      String location = data['locations'][0];
      Future<List<Map<String, dynamic>>> eventsListFuture =
          _mapService.loadEventsForMarker(location);

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  MingCuteIcons.mgc_location_3_fill,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: Text(
                  '${AppLocalizations.of(context)!.map_screen_sheet_title} $numberOfEvents',
                  style: GoogleFonts.josefinSans(
                      color: Theme.of(context).colorScheme.tertiary),
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: eventsListFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingIndicator(context);
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      eventDate
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                      style: GoogleFonts.josefinSans(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        fontSize: 14.sp,
                                      ),
                                    ));
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
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.map_screen_title_serch,
                hintStyle:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
                border: InputBorder.none,
              ),
              style: GoogleFonts.josefinSans(
                color: Theme.of(context).colorScheme.secondary,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (query) {
                _searchLocation(query.trim());
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
            }
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

  Future<void> _searchLocation(String query) async {
    _logger.i("Search by location: $query");

    try {
      final markers = await _mapService
          .loadMarkersFromFirestore((docId, data, numberOfEvents) {
        String location = data['location'];
        if (location.toLowerCase().contains(query.toLowerCase())) {
          _logger.d("Marker found for the location: $location");
          _showMarkerOptions(docId, data, numberOfEvents);
        }
      });

      setState(() {
        _markers = markers;
      });

      if (_markers.isEmpty) {
        if (mounted) {
          showErrorToast(
            context,
            AppLocalizations.of(context)!.map_screen_search_empty,
          );
        }
      } else {
        _showEventsBottomSheet(query, _markers.length);
      }
    } catch (e) {
      _logger.e("Error while searching for location: $e");
    }
  }

  void _showEventsBottomSheet(String location, int numberOfEvents) async {
    Future<List<Map<String, dynamic>>> eventsListFuture =
        _mapService.loadEventsForMarker(location);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.primary,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: eventsListFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingIndicator(context);
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!
                            .map_screen_error_events_data,
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 24.sp,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!
                            .map_screen_error_events_location,
                        style: GoogleFonts.josefinSans(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 22.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    List<Map<String, dynamic>> eventsList = snapshot.data!;

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
                    );
                  }
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
