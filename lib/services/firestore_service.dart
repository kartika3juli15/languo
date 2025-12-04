import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/absensi_model.dart';
import '../models/user_model.dart';
import '../models/qr_code_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================================
  // FUNGSI ABSENSI
  // ==========================================================

  Future<void> recordAbsensi(String scannedUserUid) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Operator tidak terautentikasi.');
    }

    // Waktu datang
    final now = DateTime.now();

    // Jam keluar otomatis 18:00
    final checkOutTargetTime = DateTime(
      now.year,
      now.month,
      now.day,
      18,
      0,
      0,
    );

    // Buat dokumen AbsensiModel
    final newDoc = _db.collection("absensi").doc(); // auto generate ID

    final absensiData = AbsensiModel(
      uid: newDoc.id, // document ID Firestore
      userId: scannedUserUid, // UID Users
      operatorUid: currentUser.uid, // UID operator
      checkInTime: now, // jam masuk sekarang
      checkOutTime: checkOutTargetTime, // jam pulang otomatis
      status: "check_in",
      absensiStatus: "valid",
    );

    try {
      await newDoc.set(absensiData.toMap());
      print("Absensi berhasil dicatat: ${newDoc.id}");
    } catch (e) {
      throw Exception("Gagal mencatat absensi: $e");
    }
  }

  // GET ABSENSI HARI INI untuk user tertentu
  Future<AbsensiModel?> getTodayAbsensi(String userUid) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final query = await _db
          .collection('absensi')
          .where('user_id', isEqualTo: userUid)
          .where('check_in_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('check_in_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return AbsensiModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting today absensi: $e');
      return null;
    }
  }

  // ==========================================================
  // FUNGSI USERS
  // ==========================================================

  Future<void> saveUserData(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['user_role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<UserModel?> getUserDataByUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data by uid: $e');
      return null;
    }
  }

  // ==========================================================
  // FUNGSI QR CODE
  // ==========================================================

  Future<QRCodeModel?> verifyQRCodeValue(String qrValue) async {
    try {
      final doc = await _db.collection('qr_code').doc(qrValue).get();

      if (doc.exists) {
        return QRCodeModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error verifying QR Code: $e');
      return null;
    }
  }
}
