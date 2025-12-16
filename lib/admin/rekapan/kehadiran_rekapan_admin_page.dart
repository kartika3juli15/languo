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

  int selectedTabIndex = 0; // 0 = dosen, 1 = karyawan
  String get selectedRole => selectedTabIndex == 0 ? 'Dosen' : 'Karyawan';

  final TextEditingController searchController = TextEditingController();

  /// ===============================
  /// AMBIL DATA USER
  /// ===============================
  Future<Map<String, dynamic>?> _getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final d = doc.data()!;
      return {
        'user_id': userId,
        'user_name': d['user_name'] ?? '',
        'user_email': d['user_email'] ?? '',
        'user_role': d['user_role'] ?? '',
      };
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  /// ===============================
  /// STREAM ABSENSI
  /// ===============================
  Stream<QuerySnapshot> _absensiStream() {
    return _firestore
        .collection('absensi')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// ===============================
  /// FORMAT TANGGAL
  /// ===============================
  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('EEE, dd MMM yyyy', 'id').format(ts.toDate());
  }

  /// ===============================
  /// STATUS ABSENSI
  /// ===============================
  String _status(String inTime, String outTime) {
    if (inTime.isEmpty || outTime.isEmpty) return 'Proses';
    return 'Hadir';
  }

  Color _jamColor(String jam) => jam.isEmpty ? Colors.grey : Colors.green;

  bool _matchSearch(String q, String name, String email) {
    if (q.isEmpty) return true;
    q = q.toLowerCase();
    return name.toLowerCase().contains(q) || email.toLowerCase().contains(q);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _header(),
          _tabBar(),
          const SizedBox(height: 8),
          _search(),
          const SizedBox(height: 10),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _header() {
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
              "Rekapan Kehadiran",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 54,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            _tabBtn('Dosen', 0),
            _tabBtn('Karyawan', 1),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String t, int i) {
    final active = selectedTabIndex == i;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = i;
            searchController.clear();
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE95A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            t,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari nama / email...',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _list() {
    return StreamBuilder<QuerySnapshot>(
      stream: _absensiStream(),
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _process(s.data!.docs),
          builder: (c, f) {
            if (!f.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = f.data!;
            if (data.isEmpty) {
              return const Center(child: Text('Tidak ada data'));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              itemCount: data.length,
              itemBuilder: (c, i) => _card(data[i]),
            );
          },
        );
      },
    );
  }

  /// ===============================
  /// PROCESS DATA
  /// ===============================
  Future<List<Map<String, dynamic>>> _process(
      List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> result = [];
    final q = searchController.text.trim();

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final userId = d['user_id'];

      if (userId == null) continue;

      final user = await _getUser(userId);
      if (user == null) continue;
      if (user['user_role'] != selectedRole) continue;

      final name = user['user_name'];
      final email = user['user_email'];
      if (!_matchSearch(q, name, email)) continue;

      final inTime = d['check_in'] ?? '';
      final outTime = d['check_out'] ?? '';

      result.add({
        'docId': doc.id,
        'user_name': name,
        'user_email': email,
        'tanggal': _formatDate(d['check_in_at']),
        'check_in': inTime,
        'check_out': outTime,
        'status': _status(inTime, outTime),
      });
    }

    return result;
  }

  /// ===============================
  /// CARD
  /// ===============================
  Widget _card(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d['user_name'],
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(d['user_email'],
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          _row('Tanggal', d['tanggal']),
          _row('Masuk', d['check_in'], _jamColor(d['check_in'])),
          _row('Keluar', d['check_out'], _jamColor(d['check_out'])),
          const SizedBox(height: 8),
          Chip(
            backgroundColor:
                d['status'] == 'Hadir' ? Colors.green : Colors.orange,
            label:
                Text(d['status'], style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, [Color? c]) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(l)),
          Text(': '),
          Expanded(
            child: Text(
              v.isEmpty ? '--:--' : v,
              style: TextStyle(color: c),
            ),
          ),
        ],
      ),
    );
  }
}
