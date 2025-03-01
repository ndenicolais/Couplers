import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EventService {
  final Logger _logger = Logger();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? get currentUser => _auth.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _client = Supabase.instance.client;

  // Function that get Events collection reference for current user
  CollectionReference getEventsCollection() {
    return _firestore
        .collection('couple')
        .doc(currentUser!.uid)
        .collection('events');
  }

  // Function that adds a new event to Firestore
  Future<String> addEvent(EventModel event) async {
    try {
      CollectionReference eventsCollection = getEventsCollection();
      DocumentReference docRef =
          await eventsCollection.add(event.toFirestore());
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
      CollectionReference eventsCollection = getEventsCollection();
      await eventsCollection.doc(event.id).update(event.toFirestore());
      _logger.i("Event with ID ${event.id} successfully updated");
    } catch (e) {
      _logger.e("Error updating the event: $e");
      rethrow;
    }
  }

  // Function that deletes an event
  Future<void> deleteEvent(String eventId) async {
    try {
      CollectionReference eventsCollection = getEventsCollection();
      await eventsCollection.doc(eventId).delete();
      _logger.i("Event with ID $eventId successfully deleted");
    } catch (e) {
      _logger.e("Error in deleting the event: $e");
      rethrow;
    }
  }

  // Function that gets an event based on its ID
  Future<EventModel> getEventById(String eventId) async {
    try {
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

  // Function to get the count of events
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

  // Function to get the count of events per year
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

  // Function to get the count of events per category
  Future<Map<String, int>> countEventsByCategory() async {
    if (currentUser == null) {
      throw "User not logged in";
    }

    try {
      final snapshot = await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      Map<String, int> eventCountByCategory = {};

      for (var doc in snapshot.docs) {
        String? category = doc.data()['category'] as String?;

        if (category != null) {
          if (eventCountByCategory.containsKey(category)) {
            eventCountByCategory[category] =
                eventCountByCategory[category]! + 1;
          } else {
            eventCountByCategory[category] = 1;
          }
        }
      }

      return eventCountByCategory;
    } catch (e) {
      _logger.e("Error counting events by category: $e");
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
    String fileExtension = extension(imageFile.path);
    final path = '$userId/events/$eventId/$uniqueId$fileExtension';

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

  // Converts Timestamp objects in the map to ISO 8601 string representations
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      }
    });
    return data;
  }

  // Export all events to JSON
  Future<String> exportCodesToJson() async {
    try {
      CollectionReference eventsCollection = getEventsCollection();
      QuerySnapshot querySnapshot = await eventsCollection.get();
      List<Map<String, dynamic>> eventList = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return _convertTimestamps(data);
      }).toList();
      String jsonEvents = jsonEncode(eventList);
      _logger.i('Events exported successfully.');
      return jsonEvents;
    } catch (e) {
      _logger.e('Error exporting events to JSON: $e');
      throw Exception('Failed to export events to JSON: $e');
    }
  }

  // Converts string representations of dates in the map to Timestamp objects
  Map<String, dynamic> _convertStringsToTimestamps(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if ((key == 'addedDate' || key == 'startDate' || key == 'endDate') &&
          value != null) {
        data[key] = Timestamp.fromDate(DateTime.parse(value));
      }
    });
    return data;
  }

  // Import events from JSON
  Future<void> importCodesFromJson(String jsonCodes, String userId) async {
    try {
      List<dynamic> eventList = jsonDecode(jsonCodes);
      for (var eventMap in eventList) {
        Map<String, dynamic> eventData = eventMap as Map<String, dynamic>;
        eventData = _convertStringsToTimestamps(eventData);

        EventModel events = EventModel.fromFirestore('', eventData);
        String eventId = await addEvent(events);
        List<dynamic>? imageUrls = eventData['images'];

        if (imageUrls != null && imageUrls.isNotEmpty) {
          List<String> uploadedImageUrls = [];
          for (var imageUrl in imageUrls) {
            Uri imageUri = Uri.parse(imageUrl);
            http.Response response = await http.get(imageUri);
            if (response.statusCode == 200) {
              File imageFile = File(
                  '${Directory.systemTemp.path}/${path.basename(imageUri.path)}');
              await imageFile.writeAsBytes(response.bodyBytes);
              String uploadedImagePath =
                  await addEventImageSupabase(userId, eventId, imageFile);
              final fileName = uploadedImagePath.split('/').last;
              String finalImageUrl =
                  getEventImageUrlSupabase(currentUser!.uid, eventId, fileName);
              uploadedImageUrls.add(finalImageUrl);
            } else {
              _logger.e('Failed to download image from $imageUrl');
            }
          }
          eventData['images'] = uploadedImageUrls;
        }

        EventModel confirmEvent = EventModel.fromFirestore(eventId, eventData);
        await updateEvent(confirmEvent);
      }
      _logger.i('Events imported successfully.');
    } catch (e) {
      _logger.e('Error importing events from JSON: $e');
      throw Exception('Failed to import events from JSON: $e');
    }
  }
}
