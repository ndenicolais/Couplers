import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EventService {
  final Logger _logger = Logger();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? get currentUser => _auth.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _client = Supabase.instance.client;

  // Function that adds a new event to Firestore
  Future<String> addEvent(EventModel event) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      DocumentReference docRef = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .add(event.toFirestore());

      _logger.i("Event added successfully with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      _logger.e("Error adding the event: $e");
      rethrow;
    }
  }

  // Function that updates an existing event
  Future<void> updateEvent(EventModel event) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }
      if (event.id == null) {
        throw "ID missing event";
      }

      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .doc(event.id)
          .update(event.toFirestore());

      _logger.i("Event with ID ${event.id} successfully updated");
    } catch (e) {
      _logger.e("Error updating the event: $e");
      rethrow;
    }
  }

  // Function that deletes an event
  Future<void> deleteEvent(String eventId) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .doc(eventId)
          .delete();

      _logger.i("Event with ID $eventId successfully deleted");
    } catch (e) {
      _logger.e("Error in deleting the event: $e");
      rethrow;
    }
  }

  // Function that gets an event based on its ID
  Future<EventModel> getEventById(String eventId) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      final doc = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .doc(eventId)
          .get();

      if (!doc.exists) {
        throw "Event not found";
      }

      return EventModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  // Function that gets an event based on its ID using Stream
  Stream<EventModel> getEventStreamById(String eventId) {
    try {
      return _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .doc(eventId)
          .snapshots(includeMetadataChanges: false)
          .map((docSnapshot) {
        if (!docSnapshot.exists) {
          throw Exception("Event not found");
        }
        return EventModel.fromFirestore(
          docSnapshot.id,
          docSnapshot.data() as Map<String, dynamic>,
        );
      });
    } catch (e) {
      throw Exception('Error in event recovery: $e');
    }
  }

  // Function that gets events
  Stream<List<EventModel>> getEvents(String userId) {
    return _firestore
        .collection('couple')
        .doc(userId)
        .collection('events')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // Function that gets types events
  Future<List<String>> getEventTypes() async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      final snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      final types = snapshot.docs
          .map((doc) => doc.data()['type'] as String?)
          .where((type) => type != null)
          .cast<String>()
          .toSet()
          .toList();

      return types;
    } catch (e) {
      _logger.e("Error retrieving event types: $e");
      return [];
    }
  }

  // Function to get the count of events created by the current user
  Future<int> getEventCount() async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      final snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      _logger.e("Error retrieving event count: $e");
      return 0;
    }
  }

  // Function to get the count of events created by the current user per year
  Future<Map<int, int>> getEventCountPerYear() async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      final snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      Map<int, int> eventCountPerYear = {};

      for (var doc in snapshot.docs) {
        DateTime eventDate = (doc.data()['startDate'] as Timestamp).toDate();
        int year = eventDate.year;
        if (eventCountPerYear.containsKey(year)) {
          eventCountPerYear[year] = eventCountPerYear[year]! + 1;
        } else {
          eventCountPerYear[year] = 1;
        }
      }

      return eventCountPerYear;
    } catch (e) {
      _logger.e("Error retrieving event count per year: $e");
      return {};
    }
  }

  // Function to update event status as favorite
  Future<void> toggleFavoriteStatus(String eventId, bool isFavorite) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }

      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .doc(eventId)
          .update({'isFavorite': isFavorite});

      _logger.i("Favorite state of the event $eventId successfully updated");
    } catch (e) {
      _logger.e("Error updating event favorite status: $e");
    }
  }

  // Function that gets favorites events
  Stream<List<EventModel>> getFavoriteEvents(String userId) {
    return _firestore
        .collection('couple')
        .doc(userId)
        .collection('events')
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // Function to add an image to Supabase under the event ID folder
  Future<String> addEventImageSupabase(
      String userId, String eventId, File imageFile) async {
    var uuid = const Uuid();
    String uniqueId = uuid.v4();
    final path = '$userId/events/$eventId/$uniqueId.jpg';

    await _client.storage.from('images').upload(path, imageFile);

    return path;
  }

  // Function to delete an image from Supabase
  Future<void> deleteEventImageSupabase(
      String userId, String eventId, String fileName) async {
    final path = '$userId/events/$eventId/$fileName';
    _logger.i('Deleting image from Supabase with path: $path');

    try {
      await _client.storage.from('images').remove([path]);
      _logger.i("Image successfully deleted from Supabase");
    } catch (e) {
      _logger.e("Error in deleting image from Supabase: $e");
    }
  }

  // Function to get public url from Supabase
  String getEventImageUrlSupabase(
      String userId, String eventId, String fileName) {
    return _client.storage
        .from('images')
        .getPublicUrl('$userId/events/$eventId/$fileName');
  }
}
