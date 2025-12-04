import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiModel {
  final String uid;
  final String userId;
  final String operatorUid;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String absensiStatus;
  final DateTime createdAt; // Tanggal data dibuat

  AbsensiModel({
    required this.uid,
    required this.userId,
    required this.operatorUid,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.absensiStatus,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "operator_uid": operatorUid,
      "check_in_time": Timestamp.fromDate(checkInTime),
      "check_out_time":
          checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      "status": status,
      "absensi_status": absensiStatus,
      "created_at": Timestamp.fromDate(createdAt),
    };
  }

  factory AbsensiModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return AbsensiModel(
      uid: doc.id,
      userId: data["user_id"],
      operatorUid: data["operator_uid"],
      checkInTime: (data["check_in_time"] as Timestamp).toDate(),
      checkOutTime: data["check_out_time"] != null
          ? (data["check_out_time"] as Timestamp).toDate()
          : null,
      status: data["status"],
      absensiStatus: data["absensi_status"],
      createdAt: (data["created_at"] as Timestamp).toDate(),
    );
  }
}
