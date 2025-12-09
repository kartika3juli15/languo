import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/user_model.dart';
import '../profile/profile_page.dart';
import '../screen/qr_scanner_screen.dart';
import '../screen/maps.dart';
import 'package:languo/users/rekapan/kehadiran_rekapan_user_page.dart';
import 'package:languo/users/pengajuan/cuti_pengajuan_page.dart';
import 'package:languo/users/pengajuan/izin_pengajuan_page.dart';
import 'package:languo/users/pengajuan/sakit_pengajuan_page.dart';
import '../admin/home_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomePageUser extends StatefulWidget {
  const HomePageUser({super.key});

  @override
  State<HomePageUser> createState() => _HomePageUserState();
}

class _HomePageUserState extends State<HomePageUser> {
  String? _lastScannedData;
  bool _localeReady = false;
  
  // Data untuk statistik
  int _totalHadir = 0;
  int _totalProses = 0;
  int _totalCuti = 0;
  int _totalIzin = 0;
  int _totalSakit = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        setState(() => _localeReady = true);
      }
    });

    _redirectIfAdmin();
    _loadStatistics();
  }

  Future<void> _redirectIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final role = doc['user_role'];

    if (!mounted) return;

    if (role == "Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeAdmin()),
      );
    }
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
      return;
    }

    try {
      // Get Kehadiran - ambil semua data absensi
      final hadirSnapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Hitung kehadiran yang sudah selesai (check_in dan check_out ada)
      // dan yang masih proses (check_in ada tapi check_out kosong)
      int hadirCount = 0;
      int prosesCount = 0;
      
      for (var doc in hadirSnapshot.docs) {
        final data = doc.data();
        final checkIn = data['check_in'] ?? '';
        final checkOut = data['check_out'] ?? '';
        
        if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
          // Sudah check out (kehadiran selesai)
          hadirCount++;
        } else if (checkIn.isNotEmpty && checkOut.isEmpty) {
          // Sudah check in tapi belum check out (proses)
          prosesCount++;
        }
      }

      // Get Cuti yang disetujui
      final cutiSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_cuti')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Disetujui')
          .get();

      // Get Izin yang disetujui
      final izinSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_izin')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Disetujui')
          .get();

      // Get Sakit yang disetujui
      final sakitSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_sakit')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Disetujui')
          .get();

      if (mounted) {
        setState(() {
          _totalHadir = hadirCount;
          _totalProses = prosesCount;
          _totalCuti = cutiSnapshot.docs.length;
          _totalIzin = izinSnapshot.docs.length;
          _totalSakit = sakitSnapshot.docs.length;
          _isLoadingStats = false;
        });

        // Debug print
        print('=== STATISTIK KEHADIRAN ===');
        print('Total Hadir (Selesai): $hadirCount');
        print('Total Proses (Belum Check Out): $prosesCount');
        print('Total Cuti: ${cutiSnapshot.docs.length}');
        print('Total Izin: ${izinSnapshot.docs.length}');
        print('Total Sakit: ${sakitSnapshot.docs.length}');
        print('========================');
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
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
              const SizedBox(height: 30),
              _buildAktivitasChart(),
              const SizedBox(height: 30),
              _buildDetailSection(),
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
                      "HALO!",
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
                    backgroundImage:
                        (user.userPhoto != null && user.userPhoto!.isNotEmpty)
                            ? NetworkImage(user.userPhoto!)
                            : null,
                    child: (user.userPhoto == null || user.userPhoto!.isEmpty)
                        ? Icon(Icons.person, color: Colors.grey[600], size: 32)
                        : null,
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
        _menuButton(Icons.accessibility_new, "Hadir", Color(0xFF5B7C99), () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KehadiranPage()),
          );
          // Refresh data setelah kembali dari halaman Hadir
          _loadStatistics();
        }),
        _menuButton(Icons.list_alt, "Izin", Color(0xFF5B7C99), () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanIzinPage()),
          );
          // Refresh data setelah kembali dari halaman Izin
          _loadStatistics();
        }),
        _menuButton(Icons.medical_services, "Sakit", Color(0xFF5B7C99), () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanSakitPage()),
          );
          // Refresh data setelah kembali dari halaman Sakit
          _loadStatistics();
        }),
        _menuButton(Icons.watch_later, "Cuti", Color(0xFF5B7C99), () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengajuanCutiPage()),
          );
          // Refresh data setelah kembali dari halaman Cuti
          _loadStatistics();
        }),
      ],
    );
  }

  Widget _menuButton(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Schedule Card =====================
  Widget _buildScheduleCard() {
    if (!_localeReady) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('EEE, d MMM yyyy', 'id_ID').format(now);

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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "08:00 - 18:00",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapsPage()),
                  );
                },
                icon: Icon(Icons.location_on, size: 20),
                label: Text(
                  "Cek lokasi",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD1644A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 48),
                  elevation: 0,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 280,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: _isLoadingStats
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF36546C),
                    ),
                  )
                : Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          hadir: _totalHadir,
                          izin: _totalIzin,
                          sakit: _totalSakit,
                          cuti: _totalCuti,
                          proses: _totalProses,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ===================== Detail Section =====================
  Widget _buildDetailSection() {
    final total = _totalHadir + _totalIzin + _totalSakit + _totalCuti + _totalProses;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Detail",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailBar(
            title: "Hadir",
            count: _totalHadir,
            total: total,
            color: Color(0xFF5BA3D0),
          ),
          const SizedBox(height: 12),
          _buildDetailBar(
            title: "Proses (belum check-out)",
            count: _totalProses,
            total: total,
            color: Color(0xFFF5A623),
          ),
          const SizedBox(height: 12),
          _buildDetailBar(
            title: "Izin",
            count: _totalIzin,
            total: total,
            color: Color(0xFFF8E71C),
          ),
          const SizedBox(height: 12),
          _buildDetailBar(
            title: "Sakit",
            count: _totalSakit,
            total: total,
            color: Color(0xFF7ED321),
          ),
          const SizedBox(height: 12),
          _buildDetailBar(
            title: "Cuti",
            count: _totalCuti,
            total: total,
            color: Color(0xFF9B59B6),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBar({
    required String title,
    required int count,
    required int total,
    required Color color,
  }) {
    final value = total > 0 ? (count / total) : 0.0;
    final percentage = (value * 100).toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              "$percentage%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final int hadir;
  final int izin;
  final int sakit;
  final int cuti;
  final int proses;

  DonutChartPainter({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.cuti,
    required this.proses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.butt;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 60) / 2;

    final total = hadir + izin + sakit + cuti + proses;
    if (total == 0) {
      paint.color = Colors.grey[300]!;
      canvas.drawCircle(center, radius, paint);
      
      final textPainterEmpty = TextPainter(
        text: const TextSpan(
          text: 'Tidak ada data',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainterEmpty.layout();
      textPainterEmpty.paint(
        canvas,
        Offset(
          center.dx - textPainterEmpty.width / 2,
          center.dy - textPainterEmpty.height / 2,
        ),
      );
      return;
    }

    final values = [
      hadir / total,
      proses / total,
      izin / total,
      sakit / total,
      cuti / total,
    ];

    final colors = [
      Color(0xFF5BA3D0), // Biru untuk Hadir
      Color(0xFFF5A623), // Orange untuk Proses
      Color(0xFFF8E71C), // Kuning untuk Izin
      Color(0xFF7ED321), // Hijau untuk Sakit
      Color(0xFF9B59B6), // Ungu untuk Cuti
    ];

    final labels = ['Hadir', 'Proses', 'Izin', 'Sakit', 'Cuti'];
    final counts = [hadir, proses, izin, sakit, cuti];

    double startAngle = -90 * (3.14159 / 180);

    // Draw arcs
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        paint.color = colors[i];
        final sweepAngle = values[i] * 2 * 3.14159;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );

        // Calculate position for label (middle of the arc, outside)
        final middleAngle = startAngle + (sweepAngle / 2);
        final labelRadius = radius + 35; // Distance from center for labels
        final labelX = center.dx + labelRadius * cos(middleAngle);
        final labelY = center.dy + labelRadius * sin(middleAngle);

        // Draw label text
        final textPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();

        // Draw percentage
        final percentage = (values[i] * 100).toStringAsFixed(1);
        final percentPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        percentPainter.layout();

        // Position text based on angle
        double textX = labelX - textPainter.width / 2;
        double textY = labelY - textPainter.height / 2;

        // Adjust for better positioning on sides
        if (middleAngle > -1.5708 && middleAngle < 1.5708) {
          // Right side
          textX = labelX;
        } else {
          // Left side
          textX = labelX - textPainter.width;
        }

        textPainter.paint(canvas, Offset(textX, textY - 8));
        percentPainter.paint(
          canvas,
          Offset(textX + (textPainter.width - percentPainter.width) / 2, textY + 6),
        );

        startAngle += sweepAngle;
      }
    }
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      hadir != oldDelegate.hadir ||
      izin != oldDelegate.izin ||
      sakit != oldDelegate.sakit ||
      cuti != oldDelegate.cuti ||
      proses != oldDelegate.proses;
}
