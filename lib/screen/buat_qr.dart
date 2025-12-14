import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuatQRPage extends StatefulWidget {
  const BuatQRPage({super.key});

  @override
  State<BuatQRPage> createState() => _BuatQRPageState();
}

class _BuatQRPageState extends State<BuatQRPage> {
  String qrData = "";
  Timer? timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _refreshQR();

    timer = Timer.periodic(const Duration(seconds: 10), (t) => _refreshQR());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ======================================================
  // CEK WAKTU ABSENSI (07.00 - 17.00)
  bool _isWithinTimeRange() {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, now.day, 7, 0);
    final end = DateTime(now.year, now.month, now.day, 17, 0);

    return now.isAfter(start) && now.isBefore(end);
  }

  // ======================================================
  // TOKEN UNIK ANTI-CHEAT
  String _generateToken(int length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final rand = Random.secure();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  // ======================================================
  // GENERATE QR DENGAN EXPIRED TIME (10 DETIK)
  Future<void> _refreshQR() async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(seconds: 20));
      final token = _generateToken(16);

      // SIMPAN TOKEN KE FIRESTORE (BELUM DIPAKAI)
      await _firestore.collection('qr_tokens').doc(token).set({
        'used': false,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(expiresAt),
      });

      final newQR = jsonEncode({
        'token': token,
        'exp': expiresAt.toIso8601String(),
      });

      setState(() {
        qrData = newQR;
      });
    } catch (e) {
      debugPrint("ERROR GENERATE QR: $e");
    }
  }

  // ======================================================
  // HEADER UI
  Widget _buildHeader() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFF36546C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "QR Absensi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  @override
  Widget build(BuildContext context) {
    if (!_isWithinTimeRange()) {
      return _errorScreen("Di luar jam absensi (07.00 - 17.00)");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double qrSize = constraints.maxWidth * 0.75;
                qrSize = qrSize.clamp(260, 360);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          "Tanggal : ${DateFormat('dd-MM-yyyy').format(DateTime.now())}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: qrData.isEmpty
                              ? const CircularProgressIndicator()
                              : QrImageView(
                                  data: qrData,
                                  size: qrSize,
                                  version: QrVersions.auto,
                                  gapless: false,
                                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                                  backgroundColor: Colors.white,
                                ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Waktu : ${DateFormat('HH:mm:ss').format(DateTime.now())}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ERROR SCREEN
  Widget _errorScreen(String text) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          "!",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
