import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminKehadiranPage extends StatefulWidget {
  const AdminKehadiranPage({Key? key}) : super(key: key);

  @override
  State<AdminKehadiranPage> createState() => _AdminKehadiranPageState();
}

class _AdminKehadiranPageState extends State<AdminKehadiranPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // tab state: 0 = Dosen, 1 = Karyawan
  int selectedTabIndex = 0;
  String get selectedTabLabel => selectedTabIndex == 0 ? 'Dosen' : 'Karyawan';
  String get selectedCollection => selectedTabIndex == 0 ? 'dosen' : 'karyawan';

  final TextEditingController searchController = TextEditingController();

  // stream snapshots for users (dosen/karyawan) and absensi
  Stream<QuerySnapshot> usersStream(String coll) =>
      _firestore.collection(coll).snapshots();

  Stream<QuerySnapshot> absensiStream() {
    try {
      return _firestore
          .collection('absensi')
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      // Jika orderBy error (missing index), fallback tanpa orderBy
      debugPrint('Error orderBy absensi: $e');
      return _firestore.collection('absensi').snapshots();
    }
  }

  // format tanggal display
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

  // compute status
  String computeStatus(String checkIn, String checkOut) {
    if (checkIn.isEmpty) return 'Proses';
    if (checkOut.isEmpty) return 'Proses';
    return 'Sudah Absen';
  }

  // warna jam (hijau jika ada, abu jika kosong)
  Color jamColor(String jam) => jam.isEmpty ? Colors.grey : Colors.green;

  // delete absensi doc
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

  // confirm delete
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

  // filter absensi by search (name/email)
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

  // UI BUILD
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
          Expanded(child: _buildCombinedList()),
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

  /// Combine users (dosen/karyawan) stream + absensi stream,
  /// join in memory and filter for the selected role.
  Widget _buildCombinedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usersStream(selectedCollection),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${usersSnapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        if (!usersSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final usersDocs = usersSnapshot.data!.docs;
        
        // Debug: print jumlah user
        debugPrint('Total ${selectedTabLabel}: ${usersDocs.length}');
        
        // map userId -> userData
        final Map<String, Map<String, dynamic>> usersMap = {};
        for (var u in usersDocs) {
          final data = u.data() as Map<String, dynamic>;
          usersMap[u.id] = data;
          // Debug: print user info
          debugPrint('User ${u.id}: ${data['nama'] ?? data['name'] ?? 'No name'}');
        }

        if (usersMap.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Tidak ada data $selectedTabLabel',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        // now listen to absensi
        return StreamBuilder<QuerySnapshot>(
          stream: absensiStream(),
          builder: (context, absSnapshot) {
            if (absSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error absensi: ${absSnapshot.error}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan Firestore index sudah dibuat',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            if (!absSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final absDocs = absSnapshot.data!.docs;
            
            // Debug: print jumlah absensi
            debugPrint('Total absensi records: ${absDocs.length}');

            // build list of combined entries where abs.user_id exists in usersMap
            final List<_CombinedEntry> combined = [];

            for (var a in absDocs) {
              final aData = a.data() as Map<String, dynamic>;
              final userId = (aData['user_id'] ?? '').toString().trim();
              
              // Debug: print absensi info
              debugPrint('Absensi ${a.id}: user_id=$userId');
              
              if (userId.isEmpty) {
                debugPrint('  -> Skipped: user_id kosong');
                continue;
              }
              
              if (!usersMap.containsKey(userId)) {
                debugPrint('  -> Skipped: user_id tidak ditemukan di $selectedCollection');
                continue; // skip absensi not for this role
              }

              final user = usersMap[userId]!;
              final nama = (user['nama'] ?? user['name'] ?? 'Tanpa Nama').toString();
              final email = (user['email'] ?? 'Tanpa Email').toString();

              // read fields from absensi
              final checkIn = (aData['check_in'] ?? '').toString();
              final checkOut = (aData['check_out'] ?? '').toString();
              final date = aData['date'];
              final tanggal = _formatDisplayDate(date);

              final status = computeStatus(checkIn, checkOut);

              // search filter
              final query = searchController.text.trim();
              if (!_matchesSearch(query, nama, email)) {
                debugPrint('  -> Skipped: tidak cocok dengan search query');
                continue;
              }

              debugPrint('  -> Added to list: $nama');

              combined.add(_CombinedEntry(
                absId: a.id,
                userId: userId,
                nama: nama,
                email: email,
                checkIn: checkIn,
                checkOut: checkOut,
                tanggal: tanggal,
                status: status,
                rawAbsensi: aData,
              ));
            }

            debugPrint('Total combined entries for $selectedTabLabel: ${combined.length}');

            if (combined.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Tidak ada data kehadiran $selectedTabLabel',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text(
                      searchController.text.isNotEmpty
                          ? 'Coba kata kunci pencarian lain'
                          : 'Belum ada data absensi untuk $selectedTabLabel',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                return _buildAdminCard(item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAdminCard(_CombinedEntry item) {
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
          // row top: avatar | nama,email | badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFF9E9E9E), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              // name & email
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nama,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 3),
                      Text(item.email,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF757575))),
                    ]),
              ),
              // badge status (Sudah Absen / Proses)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item.status == 'Sudah Absen'
                      ? const Color(0xFF5CB85C)
                      : const Color(0xFFFFA500),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status == 'Sudah Absen' ? 'sudah absen' : 'proses',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // details rows
          _infoRow('Hari, Tgl', item.tanggal),
          _infoRow('Masuk', item.checkIn.isEmpty ? '--:--' : item.checkIn,
              jamColor(item.checkIn)),
          _infoRow('Keluar', item.checkOut.isEmpty ? '--:--' : item.checkOut,
              jamColor(item.checkOut)),
          const SizedBox(height: 10),
          // actions (hapus)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(item.absId),
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

// small model for joined entry
class _CombinedEntry {
  final String absId;
  final String userId;
  final String nama;
  final String email;
  final String checkIn;
  final String checkOut;
  final String tanggal;
  final String status;
  final Map<String, dynamic> rawAbsensi;

  _CombinedEntry({
    required this.absId,
    required this.userId,
    required this.nama,
    required this.email,
    required this.checkIn,
    required this.checkOut,
    required this.tanggal,
    required this.status,
    required this.rawAbsensi,
  });
}