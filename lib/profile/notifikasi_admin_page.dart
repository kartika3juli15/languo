import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../admin/verifikasi/cuti_verifikasi_admin_page.dart';
import '../admin/verifikasi/izin_verifikasi_admin_page.dart';
import '../admin/verifikasi/sakit_verifikasi_admin_page.dart';
import 'package:rxdart/rxdart.dart';

class NotifikasiAdminPage extends StatefulWidget {
  const NotifikasiAdminPage({super.key});

  @override
  State<NotifikasiAdminPage> createState() => _NotifikasiAdminPageState();
}

class _NotifikasiAdminPageState extends State<NotifikasiAdminPage> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String query = searchController.text.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearch(),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: streamAllPengajuanUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  List data = snapshot.data!;

                  data = data.where((item) {
                    return item["jenis"].contains(query) ||
                        item["nama"].contains(query);
                  }).toList();

                  if (data.isEmpty)
                    return const Center(child: Text("Belum ada notifikasi"));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final item = data[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AdminNotifCard(
                          jenis: item["jenis"],
                          nama: item["nama"],
                          tanggal: item["tanggal"],
                          onTap: () {
                            if (item["jenis"] == "Pengajuan Cuti") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VerifikasiCutiPage(role: item["role"]),
                                ),
                              );
                            } else if (item["jenis"] == "Pengajuan Izin") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VerifikasiIzinPage(role: item["role"]),
                                ),
                              );
                            } else if (item["jenis"] == "Pengajuan Sakit") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VerifikasiSakitPage(role: item["role"]),
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

  // ===============================================================
  // STREAM 3 COLLECTION -> GABUNG & SORT DESC
  // ===============================================================

  Stream<List<Map<String, dynamic>>> streamAllPengajuanUser() {
    final cutiStream =
        FirebaseFirestore.instance.collection("pengajuan_cuti").snapshots();
    final izinStream =
        FirebaseFirestore.instance.collection("pengajuan_izin").snapshots();
    final sakitStream =
        FirebaseFirestore.instance.collection("pengajuan_sakit").snapshots();

    return Rx.combineLatest3<QuerySnapshot, QuerySnapshot, QuerySnapshot,
        List<Map<String, dynamic>>>(
      cutiStream,
      izinStream,
      sakitStream,
      (cutiSnap, izinSnap, sakitSnap) {
        List<Map<String, dynamic>> all = [];

        void addDocs(QuerySnapshot snap, String jenis) {
          for (var doc in snap.docs) {
            final d = doc.data() as Map<String, dynamic>;
            if (d["status"] != "Diajukan") continue;

            // Ambil start & end untuk display saja
            String tanggalDisplay = "-";
            if (d["tanggalMulai"] != null && d["tanggalSelesai"] != null) {
              final start = (d["tanggalMulai"] as Timestamp).toDate();
              final end = (d["tanggalSelesai"] as Timestamp).toDate();
              tanggalDisplay =
                  "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}";
            }

            all.add({
              "jenis": jenis == "Cuti"
                  ? "Pengajuan Cuti"
                  : jenis == "Izin"
                      ? "Pengajuan Izin"
                      : "Pengajuan Sakit",
              "nama": d["userName"] ?? "-",
              "email": d["emailUser"] ?? "-",
              "role": d["userRole"] ?? "-",
              "alasan": d["alasan"] ?? "",
              "perihal": d["perihal"] ?? "",
              "keterangan": d["keterangan"] ?? "",
              "sisaCuti": d["sisa_cuti_saat_pengajuan"] ?? 0,
              "tanggal": tanggalDisplay,
              "status": d["status"] ?? "-",
              "Lampiran": d["lampiranUrl"] ?? "",
              "createdAt": d["createdAt"] ?? Timestamp.now(),
            });
          }
        }

        addDocs(cutiSnap, "Cuti");
        addDocs(izinSnap, "Izin");
        addDocs(sakitSnap, "Sakit");

        // Urutkan berdasarkan createdAt terbaru
        all.sort((a, b) {
          final ca = a["createdAt"] as Timestamp;
          final cb = b["createdAt"] as Timestamp;
          return cb.millisecondsSinceEpoch.compareTo(ca.millisecondsSinceEpoch);
        });

        return all;
      },
    );
  }

  // ===============================================================
  // WIDGET UI TAMBAHAN
  // ===============================================================

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 140,
          decoration: const BoxDecoration(
            color: Color(0xFF36546C),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 70, left: 16, right: 16),
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

  Widget _buildSearch() {
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

// ===============================
// WIDGET CARD NOTIFIKASI ADMIN
// ===============================
class AdminNotifCard extends StatelessWidget {
  final String jenis;
  final String nama;
  final String tanggal;
  final VoidCallback onTap;

  const AdminNotifCard({
    super.key,
    required this.jenis,
    required this.nama,
    required this.tanggal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian kiri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      jenis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 22, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nama,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Periode:",
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  tanggal,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                )
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Tombol panah
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFE7633B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
