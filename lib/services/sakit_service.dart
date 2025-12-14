import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class SakitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, String>> uploadLampiran({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    // ===== VALIDASI EKSTENSI (WAJIB PDF) =====
    final ext = fileName.split('.').last.toLowerCase();
    if (ext != 'pdf') {
      throw Exception("Lampiran sakit wajib berupa file PDF");
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(" ", "_");

    final storagePath = 'sakit_lampiran/$userId/${timestamp}_$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: "application/pdf",
    );

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return {
      'lampiran_url': url,
      'storage_path': storagePath,
    };
  }

  /// Kirim pengajuan sakit ke Firestore (Lampiran WAJIB)
  Future<void> kirimPengajuan({
    required String userId,
    required String diagnosa,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required Uint8List lampiranBytes,
    required String fileName,
    String? keterangan,
    DateTime? tanggalVerifikasi,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      if (ext != 'pdf') {
        throw Exception("Lampiran wajib berupa file PDF");
      }
      
      // Ambil data user
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final userName = userDoc.data()?["user_name"] ?? "-";
      final userRole = userDoc.data()?["user_role"] ?? "-";
      final userEmail = userDoc.data()?["user_email"] ?? "-";

      final uploadResult = await uploadLampiran(
        bytes: lampiranBytes,
        fileName: fileName,
        userId: userId,
      );

      await _firestore.collection("pengajuan_sakit").add({
        "user_id": userId,
        "diagnosa": diagnosa,
        "user_name": userName,
        "user_role": userRole,
        "user_email": userEmail,
        "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
        "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
        "keterangan": keterangan,
        "lampiran_url": uploadResult['lampiran_url'],
        "storage_path": uploadResult['storage_path'],
        "status": "Diajukan",
        "created_at": FieldValue.serverTimestamp(),
        "tanggal_verifikasi": tanggalVerifikasi,
      });
    } catch (e) {
      debugPrint("Error kirimPengajuan Sakit: $e");
      rethrow;
    }
  }

  /// Ambil rekapan sakit berdasarkan user
  Stream<QuerySnapshot> getRekapanSakit(String uid) {
    return _firestore
        .collection("pengajuan_sakit")
        .where("user_id", isEqualTo: uid)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  /// Hapus pengajuan sakit + lampiran
  Future<void> hapusPengajuanSakit(String sakitId) async {
    try {
      final sakitDocRef = _firestore.collection("pengajuan_sakit").doc(sakitId);
      final sakitDoc = await sakitDocRef.get();

      if (!sakitDoc.exists) throw Exception("Dokumen izin tidak ditemukan.");

      final storagePath = sakitDoc.data()?["storage_path"];
      if (storagePath != null && storagePath.isNotEmpty) {
        await _storage.ref().child(storagePath).delete();
      }

      await sakitDocRef.delete();
    } catch (e) {
      debugPrint("Error hapus pengajuan izin: $e");
      rethrow;
    }
  }
}
