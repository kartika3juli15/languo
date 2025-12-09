import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanCutiModel {
  final String cutiId;
  final String userId;
  final String userName;
  final String userRole;
  final String userEmail;
  final String alasan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  String? keterangan;
  final String? lampiranUrl;
  final String? fileName;
  final num sisaCutiSaatPengajuan;
  final String status;
  final DateTime createdAt;
  final DateTime? tanggalVerifikasi;

  PengajuanCutiModel({
    required this.cutiId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.alasan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.keterangan,
    this.lampiranUrl,
    this.fileName,
    required this.sisaCutiSaatPengajuan,
    required this.status,
    this.tanggalVerifikasi,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Model -> Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      "user_id": userId,
      "user_name": userName,
      "user_role": userRole,
      "user_email": userEmail,
      "alasan": alasan,
      "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
      "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
      "keterangan": keterangan,
      "lampiran_url": lampiranUrl,
      "file_name": fileName,
      "sisa_cuti_saat_pengajuan": sisaCutiSaatPengajuan,
      "status": status,
      "created_at": Timestamp.fromDate(createdAt),
      "tanggal_verifikasi": tanggalVerifikasi,
    };
  }

  /// Firestore -> Model
  factory PengajuanCutiModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return PengajuanCutiModel(
      cutiId: doc.id,
      userId: data["user_id"],
      userName: data["user_name"],
      userRole: data["user_role"],
      userEmail: data["user_email"],
      alasan: data["alasan"],
      tanggalMulai: (data["tanggal_mulai"] as Timestamp).toDate(),
      tanggalSelesai: (data["tanggal_selesai"] as Timestamp).toDate(),
      keterangan: data["keterangan"],
      lampiranUrl: data["lampiran_url"],
      fileName: data["file_name"],
      sisaCutiSaatPengajuan: data["sisa_cuti_saat_pengajuan"],
      status: data["status"],
      createdAt: (data["created_at"] as Timestamp).toDate(),
      tanggalVerifikasi: (data["tanggal_verifikasi"] as Timestamp).toDate(),
    );
  }
}
