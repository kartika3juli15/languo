import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanIzinModel {
  final String izinId;
  final String userId;
  final String userName;
  final String userRole;
  final String userEmail;
  final String perihal;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String keterangan;
  final String? lampiranUrl;
  final String? storagePath;
  final String? fileName;
  final String status;
  final DateTime? tanggalVerifikasi;
  final DateTime createdAt;

  PengajuanIzinModel({
    required this.izinId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.perihal,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.keterangan,
    this.lampiranUrl,
    this.storagePath,
    this.fileName,
    required this.status,
    this.tanggalVerifikasi,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_role": userRole,
      "user_email": userEmail,
      "perihal": perihal,
      "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
      "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
      "keterangan": keterangan,
      "lampiran_url": lampiranUrl,
      "file_name": fileName,
      "status": status,
      "created_at": Timestamp.fromDate(createdAt),
      "tanggal_verifikasi": tanggalVerifikasi,
    };
  }

  /// Firestore -> Model
  factory PengajuanIzinModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return PengajuanIzinModel(
      izinId: doc.id,
      userId: data["user_id"],
      userName: data["user_name"],
      userEmail: data["user_email"],
      userRole: data["user_role"],
      perihal: data["perihal"],
      tanggalMulai: (data["tanggal_mulai"] as Timestamp).toDate(),
      tanggalSelesai: (data["tanggal_selesai"] as Timestamp).toDate(),
      keterangan: data["keterangan"],
      lampiranUrl: data["lampiran_url"],
      fileName: data["file_name"],
      status: data["status"],
      createdAt: (data["created_at"] as Timestamp).toDate(),
      tanggalVerifikasi: (data["tanggal_verifikasi"] as Timestamp).toDate(),
    );
  }
}
