import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class CutiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload lampiran cuti ke Firebase Storage (jika ada)
  Future<Map<String, String>> uploadLampiran({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(" ", "_");

    final storagePath = 'cuti_lampiran/$userId/${timestamp}_$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    // Tentukan content type berdasarkan ekstensi file
    String ext = fileName.split(".").last.toLowerCase();
    String contentType = "application/octet-stream";

    final contentTypes = {
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "png": "image/png",
      "pdf": "application/pdf",
      "doc": "application/msword",
      "docx":
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    };

    contentType = contentTypes[ext] ?? "application/octet-stream";

    final metadata = SettableMetadata(contentType: contentType);

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return {
      'lampiranUrl': url,
      'storagePath': storagePath,
    };
  }

  /// Kirim pengajuan cuti ke Firestore
  Future<void> kirimPengajuan({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String alasan,
    String? keterangan,
    Uint8List? lampiranBytes,
    String? fileName,
    DateTime? tanggalVerifikasi,
    required num? sisaCutiSaatPengajuan,
  }) async {
    try {
      // Ambil profile user
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final userName = userDoc.data()?["user_name"] ?? "-";
      final userRole = userDoc.data()?["user_role"] ?? "-";
      final userEmail = userDoc.data()?["user_email"] ?? "-";

      String? lampiranUrl;
      String? storagePath;

      // Upload lampiran hanya jika ada file
      if (lampiranBytes != null && fileName != null) {
        final uploadResult = await uploadLampiran(
          bytes: lampiranBytes,
          fileName: fileName,
          userId: userId,
        );
        lampiranUrl = uploadResult['lampiran_url'];
        storagePath = uploadResult['storage_path'];
      }

      // Simpan pengajuan cuti ke Firestore
      await _firestore.collection("pengajuan_cuti").add({
        "user_id": userId,
        "user_name": userName,
        "user_email": userEmail,
        "user_role": userRole,
        "tanggal_mulai": Timestamp.fromDate(startDate),
        "tanggal_selesai": Timestamp.fromDate(endDate),
        "alasan": alasan,
        "lampiran_url": lampiranUrl,
        "storage_path": storagePath,
        "status": "Diajukan",
        "keterangan": keterangan,
        "sisa_cuti": sisaCutiSaatPengajuan,
        "created_at": FieldValue.serverTimestamp(),
        "tanggal_verifikasi": tanggalVerifikasi,
      });
    } catch (e) {
      debugPrint("Error kirimPengajuan Cuti: $e");
      rethrow;
    }
  }

  /// Ambil rekapan cuti berdasarkan user login
  Stream<QuerySnapshot> getRekapanCuti(String uid) {
    return _firestore
        .collection("pengajuan_cuti")
        .where("user_id", isEqualTo: uid)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  /// Hapus pengajuan cuti dari Firestore dan lampiran dari Storage
  Future<void> hapusPengajuanCuti(String cutiId) async {
    try {
      final cutiDocRef = _firestore.collection('pengajuan_cuti').doc(cutiId);
      final cutiDoc = await cutiDocRef.get();

      if (!cutiDoc.exists) {
        throw Exception("Dokumen cuti tidak ditemukan.");
      }

      final data = cutiDoc.data() ?? {};
      String? storagePath;
      if (data.containsKey('storage_path')) {
        storagePath = data['storage_path'] as String?;
      } else if (data.containsKey('storagePath')) {
        storagePath = data['storagePath'] as String?;
      }

      // 1. Hapus Lampiran dari Firebase Storage (jika ada)
      if (storagePath != null && storagePath.isNotEmpty) {
        final ref = _storage.ref().child(storagePath);
        await ref.delete();
        debugPrint("Lampiran berhasil dihapus dari Storage: $storagePath");
      }

      // 2. Hapus Dokumen dari Firestore
      await cutiDocRef.delete();
      debugPrint("Dokumen cuti $cutiId berhasil dihapus.");
    } on FirebaseException catch (e) {
      // Menangani error spesifik Firebase (misal: permission denied, file not found)
      debugPrint("Firebase Error saat menghapus pengajuan cuti: $e");
      rethrow;
    } catch (e) {
      debugPrint("General Error saat menghapus pengajuan cuti: $e");
      rethrow;
    }
  }
}
