class UserModel {
  final String uid;
  final String email;
  final String role;
  final String name;

  UserModel({required this.uid, required this.email, required this.role, required this.name});

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
    };
  }
}