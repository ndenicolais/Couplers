import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String? name;
  final String? image;
  final DateTime? birthday;
  final String? gender;

  UserModel({
    required this.email,
    this.name,
    this.image,
    this.birthday,
    this.gender,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'image': image,
      'birthday': birthday,
      'gender': gender,
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      email: data['email'],
      name: data['name'],
      image: data['image'],
      birthday: data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null,
      gender: data['gender'],
    );
  }
}
