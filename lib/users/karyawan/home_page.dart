import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../profile/profile_page.dart';
import '../../screen/qr_scanner_screen.dart';
import '../../screen/employee_detail_screen.dart';
import 'package:languo/users/rekapan/kehadiran_page.dart';
import 'package:languo/users/pengajuan/cuti_page.dart';
import 'package:languo/users/pengajuan/izin_page.dart';
import 'package:languo/users/pengajuan/sakit_page.dart';
import 'package:languo/users/rekapan/izin_page.dart';
import '../dosen/home_page.dart';
import '../../admin/home_page.dart';

class HomeKaryawan extends StatefulWidget {
  const HomeKaryawan({super.key});

  @override
  State<HomeKaryawan> createState() => _HomeKaryawanState();
}

class _HomeKaryawanState extends State<HomeKaryawan> {
  String? _lastScannedData;

  Future<void> checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final role = doc.data()?['user_role']; // Ambil role

    if (!mounted) return;

    if (role != "Karyawan") {
      if (role == "Dosen") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDosen()),
        );
      } else if (role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeAdmin()),
        );
      }
    }
  }

  Future<UserModel?> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildScheduleCard(),
              const SizedBox(height: 20),
              if (_lastScannedData != null) _buildScanResultInfo(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildMenuButtons(),
              ),
              const SizedBox(height: 40),
              _buildAktivitasChart(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Detail",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              _buildDetailBar(
                  title: "Tepat Waktu", value: 0.655, color: Color(0xFF2196F3)),
              _buildDetailBar(
                  title: "Terlambat", value: 0.165, color: Color(0xFFFFA500)),
              _buildDetailBar(
                  title: "Izin", value: 0.062, color: Color(0xFFFFD700)),
              _buildDetailBar(
                  title: "Sakit", value: 0.125, color: Color(0xFF4CAF50)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Scan Result =====================
  Widget _buildScanResultInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scan Berhasil",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _lastScannedData ?? "",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () {
                if (!mounted) return;
                setState(() => _lastScannedData = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Bottom Nav =====================
  Widget _buildBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _bottomItem(Icons.home, "Beranda", true, () {}),
              SizedBox(width: 80),
              _bottomItem(Icons.person_outline, "Profile", false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              }),
            ],
          ),
        ),

        // Floating QR Button
        Positioned(
          top: -20,
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScannerPage()),
              );
              if (!mounted) return;
              if (result != null) {
                setState(() {
                  _lastScannedData = result;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("QR Code berhasil dipindai!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xFF36546C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child:
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomItem(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? Color(0xFF36546C) : Colors.grey[400],
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Color(0xFF36546C) : Colors.grey[400],
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Header =====================
  Widget _buildHeader() {
    return FutureBuilder<UserModel?>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 50),
            child: Text("Loading...",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            decoration: const BoxDecoration(
              color: Color(0xFF36546C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          );
        }

        final user = snapshot.data!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 50),
          decoration: const BoxDecoration(
            color: Color(0xFF36546C),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HALLO!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.userRole,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                    child:
                        Icon(Icons.person, color: Colors.grey[600], size: 32),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== Menu Buttons =====================
  Widget _buildMenuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // HADIR
        _menuButton(Icons.person, "Hadir", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KehadiranPage()),
          );
        }),

        // ========== IZIN (FIXED) ==========
        _menuButton(Icons.description, "Izin", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanIzinPage()),
          );
        }),

        // SAKIT
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengajuanSakitPage()),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF36546C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.medical_services,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              const Text("Sakit", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),

        // CUTI
        _menuButton(Icons.schedule, "Cuti", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanCutiPage()),
          );
        }),
      ],
    );
  }

  Widget _menuButton(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFF36546C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ===================== Schedule Card =====================
  Widget _buildScheduleCard() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Kelas Mandarin",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  Text(
                    "Sen, 1 Nov 2025",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "08:00 - 18:00",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployeeDetailScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE75636),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 48),
                  elevation: 0,
                ),
                child: Text(
                  "Detail",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Aktivitas Chart =====================
  Widget _buildAktivitasChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aktivitas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                size: Size(160, 160),
                painter: DonutChartPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Detail Bar =====================
  Widget _buildDetailBar({
    required String title,
    required double value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Spacer(),
              Text(
                "${(value * 100).toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 60.0;
    final strokeWidth = 20.0;

    paint.strokeWidth = strokeWidth;
    paint.strokeCap = StrokeCap.round;

    final values = [0.655, 0.165, 0.062, 0.125];
    final colors = [
      Color(0xFF2196F3),
      Color(0xFFFFA500),
      Color(0xFFFFD700),
      Color(0xFF4CAF50),
    ];

    double startAngle = -90 * (3.14159 / 180);

    for (int i = 0; i < values.length; i++) {
      paint.color = colors[i];
      final sweepAngle = values[i] * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - strokeWidth + 2, innerPaint);
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => false;
}
