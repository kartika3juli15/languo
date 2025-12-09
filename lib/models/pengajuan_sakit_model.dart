import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanSakitModel {
  final String sakitId;
  final String userId;
  final String userName;
  final String userRole;
  final String userEmail;
  final String diagnosa;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String keterangan;
  final String? lampiranUrl;
  final String? storagePath;
  final String? fileName;
  final String status;
  final DateTime? tanggalVerifikasi;
  final DateTime createdAt;

  PengajuanSakitModel({
    required this.sakitId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.diagnosa,
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

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_role": userRole,
      "user_email": userEmail,
      "diagnosa": diagnosa,
      "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
      "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
      "keterangan": keterangan,
      "lampiran_url": lampiranUrl,
      "file_name": fileName,
      "storage_path": storagePath,
      "status": status,
      "created_at": Timestamp.fromDate(createdAt),
      "tanggal_verifikasi": tanggalVerifikasi,
    };
  }

  /// Firestore → Model
  factory PengajuanSakitModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return PengajuanSakitModel(
      sakitId: doc.id,
      userId: data["user_id"],
      userName: data["user_name"],
      userEmail: data["user_email"],
      userRole: data["user_role"],
      diagnosa: data["diagnosa"],
      tanggalMulai: (data["tanggal_mulai"] as Timestamp).toDate(),
      tanggalSelesai: (data["tanggal_selesai"] as Timestamp).toDate(),
      keterangan: data["keterangan"],
      lampiranUrl: data["lampiran_url"],
      fileName: data["file_name"],
      storagePath: data["storage_path"],
      status: data["status"],
      createdAt: (data["created_at"] as Timestamp).toDate(),
      tanggalVerifikasi: (data["tanggal_verifikasi"] as Timestamp?)?.toDate(),
    );
  }
}
