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

  int? _selectedMonth; // null = semua bulan

  /// ===============================
  /// AMBIL DATA USER
  /// ===============================
  Future<Map<String, dynamic>?> _getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final d = doc.data()!;
    return {
      'user_name': d['user_name'] ?? '',
      'user_email': d['user_email'] ?? '',
      'user_role': d['user_role'] ?? '',
    };
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

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('EEE, dd MMM yyyy', 'id').format(ts.toDate());
  }

  String _status(String i, String o) =>
      (i.isEmpty || o.isEmpty) ? 'Proses' : 'Hadir';

  Color _jamColor(String jam) => jam.isEmpty ? Colors.grey : Colors.green;

  bool _matchSearch(String q, String n, String e) {
    if (q.isEmpty) return true;
    q = q.toLowerCase();
    return n.toLowerCase().contains(q) || e.toLowerCase().contains(q);
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
          _filter(),
          const SizedBox(height: 10),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  /// ===============================
  /// HEADER (BACK TETAP ADA)
  /// ===============================
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
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
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

  /// ===============================
  /// TAB
  /// ===============================
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// SEARCH
  /// ===============================
  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari nama / email...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// FILTER BULAN
  /// ===============================
  Widget _filter() {
    return Padding(
      padding: const EdgeInsets.only(right: 28, top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<int?>(
            tooltip: 'Filter Bulan',
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _selectedMonth != null ? Colors.orange : Colors.grey,
            ),
            onSelected: (v) => setState(() => _selectedMonth = v),
            itemBuilder: (context) => [
              const PopupMenuItem<int?>(
                value: null,
                child: Text('Semua Bulan'),
              ),
              ...List.generate(12, (i) {
                return PopupMenuItem<int?>(
                  value: i + 1,
                  child: Text(
                    DateFormat.MMMM('id').format(DateTime(0, i + 1)),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// LIST
  /// ===============================
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
  /// PROCESS DATA (SEARCH + FILTER)
  /// ===============================
  Future<List<Map<String, dynamic>>> _process(
      List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> result = [];
    final q = searchController.text.trim();

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final userId = d['user_id'];
      final ts = d['check_in_at'];

      if (ts is! Timestamp) continue;

      if (_selectedMonth != null && ts.toDate().month != _selectedMonth)
        continue;

      final user = await _getUser(userId);
      if (user == null) continue;
      if (user['user_role'] != selectedRole) continue;
      if (!_matchSearch(q, user['user_name'], user['user_email'])) continue;

      final inTime = d['check_in'] ?? '';
      final outTime = d['check_out'] ?? '';

      result.add({
        'user_name': user['user_name'],
        'user_email': user['user_email'],
        'tanggal': _formatDate(ts),
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
          const Text(': '),
          Expanded(
            child: Text(v.isEmpty ? '--:--' : v, style: TextStyle(color: c)),
          ),
        ],
      ),
    );
  }
}
