import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminKehadiranPage extends StatefulWidget {
  const AdminKehadiranPage({super.key});

  @override
  State<AdminKehadiranPage> createState() => _AdminKehadiranPageState();
}

class _AdminKehadiranPageState extends State<AdminKehadiranPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int selectedTabIndex = 0;
  String get selectedTabLabel => selectedTabIndex == 0 ? 'Dosen' : 'Karyawan';

  final TextEditingController searchController = TextEditingController();

  /// CEK APAKAH USER ADA DI COLLECTION DOSEN/KARYAWAN/USERS
  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    try {
      // Cek collection dosen
      var doc = await _firestore.collection('dosen').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'nama': data['nama'] ?? data['name'] ?? 'Tanpa Nama',
          'email': data['email'] ?? 'Tanpa Email',
          'role': 'dosen',
        };
      }

      // Cek collection karyawan
      doc = await _firestore.collection('karyawan').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'nama': data['nama'] ?? data['name'] ?? 'Tanpa Nama',
          'email': data['email'] ?? 'Tanpa Email',
          'role': 'karyawan',
        };
      }

      // Cek collection users (fallback)
      doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'nama': data['user_name'] ?? data['nama'] ?? data['name'] ?? 'Tanpa Nama',
          'email': data['user_email'] ?? data['email'] ?? 'Tanpa Email',
          'role': (data['user_role'] ?? 'karyawan').toString().toLowerCase(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> absensiStream() {
    try {
      return _firestore
          .collection('absensi')
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error orderBy absensi: $e');
      return _firestore.collection('absensi').snapshots();
    }
  }

  String _formatDisplayDate(dynamic firestoreDate) {
    try {
      DateTime dt;
      if (firestoreDate is Timestamp) {
        dt = firestoreDate.toDate();
      } else if (firestoreDate is String) {
        dt = DateTime.parse(firestoreDate);
      } else if (firestoreDate == null) {
        return 'Tanggal tidak tersedia';
      } else {
        return firestoreDate.toString();
      }
      return DateFormat('EEE, dd MMM yyyy', 'id').format(dt);
    } catch (e) {
      debugPrint('Error format date: $e');
      return firestoreDate?.toString() ?? 'Tanggal tidak valid';
    }
  }

  String computeStatus(String checkIn, String checkOut) {
    if (checkIn.isEmpty) return 'Proses';
    if (checkOut.isEmpty) return 'Proses';
    return 'Sudah Absen';
  }

  Color jamColor(String jam) => jam.isEmpty ? Colors.grey : Colors.green;

  Future<void> _deleteAbsensi(String docId) async {
    try {
      await _firestore.collection('absensi').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data absensi berhasil dihapus'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data'),
        content:
            const Text('Apakah Anda yakin ingin menghapus data absensi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAbsensi(docId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(String query, String nama, String email) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return nama.toLowerCase().contains(q) || email.toLowerCase().contains(q);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 12),
          Expanded(child: _buildAbsensiList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF36546C),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "Rekapan Kehadiran",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: const Color(0xFFF0F3F5),
            borderRadius: BorderRadius.circular(40)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  left: selectedTabIndex == 0 ? 0 : tabWidth,
                  child: Container(
                    width: tabWidth,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFC6D51), Color(0xFFEA5A3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _tabButton('Dosen', 0),
                    _tabButton('Karyawan', 1),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final bool active = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
            searchController.clear();
          });
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF7B8FA7),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Cari Pengguna....',
            hintStyle: TextStyle(color: Colors.white, fontSize: 15),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(Icons.search, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildAbsensiList() {
    return StreamBuilder<QuerySnapshot>(
      stream: absensiStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Tidak ada data absensi',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        // Process documents asynchronously
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _processAbsensiDocs(docs),
          builder: (context, processSnapshot) {
            if (!processSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final combined = processSnapshot.data!;

            if (combined.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Tidak ada data $selectedTabLabel',
                        style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan user sudah terdaftar di Firestore',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              itemCount: combined.length,
              itemBuilder: (context, idx) {
                final item = combined[idx];
                return _buildAdminCard(
                  docId: item['docId'],
                  nama: item['nama'],
                  email: item['email'],
                  checkIn: item['checkIn'],
                  checkOut: item['checkOut'],
                  tanggal: item['tanggal'],
                  status: item['status'],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _processAbsensiDocs(
      List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> combined = [];
    final selectedRole = selectedTabIndex == 0 ? 'dosen' : 'karyawan';

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = (data['user_id'] ?? '').toString().trim();

      if (userId.isEmpty) continue;

      // Ambil info user dari berbagai collection
      final userInfo = await _getUserInfo(userId);
      
      if (userInfo == null) {
        debugPrint('User $userId tidak ditemukan di collection manapun');
        continue;
      }

      // Filter by role
      if (userInfo['role'] != selectedRole) {
        debugPrint('User $userId role=${userInfo['role']}, skip (bukan $selectedRole)');
        continue;
      }

      // Ambil data dari absensi atau user info
      String nama = (data['nama'] ?? userInfo['nama']).toString();
      String email = (data['email'] ?? userInfo['email']).toString();

      final checkIn = (data['check_in'] ?? '').toString();
      final checkOut = (data['check_out'] ?? '').toString();
      final tanggal = _formatDisplayDate(data['date']);
      final status = computeStatus(checkIn, checkOut);

      // Search filter
      final query = searchController.text.trim();
      if (!_matchesSearch(query, nama, email)) continue;

      debugPrint('Added: $nama ($selectedRole)');

      combined.add({
        'docId': doc.id,
        'nama': nama,
        'email': email,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'tanggal': tanggal,
        'status': status,
      });
    }

    debugPrint('Total $selectedRole: ${combined.length}');
    return combined;
  }

  Widget _buildAdminCard({
    required String docId,
    required String nama,
    required String email,
    required String checkIn,
    required String checkOut,
    required String tanggal,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 3))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFF9E9E9E), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF757575))),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Sudah Absen'
                      ? const Color(0xFF5CB85C)
                      : const Color(0xFFFFA500),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'Sudah Absen' ? 'sudah absen' : 'proses',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Hari, Tgl', tanggal),
          _infoRow('Masuk', checkIn.isEmpty ? '--:--' : checkIn,
              jamColor(checkIn)),
          _infoRow('Keluar', checkOut.isEmpty ? '--:--' : checkOut,
              jamColor(checkOut)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(docId),
              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
              label: const Text('Hapus',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
        const Text(': ',
            style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.normal)),
        ),
      ]),
    );
  }
}