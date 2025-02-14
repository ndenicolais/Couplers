import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UserService {
  final Logger _logger = Logger();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? get currentUser => _auth.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _client = Supabase.instance.client;

  // Function to get the engagement date of the current user
  Future<DateTime?> getCoupleDate() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('couple').doc(currentUser!.uid).get();

        if (userDoc.exists) {
          if (userDoc['coupleDate'] != null) {
            return (userDoc['coupleDate'] as Timestamp).toDate();
          } else {
            return null;
          }
        }
      } catch (e) {
        _logger.e("Error during the recovery of the engagement date");
      }
    }
    return null;
  }

  // Function to add an image from Supabase
  Future<String> addUserImageSupabase(String userId, File imageFile) async {
    var uuid = const Uuid();
    String uniqueId = uuid.v4();
    String fileExtension = extension(imageFile.path);
    final filePath = '$userId/users/$uniqueId$fileExtension';
    await _client.storage.from('images').upload(filePath, imageFile);
    return filePath;
  }

  // Function to delete an image from Supabase
  Future<void> deleteUserImageSupabase(String userId, String fileName) async {
    final path = '$userId/users/$fileName';
    _logger.i('Deleting image from Supabase with path: $path');

    try {
      await _client.storage.from('images').remove([path]);
      _logger.i("Image successfully deleted from Supabase");
    } catch (e) {
      _logger.e("Error in deleting image from Supabase: $e");
    }
  }

  // Function to get public url from Supabase
  String getUserImageUrlSupabase(String userId, String fileName) {
    return _client.storage
        .from('images')
        .getPublicUrl('$userId/users/$fileName');
  }

  // Function to delete all user folders in Supabase
  Future<void> deleteUserFolderSupabase(String userId) async {
    final folders = ['users', 'events'];

    for (final folder in folders) {
      final pathPrefix = '$userId/$folder/';
      _logger
          .i('Deleting all files in Supabase folder with prefix: $pathPrefix');

      try {
        // List all files in the folder
        final result =
            await _client.storage.from('images').list(path: pathPrefix);

        if (result.isEmpty) {
          _logger.i("No files found in Supabase folder: $pathPrefix");
          continue;
        }

        // Handle nested files in the 'events' folder
        if (folder == 'events') {
          for (final directory in result) {
            final nestedPathPrefix = '$pathPrefix${directory.name}/';
            final nestedResult = await _client.storage
                .from('images')
                .list(path: nestedPathPrefix);

            if (nestedResult.isEmpty) {
              _logger.i(
                  "No files found in nested Supabase folder: $nestedPathPrefix");
              continue;
            }

            final nestedFilePaths = nestedResult
                .map((file) => '$nestedPathPrefix${file.name}')
                .toList();
            await _client.storage.from('images').remove(nestedFilePaths);
            _logger.i(
                "All files successfully deleted from nested Supabase folder: $nestedPathPrefix");
          }
        } else {
          // Handle files in the 'users' folder
          final filePaths =
              result.map((file) => '$pathPrefix${file.name}').toList();
          await _client.storage.from('images').remove(filePaths);
          _logger.i(
              "All files successfully deleted from Supabase folder: $pathPrefix");
        }
      } catch (e) {
        _logger.e("Error in deleting user folder from Supabase: $e");
      }
    }
  }
}
