import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:free_map/free_map.dart';
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
      final markers = snapshot.docs.expand((doc) {
        final data = doc.data();
        final event = EventModel.fromFirestore(doc.id, data);

        return event.positions
            .where((position) => position != null)
            .map((position) => Marker(
                  point: position!,
                  child: GestureDetector(
                    onTap: () => onMarkerTap(doc.id, data, position),
                    child: Icon(
                      MingCuteIcons.mgc_location_fill,
                      color: event.getColor(),
                      size: 30.sp,
                    ),
                  ),
                ));
      }).toList();

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
      // Query without array-contains filter
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
}
