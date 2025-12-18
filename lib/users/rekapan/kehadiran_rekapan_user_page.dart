import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class KehadiranPage extends StatefulWidget {
  const KehadiranPage({super.key});

  @override
  State<KehadiranPage> createState() => _KehadiranPageState();
}

class _KehadiranPageState extends State<KehadiranPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  int? _selectedMonth;
  int? _selectedYear;

  /// ===============================
  /// HELPER
  /// ===============================
  String _formatDisplayDate(dynamic firestoreDate) {
    try {
      DateTime dt;
      if (firestoreDate is Timestamp) {
        dt = firestoreDate.toDate();
      } else if (firestoreDate is String) {
        dt = DateTime.parse(firestoreDate);
      } else {
        return firestoreDate.toString();
      }
      return DateFormat('EEE, dd MMM yyyy', 'id').format(dt);
    } catch (e) {
      return firestoreDate.toString();
    }
  }

  Color _getJamColor(String jam) => jam.isEmpty ? Colors.grey : Colors.green;

  String _computeStatus(String checkIn, String checkOut) {
    if (checkIn.isEmpty || checkOut.isEmpty) return 'Proses';
    return 'Hadir';
  }

  bool _isCheckOutTime() {
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    return current >= 480 && current <= 1020;
  }

  Stream<QuerySnapshot> _userAbsensiStream() {
    return _firestore
        .collection('absensi')
        .where("user_id", isEqualTo: currentUserId)
        .snapshots();
  }

  String _getMonthName(int month) {
    const months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return months[month - 1];
  }

  bool _matchMonthYear(dynamic dateField) {
    DateTime dt;
    if (dateField is Timestamp) {
      dt = dateField.toDate();
    } else if (dateField is String) {
      dt = DateTime.parse(dateField);
    } else {
      return false;
    }

    if (_selectedMonth != null && dt.month != _selectedMonth) return false;
    if (_selectedYear != null && dt.year != _selectedYear) return false;
    return true;
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchText = v),
                decoration: InputDecoration(
                  hintText: "Cari tanggal / status",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            /// FILTER BULAN & TAHUN (SESUAI GAMBAR)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedMonth,
                      hint: const Text("Semua Bulan"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Semua Bulan"),
                        ),
                        ...List.generate(12, (i) {
                          return DropdownMenuItem<int?>(
                            value: i + 1,
                            child: Text(_getMonthName(i + 1)),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedMonth = v),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: "Filter Bulan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedYear,
                      hint: const Text("Semua Tahun"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Semua Tahun"),
                        ),
                        ...List.generate(5, (i) {
                          final year = DateTime.now().year - i;
                          return DropdownMenuItem<int?>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedYear = v),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: "Tahun",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _userAbsensiStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  docs.sort((a, b) {
                    final aTime = a['created_at']?.toDate() ?? DateTime.now();
                    final bTime = b['created_at']?.toDate() ?? DateTime.now();
                    return bTime.compareTo(aTime);
                  });

                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final dateField = data['date'] ?? data['check_in_at'];
                    return _matchMonthYear(dateField);
                  }).toList();

                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final tanggal =
                        _formatDisplayDate(data['date'] ?? data['check_in_at']);
                    final status = _computeStatus(
                        data['check_in'] ?? '', data['check_out'] ?? '');

                    return tanggal
                            .toLowerCase()
                            .contains(_searchText.toLowerCase()) ||
                        status
                            .toLowerCase()
                            .contains(_searchText.toLowerCase());
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("Data tidak ditemukan"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      final data = d.data() as Map<String, dynamic>;
                      final dateField = data['date'] ?? data['check_in_at'];

                      return _buildCard(
                        docId: d.id,
                        tanggal: _formatDisplayDate(dateField),
                        masuk: data['check_in'] ?? '',
                        keluar: data['check_out'] ?? '',
                        status: _computeStatus(
                            data['check_in'] ?? '', data['check_out'] ?? ''),
                        date: dateField is Timestamp
                            ? dateField
                            : Timestamp.fromDate(DateTime.parse(dateField)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// HEADER
  /// ===============================
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
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Rekapan Kehadiran",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// ===============================
  /// CARD
  /// ===============================
  Widget _buildCard({
    required String docId,
    required String masuk,
    required String keluar,
    required String tanggal,
    required String status,
    required Timestamp date,
  }) {
    bool isToday(Timestamp ts) {
      final d = ts.toDate();
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tanggal,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Masuk : $masuk",
                    style: TextStyle(color: _getJamColor(masuk))),
                Text(
                  "Keluar : ${keluar.isEmpty ? '--:--' : keluar}",
                  style: TextStyle(color: _getJamColor(keluar)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == "Hadir" ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(status, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      (status == "Proses" && _isCheckOutTime() && isToday(date))
                          ? () {}
                          : null,
                  child: const Text("Check Out"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
