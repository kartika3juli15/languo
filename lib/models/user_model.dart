import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String userName;
  final String userEmail;
  final String userRole;
  String? userPhoto;
  final String? userPass;
  final num sisaCuti;

  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    this.userPhoto,
    this.userPass,
    required this.sisaCuti,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': uid,
      'user_name': userName,
      'user_email': userEmail,
      'user_role': userRole,
      'user_photo': userPhoto,
      'user_password': userPass,
      'sisa_cuti': sisaCuti,
      "created_at": Timestamp.fromDate(createdAt),
    };
  }

  /// Convert Firestore -> Model
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserModel(
      uid: doc.id,
      userName: data['user_name'],
      userEmail: data['user_email'],
      userRole: data['user_role'],
      userPhoto: data['user_photo'],
      userPass: data['user_password'],
      sisaCuti: data['sisa_cuti'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }
}
