import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class IzinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, String>> uploadLampiran({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(" ", "_");

    final storagePath = 'izin_lampiran/$userId/${timestamp}_$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    String ext = fileName.split(".").last.toLowerCase();
    String contentType = {
          "jpg": "image/jpeg",
          "jpeg": "image/jpeg",
          "png": "image/png",
          "pdf": "application/pdf",
          "doc": "application/msword",
          "docx":
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        }[ext] ??
        "application/octet-stream";

    final metadata = SettableMetadata(contentType: contentType);

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return {
      "lampiran_url": url,
      "storage_path": storagePath,
    };
  }

  /// Kirim pengajuan izin ke Firestore
  Future<void> kirimPengajuan({
    required String userId,
    required String perihal,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required Uint8List lampiranBytes,
    required String fileName,
    String? keterangan,
    DateTime? tanggalVerifikasi,
  }) async {
    try {
      // Ambil data user
      final userDoc = await _firestore.collection("users").doc(userId).get();

      final userName = userDoc.data()?["user_name"] ?? "-";
      final userRole = userDoc.data()?["user_role"] ?? "-";
      final userEmail = userDoc.data()?["user_email"] ?? "-";

      // Upload lampiran
      final uploadResult = await uploadLampiran(
        bytes: lampiranBytes,
        fileName: fileName,
        userId: userId,
      );

      // Simpan ke Firestore
      await _firestore.collection("pengajuan_izin").add({
        "user_id": userId,
        "user_name": userName,
        "user_role": userRole,
        "user_email": userEmail,
        "perihal": perihal,
        "tanggal_mulai": Timestamp.fromDate(tanggalMulai),
        "tanggal_selesai": Timestamp.fromDate(tanggalSelesai),
        "keterangan": keterangan,
        "lampiran_url": uploadResult["lampiran_url"],
        "storage_path": uploadResult["storage_path"],
        "status": "Diajukan",
        "created_at": FieldValue.serverTimestamp(),
        "tanggal_verifikasi": tanggalVerifikasi,
      });
    } catch (e) {
      debugPrint("Error kirim pengajuan izin: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getRekapanIzin(String uid) {
    return _firestore
        .collection("pengajuan_izin")
        .where("user_id", isEqualTo: uid)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  Future<void> hapusPengajuanIzin(String izinId) async {
    try {
      final izinDocRef = _firestore.collection("pengajuan_izin").doc(izinId);
      final izinDoc = await izinDocRef.get();

      if (!izinDoc.exists) throw Exception("Dokumen izin tidak ditemukan.");

      final storagePath = izinDoc.data()?["storage_path"];
      if (storagePath != null && storagePath.isNotEmpty) {
        await _storage.ref().child(storagePath).delete();
      }

      await izinDocRef.delete();
    } catch (e) {
      debugPrint("Error hapus pengajuan izin: $e");
      rethrow;
    }
  }
}
