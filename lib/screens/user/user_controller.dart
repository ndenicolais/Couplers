import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/couple_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  var isLoading = true.obs;
  var hasError = false.obs;
  var coupleData = Rxn<CoupleModel>();

  @override
  void onInit() {
    super.onInit();
    fetchCoupleData();
  }

  Future<void> fetchCoupleData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('couple')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        coupleData.value = CoupleModel.fromFirestore(docSnapshot.data()!);
        isLoading.value = false;
      } else {
        throw Exception('Data of the couple not found');
      }
    } catch (e) {
      hasError.value = true;
      isLoading.value = false;
    }
  }
}
