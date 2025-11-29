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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Sanitasi nama file agar aman
    final cleanFileName = fileName.replaceAll(" ", "_");

    final storagePath = 'sakit_lampiran/$userId/${timestamp}_$cleanFileName';
    final ref = _storage.ref().child(storagePath);

    try {
      final metadata = SettableMetadata(
        contentType: "image/jpeg",
      );

      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      return {
        'lampiranUrl': url,
        'storagePath': storagePath,
      };
    } on FirebaseException catch (e) {
      debugPrint("Firebase Storage Upload Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  /// Kirim pengajuan sakit ke Firestore
  Future<void> kirimPengajuan({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String keterangan,
    required Uint8List lampiranBytes,
    required String fileName,
  }) async {
    try {
      final uploadResult = await uploadLampiran(
        bytes: lampiranBytes,
        fileName: fileName,
        userId: userId,
      );

      await _firestore.collection("pengajuan_sakit").add({
        "userId": userId,
        "tanggalMulai": Timestamp.fromDate(startDate),
        "tanggalSelesai": Timestamp.fromDate(endDate),
        "keterangan": keterangan,
        "lampiranUrl": uploadResult['lampiranUrl'],
        "storagePath":
            uploadResult['storagePath'],
        "status": "Diajukan",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint("Firebase Kirim Pengajuan Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("General Error in kirimPengajuan: $e");
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
}
