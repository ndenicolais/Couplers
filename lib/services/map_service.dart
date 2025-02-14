import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:couplers/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class MapService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  // Markers collection for the current user
  CollectionReference<Map<String, dynamic>> get _markersCollection {
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    return _firestore
        .collection('couple')
        .doc(currentUser!.uid)
        .collection('events');
  }

  // Function that loads all markers
  Future<List<Marker>> loadMarkersFromFirestore(
      void Function(String, Map<String, dynamic>, LatLng) onMarkerTap) async {
    try {
      final snapshot = await _markersCollection.get();
      final Map<LatLng, int> positionEventCount = {};
      final markers = <Marker>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final event = EventModel.fromFirestore(doc.id, data);

        for (final position in event.positions) {
          if (position != null) {
            positionEventCount.update(
              position,
              (positionCount) => positionCount + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final event = EventModel.fromFirestore(doc.id, data);

        for (final position in event.positions) {
          if (position != null) {
            final eventCount = positionEventCount[position] ?? 0;
            markers.add(Marker(
              point: position,
              child: GestureDetector(
                onTap: () => onMarkerTap(doc.id, data, position),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      MingCuteIcons.mgc_location_fill,
                      color: eventCount > 1
                          ? AppColors.darkBrick
                          : event.getColor(),
                      size: 30.sp,
                    ),
                    if (eventCount > 1)
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 15.h,
                          height: 15.h,
                          padding: EdgeInsets.all(2.w),
                          decoration: const BoxDecoration(
                            color: AppColors.darkGold,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              eventCount.toString(),
                              style: GoogleFonts.josefinSans(
                                color: AppColors.charcoal,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ));
          }
        }
      }

      return markers;
    } catch (e) {
      _logger.e("Error while loading markers: $e");
      throw Exception("Error while loading markers.");
    }
  }

  // Function that loads all events for those markers
  Future<List<Map<String, dynamic>>> loadEventsForMarker(
      LatLng position) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .where('positions', arrayContains: {
        'lat': position.latitude,
        'lng': position.longitude
      }).get();

      _logger.d(
          'Events found for ${position.latitude}, ${position.longitude}: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      _logger.e("Error while loading events: $e");
      return [];
    }
  }

  // Function to load all events
  Future<List<EventModel>> loadAllEvents() async {
    try {
      final snapshot = await _markersCollection.get();
      List<EventModel> events = snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel.fromFirestore(doc.id, data);
      }).toList();
      return events;
    } catch (e) {
      _logger.e("Error while loading events: $e");
      throw Exception("Error while loading events.");
    }
  }

  // Function that searches events by keyword in title or locations
  Future<List<EventModel>> searchEvents(String keyword) async {
    try {
      final events = await loadAllEvents();
      final filteredEvents = events.where((event) {
        final titleLower = event.title.toLowerCase();
        final locationsLower = event.locations.join(' ').toLowerCase();
        final searchLower = keyword.toLowerCase();
        return titleLower.contains(searchLower) ||
            locationsLower.contains(searchLower);
      }).toList();
      return filteredEvents;
    } catch (e) {
      _logger.e("Error while searching events: $e");
      throw Exception("Error while searching events.");
    }
  }

  // Function to get the number of events associated with a marker
  Future<int> getEventCountForMarker(LatLng position) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .where('positions', arrayContains: {
        'lat': position.latitude,
        'lng': position.longitude
      }).get();

      return snapshot.docs.length;
    } catch (e) {
      _logger.e("Error in calculating number of events: $e");
      return 0;
    }
  }

  // Function to get event locations for a marker
  Future<Set<String>> getEventLocationsForMarker(LatLng position) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .where('positions', arrayContains: {
        'lat': position.latitude,
        'lng': position.longitude
      }).get();

      Set<String> locations = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final event = EventModel.fromFirestore(doc.id, data);

        for (int i = 0; i < event.positions.length; i++) {
          if (event.positions[i] != null &&
              event.positions[i]!.latitude == position.latitude &&
              event.positions[i]!.longitude == position.longitude) {
            final cityName = event.locations[i].split(',').first;
            locations.add(cityName);
          }
        }
      }

      return locations;
    } catch (e) {
      _logger.e("Error while loading event locations: $e");
      return {};
    }
  }
}
