import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/note_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class NoteService {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;

  // Function to add a note
  Future<void> addNote(NoteModel note) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }
      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('notes')
          .add(note.toFirestore());

      _logger.i("Note added successfully");
    } catch (e) {
      _logger.e("Error in adding note: $e");
    }
  }

  // Function to update a note
  Future<void> updateNote(NoteModel note) async {
    try {
      if (currentUser == null) {
        throw "User not logged in";
      }
      if (note.id == null) {
        throw "Missing note ID";
      }

      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('notes')
          .doc(note.id)
          .update(note.toFirestore());

      _logger.i("Note with ID ${note.id} successfully updated");
    } catch (e) {
      _logger.e("Error updating the note: $e");
    }
  }

  // Function to delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore
          .collection('couple')
          .doc(currentUser!.uid)
          .collection('notes')
          .doc(noteId)
          .delete();

      _logger.i("Note with ID $noteId successfully deleted");
    } catch (e) {
      _logger.e("Error in deleting the note: $e");
    }
  }

  // Function to get all notes
  Stream<List<NoteModel>> getNotes(String userId) {
    {
      return _firestore
          .collection('couple')
          .doc(userId)
          .collection('notes')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc.id, doc.data()))
            .toList();
      });
    }
  }
}
