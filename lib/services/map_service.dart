import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
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
      void Function(String, Map<String, dynamic>, int) onMarkerTap) async {
    try {
      final snapshot = await _markersCollection.get();
      final markers = snapshot.docs.expand((doc) {
        final data = doc.data();
        final event = EventModel.fromFirestore(doc.id, data);

        return event.positions
            .where((position) => position != null)
            .map((position) async {
          final numberOfEvents = await _getEventCountForMarker(event);

          return Marker(
            width: 40.w,
            height: 40.h,
            point: position!,
            child: GestureDetector(
              onTap: () => onMarkerTap(doc.id, data, numberOfEvents),
              child: Icon(
                MingCuteIcons.mgc_location_fill,
                color: event.getColor().withValues(alpha: 0.3),
                size: 30.sp,
                shadows: const [
                  Shadow(
                    color: Colors.blueGrey,
                    offset: Offset(1, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        });
      }).toList();

      return Future.wait(markers);
    } catch (e) {
      _logger.e("Error while loading markers: $e");
      throw Exception("Error while loading markers.");
    }
  }

  // Function that loads all events for those markers
  Future<List<Map<String, dynamic>>> loadEventsForMarker(
      String location) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .where('locations', arrayContains: location)
          .get();

      _logger.d('Events found for $location: ${snapshot.docs.length}');

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

  // Function to get the number of events associated with a marker
  Future<int> _getEventCountForMarker(EventModel event) async {
    try {
      // Query without array-contains filter
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      // Filter results locally
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final locations = List<String>.from(data['locations'] ?? []);
        return event.locations.any((location) => locations.contains(location));
      }).toList();

      return filteredDocs.length;
    } catch (e) {
      _logger.e("Error in calculating number of events: $e");
      return 0;
    }
  }

  // Function to obtain coordinates from an address
  Future<LatLng?> getCoordinatesFromAddress(String location) async {
    try {
      List<Location> locations = await locationFromAddress(location);

      if (locations.isNotEmpty) {
        double latitude = locations[0].latitude;
        double longitude = locations[0].longitude;

        return LatLng(latitude, longitude);
      } else {
        return null;
      }
    } catch (e) {
      _logger.e("Error in geocoding: $e");
      return null;
    }
  }
}
