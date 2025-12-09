import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String userName;
  final String userEmail;
  final String userRole;
  String? userPhoto;
  final num? sisaCuti;

  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    this.userPhoto,
    required this.sisaCuti,
    this.createdAt,
  });

  /// Convert Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': uid,
      'user_name': userName,
      'user_email': userEmail,
      'user_role': userRole,
      'user_photo': userPhoto,
      'sisa_cuti': (sisaCuti ?? 0),
    };
  }

  /// Convert Firestore -> Model
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserModel(
      uid: doc.id,
      userName: data['user_name'] ?? '',
      userEmail: data['user_email'] ?? '',
      userRole: data['user_role'] ?? '',
      userPhoto: data['user_photo'],
      sisaCuti: (data['sisa_cuti'] != null) ? (data['sisa_cuti'] as num) : null,
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }
}
