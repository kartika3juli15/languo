import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:languo/screen/buat_qr.dart';
import 'package:languo/admin/pengajuan/sakit_pengajuan_role_page.dart';
import 'package:languo/admin/pengajuan/cuti_pengajuan_role_page.dart';
import 'package:languo/admin/pengajuan/izin_pengajuan_role_page.dart';
import '../models/user_model.dart';
import '../profile/profile_page.dart';
import 'rekapan/izin_rekapan_admin_page.dart';
import 'rekapan/sakit_rekapan_admin_page.dart';
import 'rekapan/kehadiran_rekapan_admin_page.dart';
import 'tambah_jadwal.dart';
import 'package:intl/intl.dart';
import 'package:languo/admin/user_management_page.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  String? _lastScannedData;
  Map<String, int> _statistikData = {
    'tepatWaktu': 0,
    'terlambat': 0,
    'izin': 0,
    'sakit': 0,
    'cuti': 0,
    'kehadiran': 0,
  };
  bool _isLoadingStats = true;
  String _selectedRole = 'dosen'; // Default dosen

  @override
  void initState() {
    super.initState();
    _loadStatistikData();
  }

  Future<void> _loadStatistikData() async {
    setState(() => _isLoadingStats = true);

    try {
      int tepatWaktu = 0;
      int terlambat = 0;
      int kehadiran = 0;
      int izin = 0;
      int sakit = 0;
      int cuti = 0;

      debugPrint('=== LOADING STATISTIK untuk $_selectedRole ===');

      // 1. Hitung data absensi berdasarkan role
      final absensiSnapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .get();

      debugPrint('Total dokumen absensi: ${absensiSnapshot.docs.length}');

      for (var doc in absensiSnapshot.docs) {
        final data = doc.data();
        
        debugPrint('--- Processing absensi doc: ${doc.id} ---');
        debugPrint('Raw data: $data');
        
        // Coba ambil user_id dengan berbagai kemungkinan
        final userIdRaw = data['user_id'];
        debugPrint('user_id raw type: ${userIdRaw.runtimeType}');
        debugPrint('user_id raw value: "$userIdRaw"');
        
        String userId = '';
        if (userIdRaw is int) {
          userId = userIdRaw.toString();
        } else if (userIdRaw is String) {
          userId = userIdRaw;
        } else {
          userId = userIdRaw?.toString() ?? '';
        }
        
        debugPrint('user_id setelah konversi: "$userId"');
        
        if (userId.isEmpty) {
          debugPrint('Skip: user_id kosong');
          continue;
        }

        // Cek role user berdasarkan user_id
        final userRole = await _getUserRoleByUserId(userId);
        
        debugPrint('Role yang ditemukan: $userRole, Filter: $_selectedRole');
        
        if (userRole == null) {
          debugPrint('❌ User $userId tidak ditemukan di collection manapun');
          continue;
        }
        
        if (userRole != _selectedRole) {
          debugPrint('Skip: role=$userRole, filter=$_selectedRole');
          continue;
        }

        // Ambil check_in_time dan check_out_time (Timestamp dari Firestore)
        final checkInTimestamp = data['check_in_time'] as Timestamp?;
        final checkOutTimestamp = data['check_out_time'] as Timestamp?;

        debugPrint('check_in_time: $checkInTimestamp');
        debugPrint('check_out_time: $checkOutTimestamp');

        if (checkInTimestamp == null || checkOutTimestamp == null) {
          debugPrint('Skip: check_in_time atau check_out_time null');
          continue;
        }

        final checkInTime = checkInTimestamp.toDate();
        final checkOutTime = checkOutTimestamp.toDate();

        // Hitung kehadiran (yang sudah check in DAN check out)
        kehadiran++;
        debugPrint('✓ Kehadiran++ untuk user $userId: Total = $kehadiran');

        // Hitung tepat waktu vs terlambat (berdasarkan jam check in)
        try {
          final hour = checkInTime.hour;
          final minute = checkInTime.minute;

          debugPrint('Check in time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

          // Tepat waktu jika sebelum atau sama dengan 07:30
          if (hour < 7 || (hour == 7 && minute <= 30)) {
            tepatWaktu++;
            debugPrint('✓ Tepat Waktu: Total = $tepatWaktu');
          } else {
            terlambat++;
            debugPrint('✓ Terlambat: Total = $terlambat');
          }
        } catch (e) {
          debugPrint('Error parsing time: $e');
        }
      }

      debugPrint('Hasil Absensi: Kehadiran=$kehadiran, Tepat Waktu=$tepatWaktu, Terlambat=$terlambat');

      // 2. Hitung izin yang disetujui
      debugPrint('--- Mengecek Izin ---');
      final izinSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_izin')
          .where('status', isEqualTo: 'Disetujui')
          .get();

      debugPrint('Total izin dengan status Disetujui: ${izinSnapshot.docs.length}');

      for (var doc in izinSnapshot.docs) {
        final data = doc.data();
        var userRole = (data['user_role'] ?? '').toString().trim();
        final userName = data['user_name'] ?? '';
        
        // Normalisasi role ke lowercase
        userRole = userRole.toLowerCase();
        
        debugPrint('Izin - User: $userName, Role: "$userRole", Filter: "$_selectedRole"');
        
        if (userRole == _selectedRole) {
          izin++;
          debugPrint('✓ Izin MATCH! Total: $izin');
        } else {
          debugPrint('✗ Izin TIDAK MATCH (role tidak sama)');
        }
      }

      // 3. Hitung sakit yang disetujui
      debugPrint('--- Mengecek Sakit ---');
      final sakitSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_sakit')
          .where('status', isEqualTo: 'Disetujui')
          .get();

      debugPrint('Total sakit dengan status Disetujui: ${sakitSnapshot.docs.length}');

      for (var doc in sakitSnapshot.docs) {
        final data = doc.data();
        var userRole = (data['user_role'] ?? '').toString().trim();
        final userName = data['user_name'] ?? '';
        
        // Normalisasi role ke lowercase
        userRole = userRole.toLowerCase();
        
        debugPrint('Sakit - User: $userName, Role: "$userRole", Filter: "$_selectedRole"');
        
        if (userRole == _selectedRole) {
          sakit++;
          debugPrint('✓ Sakit MATCH! Total: $sakit');
        } else {
          debugPrint('✗ Sakit TIDAK MATCH (role tidak sama)');
        }
      }

      // 4. Hitung cuti yang disetujui
      debugPrint('--- Mengecek Cuti ---');
      final cutiSnapshot = await FirebaseFirestore.instance
          .collection('pengajuan_cuti')
          .where('status', isEqualTo: 'Disetujui')
          .get();

      debugPrint('Total cuti dengan status Disetujui: ${cutiSnapshot.docs.length}');

      for (var doc in cutiSnapshot.docs) {
        final data = doc.data();
        var userRole = (data['user_role'] ?? '').toString().trim();
        final userName = data['user_name'] ?? '';
        
        // Normalisasi role ke lowercase
        userRole = userRole.toLowerCase();
        
        debugPrint('Cuti - User: $userName, Role: "$userRole", Filter: "$_selectedRole"');
        
        if (userRole == _selectedRole) {
          cuti++;
          debugPrint('✓ Cuti MATCH! Total: $cuti');
        } else {
          debugPrint('✗ Cuti TIDAK MATCH (role tidak sama)');
        }
      }

      debugPrint('=== HASIL AKHIR STATISTIK ($_selectedRole) ===');
      debugPrint('Kehadiran: $kehadiran');
      debugPrint('Tepat Waktu: $tepatWaktu');
      debugPrint('Terlambat: $terlambat');
      debugPrint('Izin: $izin');
      debugPrint('Sakit: $sakit');
      debugPrint('Cuti: $cuti');

      setState(() {
        _statistikData = {
          'tepatWaktu': tepatWaktu,
          'terlambat': terlambat,
          'izin': izin,
          'sakit': sakit,
          'cuti': cuti,
          'kehadiran': kehadiran,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading statistik: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  // Fungsi untuk mendapatkan role berdasarkan user_id (menggunakan document ID)
  Future<String?> _getUserRoleByUserId(String userId) async {
    try {
      // Cek di collection dosen berdasarkan document ID
      var doc = await FirebaseFirestore.instance
          .collection('dosen')
          .doc(userId)
          .get();
      if (doc.exists) {
        debugPrint('✓ User $userId ditemukan di collection DOSEN');
        return 'dosen';
      }

      // Cek di collection karyawan berdasarkan document ID
      doc = await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(userId)
          .get();
      if (doc.exists) {
        debugPrint('✓ User $userId ditemukan di collection KARYAWAN');
        return 'karyawan';
      }

      // Cek di collection users berdasarkan document ID (fallback)
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final role = (data['user_role'] ?? 'karyawan').toString().toLowerCase();
        debugPrint('✓ User $userId ditemukan di collection USERS dengan role: $role');
        return role;
      }

      debugPrint('✗ User $userId TIDAK DITEMUKAN di collection manapun');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user role for $userId: $e');
      return null;
    }
  }

  Future<String?> _getUserRole(String userId) async {
    if (userId.isEmpty) return null;

    try {
      // Cek di collection dosen
      var doc = await FirebaseFirestore.instance
          .collection('dosen')
          .doc(userId)
          .get();
      if (doc.exists) {
        debugPrint('✓ User $userId ditemukan di collection DOSEN');
        return 'dosen';
      }

      // Cek di collection karyawan
      doc = await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(userId)
          .get();
      if (doc.exists) {
        debugPrint('✓ User $userId ditemukan di collection KARYAWAN');
        return 'karyawan';
      }

      // Cek di collection users
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final role = (data['user_role'] ?? 'karyawan').toString().toLowerCase();
        debugPrint('✓ User $userId ditemukan di collection USERS dengan role: $role');
        return role;
      }

      debugPrint('✗ User $userId TIDAK DITEMUKAN di collection manapun');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user role for $userId: $e');
      return null;
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

  void _showRoleFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Radio<String>(
                    value: 'dosen',
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                      Navigator.pop(context);
                      _loadStatistikData();
                    },
                  ),
                  title: const Text('Dosen'),
                  onTap: () {
                    setState(() => _selectedRole = 'dosen');
                    Navigator.pop(context);
                    _loadStatistikData();
                  },
                ),
                ListTile(
                  leading: Radio<String>(
                    value: 'karyawan',
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                      Navigator.pop(context);
                      _loadStatistikData();
                    },
                  ),
                  title: const Text('Karyawan'),
                  onTap: () {
                    setState(() => _selectedRole = 'karyawan');
                    Navigator.pop(context);
                    _loadStatistikData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Padding(
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

  Widget _buildDetailSection() {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final total = _statistikData['kehadiran']! +
        _statistikData['tepatWaktu']! +
        _statistikData['terlambat']! +
        _statistikData['izin']! +
        _statistikData['sakit']! +
        _statistikData['cuti']!;

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Belum ada data untuk ${_selectedRole == 'dosen' ? 'Dosen' : 'Karyawan'}',
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
          title: "Kehadiran",
          value: _statistikData['kehadiran']! / total,
          count: _statistikData['kehadiran']!,
          color: const Color(0xFF5B9BD5),
        ),
        _buildDetailBar(
          title: "Tepat Waktu",
          value: _statistikData['tepatWaktu']! / total,
          count: _statistikData['tepatWaktu']!,
          color: const Color(0xFF4CAF50),
        ),
        _buildDetailBar(
          title: "Terlambat",
          value: _statistikData['terlambat']! / total,
          count: _statistikData['terlambat']!,
          color: const Color(0xFFFFA500),
        ),
        _buildDetailBar(
          title: "Izin",
          value: _statistikData['izin']! / total,
          count: _statistikData['izin']!,
          color: const Color(0xFFFFD966),
        ),
        _buildDetailBar(
          title: "Sakit",
          value: _statistikData['sakit']! / total,
          count: _statistikData['sakit']!,
          color: const Color(0xFFFF6B6B),
        ),
        _buildDetailBar(
          title: "Cuti",
          value: _statistikData['cuti']! / total,
          count: _statistikData['cuti']!,
          color: const Color(0xFF9C27B0),
        ),
      ],
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
        Positioned(
          top: -20,
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuatQRPage()),
              );
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
                    Text("HAI!",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      user?.userName ?? "-",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.userRole ?? "-",
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
          boxShadow: [
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
              Text(
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
  Widget _buildAktivitasChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Aktivitas keseluruhan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isLoadingStats)
                SizedBox(
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
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filter button di pojok kanan atas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedRole == 'dosen' ? 'Dosen' : 'Karyawan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.menu, color: Colors.grey[700]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        setState(() => _selectedRole = value);
                        _loadStatistikData();
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'karyawan',
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'karyawan',
                                groupValue: _selectedRole,
                                onChanged: (val) {
                                  setState(() => _selectedRole = val!);
                                  Navigator.pop(context);
                                  _loadStatistikData();
                                },
                              ),
                              const Text('Karyawan'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'dosen',
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'dosen',
                                groupValue: _selectedRole,
                                onChanged: (val) {
                                  setState(() => _selectedRole = val!);
                                  Navigator.pop(context);
                                  _loadStatistikData();
                                },
                              ),
                              const Text('Dosen'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Chart
                SizedBox(
                  height: 220,
                  child: _isLoadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : CustomPaint(
                          size: const Size(220, 220),
                          painter: DonutChartPainter(_statistikData),
                        ),
                ),
              ],
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
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
  final Map<String, int> data;

  DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final strokeWidth = 35.0;

    paint.strokeWidth = strokeWidth;

    final total = data['kehadiran']! +
        data['tepatWaktu']! +
        data['terlambat']! +
        data['izin']! +
        data['sakit']! +
        data['cuti']!;

    if (total == 0) {
      // Tampilkan circle kosong jika tidak ada data
      paint.color = Colors.grey[300]!;
      canvas.drawCircle(center, radius, paint);

      // Tampilkan text "Belum ada data"
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

    final values = [
      data['kehadiran']! / total,
      data['tepatWaktu']! / total,
      data['terlambat']! / total,
      data['izin']! / total,
      data['sakit']! / total,
      data['cuti']! / total,
    ];

    final colors = [
      const Color(0xFF5B9BD5), // Kehadiran - Biru
      const Color(0xFF4CAF50), // Tepat Waktu - Hijau
      const Color(0xFFFFA500), // Terlambat - Orange
      const Color(0xFFFFD966), // Izin - Kuning
      const Color(0xFFFF6B6B), // Sakit - Merah Muda
      const Color(0xFF9C27B0), // Cuti - Ungu
    ];

    final labels = ['Kehadiran', 'Tepat Waktu', 'Terlambat', 'Izin', 'Sakit', 'Cuti'];

    double startAngle = -math.pi / 2; // Mulai dari atas

    // Gambar donut chart
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        paint.color = colors[i];
        final sweepAngle = values[i] * 2 * math.pi;
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

    // Gambar lingkaran dalam putih
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - strokeWidth / 2, innerPaint);

    // Gambar label persentase di dalam chart dengan warna HITAM
    startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0.03) {
        // Hanya tampilkan label jika > 3%
        final sweepAngle = values[i] * 2 * math.pi;
        final middleAngle = startAngle + sweepAngle / 2;

        // Posisi label di tengah arc
        final labelRadius = radius - strokeWidth / 2;
        final labelX = center.dx + labelRadius * math.cos(middleAngle);
        final labelY = center.dy + labelRadius * math.sin(middleAngle);

        // Gambar persentase dengan warna HITAM dan font lebih besar
        final percentage = (values[i] * 100).toStringAsFixed(0);
        final labelPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: const TextStyle(
              color: Colors.black, // WARNA HITAM
              fontSize: 14, // Ukuran lebih besar
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            labelX - labelPainter.width / 2,
            labelY - labelPainter.height / 2,
          ),
        );

        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => true;
}