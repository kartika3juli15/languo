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

  /// FORMAT TANGGAL
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

  /// WARNA JAM → SELALU HIJAU
  Color _getJamColor(String jam) {
    if (jam.isEmpty) return Colors.grey;
    return Colors.green;
  }

  /// STATUS OTOMATIS
  String _computeStatus(String checkIn, String checkOut) {
    if (checkIn.isEmpty) return 'Proses';
    if (checkOut.isEmpty) return 'Proses';
    return 'Hadir';
  }

  /// CHECK OUT WAKTU VALID
  bool _isCheckOutTime() {
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    const checkoutStart = 8 * 60; // 08:00
    const checkoutEnd = 17 * 60; // 17:00
    return current >= checkoutStart && current <= checkoutEnd;
  }

  /// CHECK OUT KE HALAMAN MAPS → VALIDASI RADIUS
  Future<void> _goToMapsBeforeCheckout(String docId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapsPage()),
    );

    if (result == true) {
      _showCheckOutDialog(docId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda berada di luar radius 100 meter!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// DIALOG COUNTDOWN CHECK OUT
  void _showCheckOutDialog(String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CountdownDialog(
        onCheckOut: () async {
          Navigator.pop(context);
          await _performCheckOut(docId);
        },
      ),
    );
  }

  Future<void> _performCheckOut(String docId) async {
    final now = DateTime.now();
    final timeNow =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    await _firestore.collection('absensi').doc(docId).update({
      'check_out': timeNow,
      'status': 'Hadir',
      'updated_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check out berhasil!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// STREAM REKAPAN USER YANG LOGIN
  Stream<QuerySnapshot> _userAbsensiStream() {
    return _firestore
        .collection('absensi')
        .where("user_id", isEqualTo: currentUserId)
        .snapshots(); // tanpa orderBy
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
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _userAbsensiStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  docs.sort((a, b) {
                    final aTime = a['created_at']?.toDate() ?? DateTime.now();
                    final bTime = b['created_at']?.toDate() ?? DateTime.now();
                    return bTime.compareTo(aTime);
                  });

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Belum ada data kehadiran"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      final data = d.data() as Map<String, dynamic>;

                      // Ambil data check-in/out & tanggal
                      final checkIn = data['check_in'] ?? '';
                      final checkOut = data['check_out'] ?? '';
                      final dateField = data['date'] ?? data['check_in_at'];

                      final status = _computeStatus(checkIn, checkOut);
                      final tanggal = _formatDisplayDate(dateField);

                      return _buildCard(
                        docId: d.id,
                        tanggal: tanggal,
                        masuk: checkIn,
                        keluar: checkOut,
                        status: status,
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

  /// HEADER
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

  /// CARD ABSENSI
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tanggal,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 30),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Masuk : $masuk",
                            style: TextStyle(color: _getJamColor(masuk))),
                        Text("Keluar : ${keluar.isEmpty ? '--:--' : keluar}",
                            style: TextStyle(color: _getJamColor(keluar))),
                      ],
                    ),
                  ],
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
                          ? () => _goToMapsBeforeCheckout(docId)
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE95A3A),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Check Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===========================================
/// DIALOG COUNTDOWN CHECK OUT
/// ===========================================
class _CountdownDialog extends StatefulWidget {
  final VoidCallback onCheckOut;
  const _CountdownDialog({required this.onCheckOut});

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        widget.onCheckOut();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return "00:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Waktu Check Out"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("08.00 - 17.00", style: TextStyle(color: Colors.orange)),
          const SizedBox(height: 12),
          Text(_format(_remainingSeconds),
              style: const TextStyle(fontSize: 18, color: Colors.green)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            widget.onCheckOut();
          },
          child: const Text("Check Out"),
        )
      ],
    );
  }
}
