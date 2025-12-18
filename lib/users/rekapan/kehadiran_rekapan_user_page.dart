import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:languo/screen/maps.dart';

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

            const SizedBox(height: 6),

            /// FILTER ICON
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<int?>(
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      color:
                          _selectedMonth != null ? Colors.orange : Colors.grey,
                    ),
                    onSelected: (v) => setState(() => _selectedMonth = v),
                    itemBuilder: (context) => [
                      const PopupMenuItem<int?>(
                        value: null,
                        child: Text("Semua Bulan"),
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
            ),

            const SizedBox(height: 8),

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

                  if (_selectedMonth != null) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final dateField = data['date'] ?? data['check_in_at'];
                      final dt = dateField is Timestamp
                          ? dateField.toDate()
                          : DateTime.parse(dateField);
                      return dt.month == _selectedMonth;
                    }).toList();
                  }

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

  /// HEADER — BACK SEJAJAR JUDUL
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
          Expanded(
            child: Center(
              child: Text(
                "Rekapan Kehadiran",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 48), // penyeimbang kanan
        ],
      ),
    );
  }

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
                Text("Keluar : ${keluar.isEmpty ? '--:--' : keluar}",
                    style: TextStyle(color: _getJamColor(keluar))),
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
