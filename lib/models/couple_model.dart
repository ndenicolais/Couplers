import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couplers/models/user_model.dart';

class CoupleModel {
  final UserModel user1;
  final UserModel user2;
  final DateTime? coupleDate;

  CoupleModel({
    required this.user1,
    required this.user2,
    this.coupleDate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'user1': user1.toFirestore(),
      'user2': user2.toFirestore(),
      'coupleDate': coupleDate != null ? Timestamp.fromDate(coupleDate!) : null,
    };
  }

  factory CoupleModel.fromFirestore(Map<String, dynamic> data) {
    return CoupleModel(
      user1: UserModel.fromFirestore(data['user1']),
      user2: UserModel.fromFirestore(data['user2']),
      coupleDate: data['coupleDate'] != null
          ? (data['coupleDate'] as Timestamp).toDate()
          : null,
    );
  }
}
