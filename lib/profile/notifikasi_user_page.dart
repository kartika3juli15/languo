import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:languo/users/pengajuan/cuti_pengajuan_page.dart';
import 'package:languo/users/pengajuan/izin_pengajuan_page.dart';
import 'package:languo/users/pengajuan/sakit_pengajuan_page.dart';
import 'package:rxdart/rxdart.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    String query = searchController.text.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),

            // STREAM DATA NOTIFIKASI USER
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: streamNotifikasiUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List data = snapshot.data!;

                  // Filter pencarian
                  data = data.where((n) {
                    return n["jenis"].toLowerCase().contains(query) ||
                        n["nama"].toLowerCase().contains(query) ||
                        n["status"].toLowerCase().contains(query);
                  }).toList();

                  if (data.isEmpty) {
                    return const Center(
                      child: Text(
                        "Data tidak ditemukan",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final n = data[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NotifikasiCard(
                          jenis: n["jenis"],
                          nama: n["nama"],
                          tanggal: n["tanggal"],
                          status: n["status"],
                          statusColor: n["statusColor"],
                          dotColor: n["dotColor"],
                          onTap: () {
                            if (n["jenis"].contains("Cuti")) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PengajuanCutiPage(initialTab: 1),
                                ),
                              );
                            } else if (n["jenis"].contains("Izin")) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PengajuanIzinPage(initialTab: 1),
                                ),
                              );
                            } else if (n["jenis"].contains("Sakit")) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PengajuanSakitPage(initialTab: 1),
                                ),
                              );
                            }
                          },
                        ),
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

  // ================================================================
  // STREAM NOTIFIKASI USER BERDASARKAN USER LOGIN
  // ================================================================
  Stream<List<Map<String, dynamic>>> streamNotifikasiUser() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final cuti = FirebaseFirestore.instance
        .collection("pengajuan_cuti")
        .where("user_id", isEqualTo: uid)
        .snapshots();

    final izin = FirebaseFirestore.instance
        .collection("pengajuan_izin")
        .where("user_id", isEqualTo: uid)
        .snapshots();

    final sakit = FirebaseFirestore.instance
        .collection("pengajuan_sakit")
        .where("user_id", isEqualTo: uid)
        .snapshots();

    return Rx.combineLatest3(cuti, izin, sakit, (QuerySnapshot cutiSnap,
        QuerySnapshot izinSnap, QuerySnapshot sakitSnap) {
      List<Map<String, dynamic>> all = [];

      void addDocs(QuerySnapshot snap, String jenisLabel) {
        for (var doc in snap.docs) {
          final d = doc.data() as Map<String, dynamic>;
          if (d["status"] != "Disetujui" && d["status"] != "Ditolak") {
            continue;
          }

          // Format tanggal
          String tanggalDisplay = "-";
          if (d["tanggal_mulai"] != null && d["tanggal_selesai"] != null) {
            final start = (d["tanggal_mulai"] as Timestamp).toDate();
            final end = (d["tanggal_selesai"] as Timestamp).toDate();
            tanggalDisplay =
                "${start.day}/${start.month}/${start.year} s.d ${end.day}/${end.month}/${end.year}";
          }

          // STATUS COLOR
          Color badgeColor;
          Color dotColor;

          switch (d["status"]) {
            case "Disetujui":
              badgeColor = Colors.green;
              dotColor = Colors.green;
              break;
            case "Ditolak":
              badgeColor = Colors.red;
              dotColor = Colors.grey;
              break;
            default:
              badgeColor = Colors.orange;
              dotColor = Colors.orange;
          }

          all.add({
            "jenis": "Pengajuan Anda ${d["status"]} $jenisLabel",
            "nama": d["user_name"],
            "tanggal": tanggalDisplay,
            "status": d["status"],
            "statusColor": badgeColor,
            "dotColor": dotColor,
            "createdAt": d["created_at"] ?? Timestamp.now(),
          });
        }
      }

      addDocs(cutiSnap, "Cuti");
      addDocs(izinSnap, "Izin");
      addDocs(sakitSnap, "Sakit");

      // Sort berdasarkan createdAt DESC
      all.sort((a, b) {
        final t1 = a["createdAt"] as Timestamp;
        final t2 = b["createdAt"] as Timestamp;
        return t2.millisecondsSinceEpoch.compareTo(t1.millisecondsSinceEpoch);
      });

      return all;
    });
  }

  // ================================================================
  // UI ELEMENTS
  // ================================================================

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            color: Color(0xFF36546C),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: -18,
          child: Icon(
            Icons.menu_book_rounded,
            size: 140,
            color: Colors.white.withOpacity(0.10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 70),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                "Notifikasi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EEF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Cari...",
            suffixIcon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
//                     WIDGET KARTU NOTIFIKASI (TIDAK DIUBAH)
// ===============================================================

class NotifikasiCard extends StatelessWidget {
  final String jenis;
  final String nama;
  final String tanggal;
  final String? status;
  final Color? statusColor;
  final Color dotColor;
  final VoidCallback onTap;

  const NotifikasiCard({
    super.key,
    required this.jenis,
    required this.nama,
    required this.tanggal,
    required this.status,
    required this.statusColor,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: dotColor),
                    const SizedBox(width: 8),
                    Text(
                      jenis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (status != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Periode Cuti  :",
                        style: TextStyle(fontSize: 12)),
                    Text(
                      tanggal,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE65A3A),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
