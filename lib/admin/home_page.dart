import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:languo/screen/buat_qr.dart';
import 'package:languo/admin/pengajuan/sakit_pengajuan_role_page.dart';
import 'package:languo/admin/pengajuan/cuti_pengajuan_role_page.dart';
import 'package:languo/admin/pengajuan/izin_pengajuan_role_page.dart';
import '../models/user_model.dart';
import '../models/absensi_model.dart';
import '../models/pengajuan_cuti_model.dart';
import '../models/pengajuan_izin_model.dart';
import '../models/pengajuan_sakit_model.dart';
import '../profile/profile_page.dart';
import 'rekapan/kehadiran_rekapan_admin_page.dart';
import 'package:intl/intl.dart';
import 'package:languo/admin/user_management_page.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class StatistikItem {
  final String label;
  final int value;
  final Color color;

  StatistikItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _HomeAdminState extends State<HomeAdmin> {
  String? _lastScannedData;
  Map<String, int> _statistikData = {
    'izin': 0,
    'sakit': 0,
    'cuti': 0,
    'kehadiran': 0,
  };
  bool _isLoadingStats = true;
  String _selectedRole = 'semua';
  String _selectedHoverLabel = 'Total';

  @override
  void initState() {
    super.initState();
    _loadStatistikData();
  }

  List<StatistikItem> get _statistikItems {
    return [
      StatistikItem(
        label: 'Kehadiran',
        value: _statistikData['kehadiran'] ?? 0,
        color: const Color(0xFF5B9BD5),
      ),
      StatistikItem(
        label: 'Izin',
        value: _statistikData['izin'] ?? 0,
        color: const Color(0xFFFFD966),
      ),
      StatistikItem(
        label: 'Sakit',
        value: _statistikData['sakit'] ?? 0,
        color: const Color(0xFF4CAF50),
      ),
      StatistikItem(
        label: 'Cuti',
        value: _statistikData['cuti'] ?? 0,
        color: const Color(0xFFE75636),
      ),
    ];
  }

  Future<void> _loadStatistikData() async {
    setState(() => _isLoadingStats = true);

    try {
      int kehadiran = 0;
      int izin = 0;
      int sakit = 0;
      int cuti = 0;

      // Ambil semua user sesuai role
      Query usersRef = FirebaseFirestore.instance.collection('users');

      if (_selectedRole == 'dosen' || _selectedRole == 'karyawan') {
        usersRef = usersRef.where('user_role',
            isEqualTo: firestoreRole(_selectedRole));
      } else if (_selectedRole == 'semua') {
        usersRef = usersRef.where('user_role', whereIn: ['Dosen', 'Karyawan']);
      }

      final userQuery = await usersRef.get();

      final Map<String, UserModel> usersMap = {
        for (var doc in userQuery.docs)
          doc.id.toString(): UserModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>),
      };

      final now = DateTime.now();
      final todayStart =
          Timestamp.fromDate(DateTime(now.year, now.month, now.day, 0, 0));
      final todayEnd = Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 23, 59, 59));

      // Ambil absensi hari ini
      final absensiSnapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('check_in_time', isGreaterThanOrEqualTo: todayStart)
          .where('check_in_time', isLessThanOrEqualTo: todayEnd)
          .get();

      for (var doc in absensiSnapshot.docs) {
        final absensi = AbsensiModel.fromMap(doc.data(), doc.id);
        final userIdStr = absensi.userId.toString();
        if (!usersMap.containsKey(userIdStr)) continue;

        kehadiran++;
      }

      // Ambil pengajuan izin, sakit, cuti yang disetujui
      final izinSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_izin')
          .where('status', isEqualTo: 'Disetujui')
          .get();
      for (var doc in izinSnapshot.docs) {
        final izinModel = PengajuanIzinModel.fromFirestore(doc);
        if (usersMap.containsKey(izinModel.userId.toString())) izin++;
      }

      final sakitSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_sakit')
          .where('status', isEqualTo: 'Disetujui')
          .get();
      for (var doc in sakitSnapshot.docs) {
        final sakitModel = PengajuanSakitModel.fromFirestore(doc);
        if (usersMap.containsKey(sakitModel.userId.toString())) sakit++;
      }

      final cutiSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_cuti')
          .where('status', isEqualTo: 'Disetujui')
          .get();
      for (var doc in cutiSnapshot.docs) {
        try {
          final cutiModel = PengajuanCutiModel.fromFirestore(doc);
          if (usersMap.containsKey(cutiModel.userId.toString())) cuti++;
        } catch (e) {
          debugPrint('Skip cuti document ${doc.id} karena error: $e');
        }
      }

      setState(() {
        _statistikData = {
          'izin': izin,
          'sakit': sakit,
          'cuti': cuti,
          'kehadiran': kehadiran,
        };
        _isLoadingStats = false;
      });
    } catch (e, st) {
      debugPrint('Error load statistik: $e\n$st');
      setState(() => _isLoadingStats = false);
    }
  }

  String firestoreRole(String role) {
    switch (role) {
      case 'dosen':
        return 'Dosen';
      case 'karyawan':
        return 'Karyawan';
      default:
        return ''; // fallback
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
    // Kode UI sama persis dengan HomeAdmin Anda, tidak perlu diubah
    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistikData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Detail",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailSection(),
                const SizedBox(height: 20),
              ],
            ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
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
              icon: const Icon(Icons.close, size: 20),
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
              const SizedBox(width: 80),
              _bottomItem(Icons.person_outline, "Profile", false, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              }),
            ],
          ),
        ),
        Positioned(
          top: -20,
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BuatQRPage()),
              );
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF36546C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 38),
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
            color: active ? const Color(0xFF36546C) : Colors.grey[400],
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF36546C) : Colors.grey[400],
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
        final user = snapshot.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
          decoration: const BoxDecoration(
            color: Color(0xFF36546C),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("HAI!",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      user?.userName ?? "-",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.userRole ?? "-",
                      style: const TextStyle(
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
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        (user?.userPhoto != null && user!.userPhoto!.isNotEmpty)
                            ? NetworkImage(user.userPhoto!)
                            : null,
                    child: (user?.userPhoto == null || user!.userPhoto!.isEmpty)
                        ? Icon(Icons.person, color: Colors.grey[600], size: 32)
                        : null,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ===================== Menu Buttons =====================
  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFFE3E3E3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _menuItem(Icons.accessibility_new, "Hadir", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminKehadiranPage()),
              );
            }),
            _menuItem(Icons.list_alt, "Izin", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PengajuanIzinPage()),
              );
            }),
            _menuItem(Icons.medical_services, "Sakit", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSakitPage()),
              );
            }),
            _menuItem(Icons.schedule, "Cuti", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PengajuanCutiPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFF2C6E91),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
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
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "07:00 - 17:00",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserManagementPage()),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  "Manajemen User",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE75636),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                  elevation: 0,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Chart =====================
  // =====================================================================
