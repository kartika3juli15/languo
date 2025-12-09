import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:languo/admin/verifikasi/izin_verifikasi_admin_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:languo/admin/pengajuan/izin_pengajuan_role_page.dart';

class RekapanAdminIzinPage extends StatefulWidget {
  final String role;

  const RekapanAdminIzinPage({super.key, required this.role});

  @override
  State<RekapanAdminIzinPage> createState() => _RekapanAdminIzinPageState();
}

class _RekapanAdminIzinPageState extends State<RekapanAdminIzinPage> {
  int selectedTab = 1; // langsung ke REKAPAN
  TextEditingController searchController = TextEditingController();
  int expandedIndex = -1;

  String keyword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          header(),
          _buildTabBar(),
          searchBar(),
          Expanded(child: buildRekapanStream()),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AMBIL DATA FIRESTORE → status Disetujui / Ditolak
  // -------------------------------------------------------------------------

  Stream<QuerySnapshot> getRekapanIzin() {
    return FirebaseFirestore.instance
        .collection("pengajuan_izin")
        .where("status", whereIn: ["Disetujui", "Ditolak"])
        .where("user_role", isEqualTo: widget.role) // filter role sesuai
        .snapshots();
  }

  // -------------------------------------------------------------------------
  // STREAMBUILDER
  // -------------------------------------------------------------------------

  Widget buildRekapanStream() {
    return StreamBuilder(
      stream: getRekapanIzin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Belum ada rekapan izin.",
                style: TextStyle(color: Colors.grey)),
          );
        }

        // FILTER pencarian
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final nama = (doc["user_name"] ?? "").toString().toLowerCase();
          return nama.contains(keyword);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return IzinCard(filteredDocs[index], index);
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // UI HEADER
  // -------------------------------------------------------------------------

  Widget header() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF36546C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PengajuanIzinPage(),
                    ),
                  );
                },
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PengajuanIzinPage(),
                    ),
                  );
                },
                child: Text(
                  "Izin  <  ${widget.role}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB BAR
  // -------------------------------------------------------------------------

  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(40),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  left: selectedTab == 0 ? 0 : tabWidth,
                  child: Container(
                    height: 55,
                    width: tabWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepOrange, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _tab("Pengajuan", 0),
                    _tab("Rekapan", 1),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tab(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifikasiIzinPage(role: widget.role),
              ),
            );
          } else {
            setState(() => selectedTab = index);
          }
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? Colors.white : Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SEARCH BAR
  // -------------------------------------------------------------------------

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF9FB0BD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => keyword = v.toLowerCase()),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Cari Pengguna....",
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const Icon(Icons.search, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // CARD IZIN
  // -------------------------------------------------------------------------

  Widget IzinCard(DocumentSnapshot doc, int index) {
    bool isExpanded = expandedIndex == index;

    final data = doc.data() as Map<String, dynamic>;

    // Ambil field dari Firestore
    final nama = data["user_name"] ?? "-";
    final email = data["user_email"] ?? "-";
    final keterangan = data["keterangan"] ?? "-";
    final perihal = data["perihal"] ?? "-";
    final file = data["lampiran_url"] ?? "";
    final status = data["status"] ?? "-";

    final mulai = (data["tanggal_mulai"] as Timestamp).toDate();
    final selesai = (data["tanggal_selesai"] as Timestamp).toDate();
    final tanggalVerifikasiTimestamp = data["tanggal_verifikasi"] as Timestamp?;
    final tanggalVerifikasi = tanggalVerifikasiTimestamp != null
        ? tanggalVerifikasiTimestamp.toDate()
        : null;

    Color badgeColor = status == "Disetujui" ? Colors.green : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(207, 237, 236, 236),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_today, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text("Periode Izin :",
                        style: TextStyle(color: Colors.black54)),
                    Text(
                      "${format(mulai)}  s.d  ${format(selesai)}",
                      style: const TextStyle(
                        color: Color(0xFFDA3B26),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),

                  // EXPAND BUTTON
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        expandedIndex = isExpanded ? -1 : index;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDA3B26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (isExpanded) ...[
            const SizedBox(height: 15),
            detailRow("Alamat Email :", email),
            detailRow("Perihal :", perihal),
            detailRow("Keterangan :", keterangan),
            detailRow(
              "Tanggal Verifikasi :",
              tanggalVerifikasi != null
                  ? "${[
                      "Senin",
                      "Selasa",
                      "Rabu",
                      "Kamis",
                      "Jumat",
                      "Sabtu",
                      "Minggu"
                    ][tanggalVerifikasi.weekday - 1]}, "
                      "${tanggalVerifikasi.day.toString().padLeft(2, '0')} "
                      "${[
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
                    ][tanggalVerifikasi.month - 1]} "
                      "${tanggalVerifikasi.year}\n"
                      "Waktu: "
                      "${tanggalVerifikasi.hour.toString().padLeft(2, '0')}:"
                      "${tanggalVerifikasi.minute.toString().padLeft(2, '0')}:"
                      "${tanggalVerifikasi.second.toString().padLeft(2, '0')}"
                  : "-",
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(file);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Tidak bisa membuka file")),
                  );
                }
              },
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.white),
                    SizedBox(width: 8),
                    Text("File", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection("pengajuan_izin")
                        .doc(doc.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Data berhasil dihapus")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal menghapus: $e")),
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    "Hapus",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  // FORMAT TANGGAL
  String format(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }
}
