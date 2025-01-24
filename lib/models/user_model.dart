class UserModel {
  final String email;
  final String? name;
  final String? image;

  UserModel({
    required this.email,
    this.name,
    this.image,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'image': image,
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      email: data['email'],
      name: data['name'],
      image: data['image'],
    );
  }
}
