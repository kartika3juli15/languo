import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class SakitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload lampiran sakit ke Firebase Storage
  Future<Map<String, String>> uploadLampiran({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(" ", "_");

    final storagePath = 'sakit_lampiran/$userId/${timestamp}_$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    String ext = fileName.split(".").last.toLowerCase();
    final contentTypes = {
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "png": "image/png",
      "pdf": "application/pdf",
      "doc": "application/msword",
      "docx":
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    };
    String contentType = contentTypes[ext] ?? "application/octet-stream";

    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return {
      'lampiranUrl': url,
      'storagePath': storagePath,
      'fileName': fileName,
    };
  }

  /// Kirim pengajuan sakit ke Firestore (Lampiran WAJIB)
  Future<void> kirimPengajuan({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? keterangan,
    Uint8List? lampiranBytes,
    String? fileName,
  }) async {
    try {
      // === VALIDASI LAMPIRAN WAJIB ===
      if (lampiranBytes == null || fileName == null) {
        throw Exception("Lampiran surat sakit wajib diunggah.");
      }

      final userDoc = await _firestore.collection("users").doc(userId).get();
      final userName = userDoc.data()?["user_name"] ?? "-";
      final userRole = userDoc.data()?["user_role"] ?? "-";
      final emailUser = userDoc.data()?["user_email"] ?? "-";

      final uploadResult = await uploadLampiran(
        bytes: lampiranBytes,
        fileName: fileName,
        userId: userId,
      );

      await _firestore.collection("pengajuan_sakit").add({
        "userId": userId,
        "userName": userName,
        "emailUser": emailUser,
        "userRole": userRole,
        "tanggalMulai": Timestamp.fromDate(startDate),
        "tanggalSelesai": Timestamp.fromDate(endDate),
        "keterangan": keterangan,
        "lampiranUrl": uploadResult['lampiranUrl'],
        "storagePath": uploadResult['storagePath'],
        "fileName": uploadResult['fileName'],
        "status": "Diajukan",
        "createdAt": FieldValue.serverTimestamp(),
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
        .where("userId", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Hapus pengajuan sakit + lampiran
  Future<void> hapusPengajuanSakit(String sakitId) async {
    try {
      final docRef = _firestore.collection("pengajuan_sakit").doc(sakitId);
      final doc = await docRef.get();

      if (!doc.exists) throw Exception("Pengajuan sakit tidak ditemukan.");

      final data = doc.data();
      final storagePath = data?['storagePath'] as String?;

      if (storagePath != null && storagePath.isNotEmpty) {
        final ref = _storage.ref().child(storagePath);
        await ref.delete();
        debugPrint("Lampiran berhasil dihapus: $storagePath");
      }

      await docRef.delete();
      debugPrint("Dokumen sakit $sakitId berhasil dihapus");
    } catch (e) {
      debugPrint("Error hapusPengajuan Sakit: $e");
      rethrow;
    }
  }
}
