import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../users/rekapan/kehadiran_rekapan_user_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessingScan = false;

  bool _isWithinTimeRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 7, 0);
    final end = DateTime(now.year, now.month, now.day, 17, 0);
    return now.isAfter(start) && now.isBefore(end);
  }

  /// AMBIL DATA USER DARI COLLECTION USERS
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          'user_name': data['user_name'],
          'user_email': data['user_email'],
          'user_role': data['user_role'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  final MobileScannerController _scannerController =
      MobileScannerController(autoStart: true);

  void stopScanner() {
    _scannerController.stop();
  }

  Future<void> _processQR(String qrText) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    try {
      final now = DateTime.now();

      // --- VALIDASI WAKTU ---
      if (!_isWithinTimeRange()) throw "DI_LUAR_JAM";

      // --- PARSE QR ---
      final data = jsonDecode(qrText);
      final token = data['token'];
      if (token == null) throw "QR_TIDAK_VALID";

      // --- AUTH USER ---
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "BELUM_LOGIN";

      final userId = user.uid;
      final tokenRef = _firestore.collection('qr_tokens').doc(token);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(tokenRef);
        if (!snap.exists) throw "TOKEN_TIDAK_ADA";

        final tokenData = snap.data()!;
        final expiresAt = (tokenData['expires_at'] as Timestamp).toDate();
        final used = tokenData['used'] ?? false;

        if (DateTime.now().isAfter(expiresAt)) {
          tx.delete(tokenRef);
          throw "TOKEN_EXPIRED";
        }
        if (used) throw "TOKEN_SUDAH_DIPAKAI";

        // --- LOCK 1 ABSENSI/HARI ---
        final dateKey =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final absensiDocId = "${userId}_$dateKey";
        final absensiRef = _firestore.collection('absensi').doc(absensiDocId);
        final absensiSnap = await tx.get(absensiRef);

        final hasCheckIn = absensiSnap.exists &&
            (absensiSnap.data()?['check_in'] ?? '').isNotEmpty;
        final hasCheckOut = absensiSnap.exists &&
            (absensiSnap.data()?['check_out'] ?? '').isNotEmpty;
        if (hasCheckIn && hasCheckOut) throw "SUDAH_ABSEN_HARI_INI";

        // --- KUNCI TOKEN ---
        tx.update(tokenRef, {
          'used': true,
          'used_by': userId,
          'used_at': FieldValue.serverTimestamp(),
        });

        // --- AMBIL DATA USER ---
        final userData = await _getUserData(userId);
        if (userData == null) throw "DATA_USER_TIDAK_DITEMUKAN";

        final timeNow =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        // --- ABSENSI ---
        if (!hasCheckIn) {
          // check-in berhasil
          tx.set(
              absensiRef,
              {
                "user_id": userId,
                "user_name": userData['user_name'],
                "user_email": userData['user_email'],
                "user_role": userData['user_role'],
                "check_in": timeNow,
                "check_in_at": FieldValue.serverTimestamp(),
                "status": "Proses",
                "created_at": FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          // Tampilkan pesan berhasil hanya untuk check-in
          _showMessage("Check in berhasil!", goToKehadiran: true);
        } else {
          // check-out
          final checkInAt = absensiSnap.data()?['check_in_at'] as Timestamp?;
          if (checkInAt == null) throw "CHECK_IN_TIDAK_DITEMUKAN";

          final checkInTime = checkInAt.toDate();
          final diffMinutes = now.difference(checkInTime).inMinutes;

          if (diffMinutes < 10) {
            throw "CHECK_OUT_TERLALU_DINI"; // belum 10 menit
          }

          // check-out berhasil
          tx.update(absensiRef, {
            "check_out": timeNow,
            "status": "Hadir",
            "updated_at": FieldValue.serverTimestamp(),
          });

          _showMessage("Absensi berhasil!", goToKehadiran: true);
        }
      });
    } catch (e) {
      debugPrint("QR ERROR: $e");

      final errorMap = {
        "DI_LUAR_JAM": "Di luar jam absensi (07.00 - 17.00)",
        "QR_TIDAK_VALID": "QR tidak valid",
        "BELUM_LOGIN": "User belum login",
        "TOKEN_TIDAK_ADA": "Token QR tidak ditemukan",
        "TOKEN_SUDAH_DIPAKAI": "QR sudah digunakan",
        "TOKEN_EXPIRED": "QR sudah kedaluwarsa",
        "SUDAH_ABSEN_HARI_INI": "Anda sudah absensi hari ini",
        "DATA_USER_TIDAK_DITEMUKAN": "Data user tidak ditemukan",
        "CHECK_OUT_TERLALU_DINI":
            "Anda baru saja Check in, Silakan tunggu beberapa saat untuk checkout",
      };

      _showMessage(errorMap[e] ?? "Terjadi kesalahan saat absensi");
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isProcessingScan = false;
      });
    }
  }

  void _showMessage(String text, {bool goToKehadiran = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );

    if (goToKehadiran) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KehadiranPage()),
      );
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final rawValue = capture.barcodes.first.rawValue;
              if (rawValue == null) return;

              _processQR(rawValue);
            },
          ),
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Scan QR Code",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Pindai Kode QR untuk Absensi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Batal",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
