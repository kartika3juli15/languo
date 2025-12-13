import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiModel {
  final int userId; 
  // Mengacu ke operator_uid (UID Firebase)
  final String operatorUid;
  // Menggantikan absensi_date, check_in/out (ERD menggunakan datetime/time)
  final Timestamp checkInTime; 

  final Timestamp checkOutTime;
  
  // Status (dari ERD: absensi_status, is_confirmed - kita pakai satu status string)
  final String status; 
  // Field tambahan dari ERD: absensi_status (enum)
  final String absensiStatus; 

  AbsensiModel({
    required this.userId,
    // Hapus: required this.qrId,
    required this.operatorUid,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.absensiStatus,
  });

  // Fungsi untuk mengkonversi model Dart ke format Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      // Hapus: 'qr_id': qrId,
      'operator_uid': operatorUid,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'status': status,
      'absensi_status': absensiStatus,
    };
  }

  // ==========================================================
  // LOGIKA VALIDASI DUPLIKASI HARIAN
  // ==========================================================
  
  // Getter PENTING: ID Dokumen unik (Cek Duplikasi Server)
  // Duplikasi dicek berdasarkan user_id dan TANGGAL HARI INI.
  String get documentId {
    // Format: "USER_ID_YYYYMMDD"
    final date = checkInTime.toDate();
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${userId}_$dateString';
  }

  // ==========================================================
  // FACTORY CONSTRUCTOR (DIPERLUKAN getTodayAbsensi)
  // ==========================================================

  // Fungsi untuk membuat objek dari data Firestore
  factory AbsensiModel.fromMap(Map<String, dynamic> map, String docId) {
    // Parsing docId untuk mendapatkan userId (karena docId = USER_ID_TANGGAL)
    final parts = docId.split('_');
    final userId = int.parse(parts.first); 
    
    return AbsensiModel(
      userId: userId,
      operatorUid: map['operator_uid'] as String,
      checkInTime: map['check_in_time'] as Timestamp,
      checkOutTime: map['check_out_time'] as Timestamp,
      status: map['status'] as String,
      absensiStatus: map['absensi_status'] as String,
    );
  }
}