import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:languo/admin/rekapan/cuti_rekapan_admin_page.dart';
import 'package:languo/admin/pengajuan/cuti_pengajuan_role_page.dart';

class VerifikasiCutiPage extends StatefulWidget {
  final String role;

  const VerifikasiCutiPage({super.key, required this.role});

  @override
  State<VerifikasiCutiPage> createState() => _VerifikasiCutiPageState();
}

class _VerifikasiCutiPageState extends State<VerifikasiCutiPage> {
  int selectedTab = 0;
  TextEditingController searchController = TextEditingController();
  int expandedIndex = -1;
  String keyword = "";

  final Map<int, String> bulan = {
    1: "Jan",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "Mei",
    6: "Jun",
    7: "Jul",
    8: "Agu",
    9: "Sep",
    10: "Okt",
    11: "Nov",
    12: "Des",
  };

  // Stream data cuti
  Stream<QuerySnapshot> getPengajuanCuti() {
    return FirebaseFirestore.instance
        .collection('pengajuan_cuti')
        .where('status', isEqualTo: 'Diajukan')
        .where('user_role', isEqualTo: widget.role)
        .snapshots();
  }

  // CARD LIST (collapsed / expanded)
  Widget cutiTile(Map<String, dynamic> data, String id, int index) {
    DateTime mulai = (data['tanggal_mulai'] as Timestamp).toDate();
    DateTime selesai = (data['tanggal_selesai'] as Timestamp).toDate();

    final isExpanded = expandedIndex == index;

    // collapsed
    if (!isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => expandedIndex = index),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['user_name'] ?? "-",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    const Text("Periode Cuti :",
                        style: TextStyle(fontSize: 12)),
                    Text(
                      "${mulai.day} ${bulan[mulai.month]} ${mulai.year} s.d ${selesai.day} ${bulan[selesai.month]} ${selesai.year}",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFA86F),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text("Diajukan",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 225, 98, 19),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12)),
                    ),
                    child: const Center(
                        child: Icon(Icons.chevron_right,
                            color: Colors.white, size: 20)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // expanded
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['user_name'] ?? "-",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text("Diajukan",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      onPressed: () => setState(() => expandedIndex = -1),
                      icon: const Icon(Icons.close))
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text("Periode Cuti :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
              "${mulai.day} ${bulan[mulai.month]} ${mulai.year} s.d ${selesai.day} ${bulan[selesai.month]} ${selesai.year}"),
          const SizedBox(height: 8),
          const Text("Alasan :", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(data['alasan'] ?? "-"),
          const SizedBox(height: 8),
          const Text("Keterangan :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(data['keterangan'] ?? "-"),
          const SizedBox(height: 8),
          const Text("Alamat Email :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(data['user_email'] ?? "-"),
          const SizedBox(height: 14),

          // buka file
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = data['lampiran_url'];
                if (url == null || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("File tidak tersedia")));
                  return;
                }
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.insert_drive_file, color: Colors.white),
              label: const Text("File",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFE4572E)),
            ),
          ),
          const SizedBox(height: 16),

          // tombol verifikasi
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // tolak
              ElevatedButton(
                onPressed: () => showRejectConfirm(context, id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child:
                    const Text("TOLAK", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              // terima
              ElevatedButton(
                onPressed: () async {
                  final String userId = data['user_id'];

                  // Ambil tanggal mulai & selesai
                  DateTime mulai =
                      (data['tanggal_mulai'] as Timestamp).toDate();
                  DateTime selesai =
                      (data['tanggal_selesai'] as Timestamp).toDate();

                  // Hitung jumlah hari cuti (inklusif)
                  int lamaCuti = selesai.difference(mulai).inDays + 1;

                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();

                  int sisaCuti = userDoc['sisa_cuti'] ?? 0;
                  int sisaBaru = (sisaCuti - lamaCuti);
                  if (sisaBaru < 0) sisaBaru = 0; // supaya tidak minus

                  // Update status cuti + tanggal verifikasi
                  await FirebaseFirestore.instance
                      .collection('pengajuan_cuti')
                      .doc(id)
                      .update({
                    "status": "Disetujui",
                    "tanggal_verifikasi": Timestamp.now(),
                  });

                  // Update sisa cuti user
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({
                    "sisa_cuti": sisaBaru,
                  });

                  showSuccessPopup(context);
                  setState(() => expandedIndex = -1);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF36546C)),
                child:
                    const Text("TERIMA", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          header(),
          _buildTabBar(),
          searchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPengajuanCuti(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Tidak ada pengajuan cuti"));
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  if (keyword.isEmpty) return true;
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['user_name'] ?? '').toString().toLowerCase();
                  final email =
                      (d['user_email'] ?? '').toString().toLowerCase();
                  final alasan = (d['alasan'] ?? '').toString().toLowerCase();
                  return name.contains(keyword) ||
                      email.contains(keyword) ||
                      alasan.contains(keyword);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("Tidak ditemukan"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    return cutiTile(
                        doc.data() as Map<String, dynamic>, doc.id, i);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =============== HEADER
  Widget header() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF36546C),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PengajuanCutiPage(),
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
                    builder: (_) => const PengajuanCutiPage(),
                  ),
                );
              },
              child: Text(
                "Cuti  <  ${widget.role}",
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
    );
  }

  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(40)),
        child: LayoutBuilder(
          builder: (context, cons) {
            final w = cons.maxWidth / 2;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  left: selectedTab == 0 ? 0 : w,
                  child: Container(
                    width: w,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.deepOrange, Colors.redAccent]),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _tabButton("Pengajuan", 0),
                    _tabButton("Rekapan", 1),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RekapanAdminCutiPage(role: widget.role),
                ));
          } else {
            setState(() => selectedTab = index);
          }
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
                color:
                    selectedTab == index ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
        ),
      ),
    );
  }

  // =============== SEARCH
  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: Color(0xFF9FB0BD), borderRadius: BorderRadius.circular(12)),
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

  // =============== POPUP SUCCESS
  void showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(15),
                decoration:
                    BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 45)),
            const SizedBox(height: 20),
            const Text("Pengajuan telah disetujui",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // =============== POPUP TOLAK
  void showRejectConfirm(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Apakah Anda yakin ingin menolak?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Text("Tidak",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance
                        .collection('pengajuan_cuti')
                        .doc(id)
                        .update({
                      "status": "Ditolak",
                      "tanggal_verifikasi": Timestamp.now(),
                    });
                    showRejectSuccess(context);
                    setState(() => expandedIndex = -1);
                  },
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                        color: Color(0xFF36546C),
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Text("Ya",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void showRejectSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(15),
                decoration:
                    BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 45)),
            const SizedBox(height: 20),
            const Text("Pengajuan telah ditolak",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
