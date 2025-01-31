import 'package:couplers/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/couple_model.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;
  final UserService _userService = UserService();

  // SIGNUP
  Future<User?> signup(CoupleModel couple, String password) async {
    final emailCheck1 = await _firestore
        .collection('couple')
        .where('user1.email', isEqualTo: couple.user1.email)
        .get();

    if (emailCheck1.docs.isNotEmpty) {
      throw Exception("personal_email_already_register");
    }

    final emailCheck1AsSecondary = await _firestore
        .collection('couple')
        .where('user2.email', isEqualTo: couple.user1.email)
        .get();

    if (emailCheck1AsSecondary.docs.isNotEmpty) {
      throw Exception("personal_email_register_as_partner_email");
    }

    final emailCheck2 = await _firestore
        .collection('couple')
        .where('user2.email', isEqualTo: couple.user2.email)
        .get();

    if (emailCheck2.docs.isNotEmpty) {
      throw Exception("partner_email_already_register");
    }

    final emailCheck2AsPrimary = await _firestore
        .collection('couple')
        .where('user1.email', isEqualTo: couple.user2.email)
        .get();

    if (emailCheck2AsPrimary.docs.isNotEmpty) {
      throw Exception("partner_email_register_as_personal_email");
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: couple.user1.email,
        password: password,
      );

      _logger.i("User successfully registered: ${couple.user1.email}");

      await _firestore.collection('couple').doc(userCredential.user?.uid).set({
        'user1': couple.user1.toFirestore(),
        'user2': couple.user2.toFirestore(),
        'coupleDate': couple.coupleDate != null
            ? Timestamp.fromDate(couple.coupleDate!)
            : null,
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', true);
      await prefs.setString('user_id', userCredential.user?.uid ?? '');

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN
  Future<User?> login(String email, String password, bool rememberMe) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .where('user1.email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('couple')
            .where('user2.email', isEqualTo: email)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        throw Exception("email_not_found");
      }

      var userDoc = snapshot.docs.first;
      String emailToUse = userDoc['user1']['email'];

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse.trim(),
        password: password.trim(),
      );

      _logger.i("User successfully logged: $emailToUse");

      if (rememberMe) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        await prefs.setString('user_id', userCredential.user?.uid ?? '');
      }

      return userCredential.user;
    } catch (e) {
      if (e.toString().contains("wrong-password")) {
        throw Exception("invalid_password");
      }
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      await prefs.remove('user_id');
    } catch (e) {
      throw Exception('Error during logout.');
    }
  }

  // RESET PASSWORD
  Future<String> resetPassword(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('couple')
          .where('user1.email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('couple')
            .where('user2.email', isEqualTo: email)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        throw Exception("email_not_found");
      }

      String emailToReset = email;
      if (snapshot.docs.isNotEmpty) {
        var docData = snapshot.docs.first.data() as Map<String, dynamic>;
        if (docData.containsKey('user2')) {
          if (docData['user2']['email'] == email) {
            emailToReset = docData['user1']['email'];
          }
        }
      }

      await _auth.sendPasswordResetEmail(email: emailToReset);

      return emailToReset;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // DELETE
  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _deleteEntireUserCollection(user.uid);
        await _userService.deleteUserFolderSupabase(user.uid);
        await user.delete();
        await logout();
      } catch (e) {
        throw Exception("Error while deleting: $e");
      }
    } else {
      throw Exception("No user logged in.");
    }
  }

  // Function to delete a user’s entire collection in Firestore
  Future<void> _deleteEntireUserCollection(String userId) async {
    try {
      List<String> subCollections = ['events', 'notes'];

      for (String collection in subCollections) {
        QuerySnapshot subCollectionSnapshot = await _firestore
            .collection('couple')
            .doc(userId)
            .collection(collection)
            .get();

        for (DocumentSnapshot doc in subCollectionSnapshot.docs) {
          await doc.reference.delete();
        }
        await _firestore.collection('couple').doc(userId).delete();
      }
    } catch (e) {
      throw Exception("Error during user document deletion: $e");
    }
  }
}