// HELPER METHODS
// =====================================================================

// Helper untuk menghitung persentase item yang sedang di-hover
  String _getHoverPercentage(String label, Map<String, int> data) {
    // Mapping label ke kunci data
    final keyMap = {
      'Kehadiran': 'kehadiran',
      'Izin': 'izin',
      'Sakit': 'sakit',
      'Cuti': 'cuti'
    };
    final key = keyMap[label];

    if (key == null) return '0%';

    final total = data.values.reduce((a, b) => a + b);
    if (total == 0) return '0%';

    final value = data[key] ?? 0;
    return '${(value / total * 100).toStringAsFixed(0)}%';
  }

// A. Custom Segmented Button untuk Filter Peran
  Widget _buildRoleFilterButtons(Color selectedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildRoleButton('semua', 'Semua', selectedColor),
        const SizedBox(width: 8),
        _buildRoleButton('dosen', 'Dosen', selectedColor),
        const SizedBox(width: 8),
        _buildRoleButton('karyawan', 'Karyawan', selectedColor),
      ],
    );
  }

  Widget _buildRoleButton(String value, String label, Color selectedColor) {
    final isSelected = _selectedRole == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedRole = value);
        _loadStatistikData();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // Modifikasi pada _buildLegendItem
  Widget _buildLegendItem(StatistikItem item, Color primaryColor) {
    final total = _statistikData.values.reduce((a, b) => a + b);
    final percentage = total == 0 ? 0.0 : (item.value / total);

    // Sekarang hanya bergantung pada _selectedHoverLabel yang disetel oleh TAP
    final isSelected = _selectedHoverLabel == item.label;

    // Hapus MouseRegion. Hanya gunakan InkWell.
    return InkWell(
      onTap: () {
        // Tap berfungsi sebagai toggle:
        // Jika sudah terpilih, kembalikan ke 'Total'. Jika belum, pilih item ini.
        final newLabel = isSelected ? 'Total' : item.label;
        setState(() => _selectedHoverLabel = newLabel);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Gunakan isSelected (berdasarkan Tap) untuk menyorot Legend
          color: isSelected ? item.color.withOpacity(0.15) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? item.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot Warna
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Label & Persentase
            Text(
              '${item.label} (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Chart (Tampilan Utama) =====================
  Widget _buildAktivitasChart() {
    const primaryColor = const Color(0xFF2B3541);
    final totalValue = _statistikData.values.reduce((a, b) => a + b);
    final totalPercentage = totalValue > 0 ? 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Aktivitas keseluruhan",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              if (_isLoadingStats)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRoleFilterButtons(primaryColor),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: _isLoadingStats
                      ? const Center(
                          child: CircularProgressIndicator(color: primaryColor))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Donut Chart DENGAN PROPERTI TAMBAHAN
                            CustomPaint(
                              size: const Size(220, 220),
                              painter: DonutChartPainter(
                                _statistikData, // Map<String, int> data
                                _selectedHoverLabel, // String label yang di-hover/diklik
                                _statistikItems, // List<StatistikItem> untuk warna
                              ),
                            ),
                            // Teks di Tengah Lingkaran
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedHoverLabel == 'Total'
                                      ? "$totalPercentage%"
                                      : _getHoverPercentage(
                                          _selectedHoverLabel, _statistikData),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedHoverLabel, // Label status yang sedang ditampilkan
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _statistikItems.map((item) {
                    return _buildLegendItem(item, primaryColor);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== Detail Bar (Tetap Sederhana) =====================
  Widget _buildDetailBar({
    required String title,
    required double value,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$title ($count)", // Menambahkan count ke judul
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                "${(value * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B3541)),
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

// ===================== Detail Section =====================
  Widget _buildDetailSection() {
    const colorHadir = Color(0xFF5B9BD5);
    const colorIzin = Color(0xFFFFD966);
    const colorSakit = Color(0xFF4CAF50);
    const colorCuti = Color(0xFFE75636);

    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hadir = _statistikData['kehadiran']!;
    final izin = _statistikData['izin']!;
    final sakit = _statistikData['sakit']!;
    final cuti = _statistikData['cuti']!;
    final total = hadir + izin + sakit + cuti;

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Belum ada data',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildDetailBar(
          title: "Hadir",
          value: hadir / total,
          count: hadir,
          color: colorHadir,
        ),
        _buildDetailBar(
          title: "Izin",
          value: izin / total,
          count: izin,
          color: colorIzin,
        ),
        _buildDetailBar(
          title: "Sakit",
          value: sakit / total,
          count: sakit,
          color: colorSakit,
        ),
        _buildDetailBar(
          title: "Cuti",
          value: cuti / total,
          count: cuti,
          color: colorCuti,
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, int> data;
  final String hoveredLabel;
  final List<StatistikItem> items;

  DonutChartPainter(this.data, this.hoveredLabel, this.items);

  // Mapping label tampilan ke kunci data Map
  final keyMap = const {
    'Kehadiran': 'kehadiran',
    'Izin': 'izin',
    'Sakit': 'sakit',
    'Cuti': 'cuti'
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 40.0;

    paint.strokeWidth = strokeWidth;

    // Pastikan data Map tidak nol (karena Map<String, int> biasanya tidak mengandung null)
    final total = (data['kehadiran'] ?? 0) +
        (data['izin'] ?? 0) +
        (data['sakit'] ?? 0) +
        (data['cuti'] ?? 0);

    if (total == 0) {
      // Logika penanganan data nol Anda yang asli
      paint.color = Colors.grey[300]!;
      canvas.drawCircle(center, radius, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Belum ada data',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
      return;
    }

    paint.color = Colors.grey[200]!;
    canvas.drawCircle(center, radius, paint);

    double startAngle = -math.pi / 2;

    for (var item in items) {
      final key = keyMap[item.label];
      final value = (key != null) ? (data[key] ?? 0) : 0;

      if (value > 0) {
        final sweepAngle = (value / total) * 2 * math.pi;

        bool isHovered = item.label == hoveredLabel;
        Color segmentColor;

        if (hoveredLabel == 'Total' || isHovered) {
          segmentColor = item.color;
        } else {
          // Segmen lain memudar
          segmentColor = item.color.withOpacity(0.4);
        }

        paint.color = segmentColor;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
        startAngle += sweepAngle;
      }
    }

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - strokeWidth / 2 + 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.hoveredLabel != hoveredLabel ||
        oldDelegate.items != items;
  }
}
