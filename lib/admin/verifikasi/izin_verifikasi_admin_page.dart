import 'package:flutter/material.dart';
import 'package:languo/admin/rekapan/izin_rekapan_admin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:languo/admin/pengajuan/izin_pengajuan_role_page.dart';

class VerifikasiIzinPage extends StatefulWidget {
  final String role; // menerima role dari halaman sebelumnya

  const VerifikasiIzinPage({super.key, required this.role});

  @override
  State<VerifikasiIzinPage> createState() => _VerifikasiIzinPageState();
}

class _VerifikasiIzinPageState extends State<VerifikasiIzinPage> {
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

  Stream<QuerySnapshot> getPengajuanIzin() {
    return FirebaseFirestore.instance
        .collection('pengajuan_izin')
        .where('status', isEqualTo: 'Diajukan')
        .where('user_role', isEqualTo: widget.role)
        .snapshots();
  }

  // ====================== WIDGET KARTU (collapsed / expanded) ======================
  Widget izinTile(Map<String, dynamic> data, String id, int index) {
    DateTime mulai = (data['tanggal_mulai'] as Timestamp).toDate();
    DateTime selesai = (data['tanggal_selesai'] as Timestamp).toDate();

    final isExpanded = expandedIndex == index;

    // Collapsed card (small)
    if (!isExpanded) {
      return GestureDetector(
        onTap: () {
          setState(() {
            expandedIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // info left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['user_name'] ?? "-",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Periode Izin :",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 3, 3, 3),
                      ),
                    ),
                    Text(
                      "${mulai.day} ${bulan[mulai.month]} ${mulai.year} s.d ${selesai.day} ${bulan[selesai.month]} ${selesai.year}",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),

              // badge and arrow
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 197, 111),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Diajukan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(
                          255, 225, 98, 19), // oranye muda seperti mockup
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: Color.fromARGB(255, 232, 227, 227),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Expanded card (detail)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['user_name'] ?? "-",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 242, 156, 27), // ⬅ ubah jadi oranye
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Diajukan",
                      style: TextStyle(
                        color: Colors.white, // ⬅ teks putih
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() => expandedIndex = -1);
                    },
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  )
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // details like mockup
          const Text("Periode Izin :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
              "${mulai.day} ${bulan[mulai.month]} ${mulai.year} s.d ${selesai.day} ${bulan[selesai.month]} ${selesai.year}"),
          const SizedBox(height: 8),

          const Text("Perihal :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(data['perihal'] ?? "-"),
          const SizedBox(height: 8),
          const Text("Keterangan :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(data['keterangan'] ?? "-"),
          const SizedBox(height: 8),
          const Text("Alamat Email :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            data['user_email'] ?? "-",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // file button (full width)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = data['lampiran_url'];
                if (url == null || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("File tidak tersedia")),
                  );
                  return;
                }

                final uri = Uri.parse(url);
                if (!await launchUrl(uri,
                    mode: LaunchMode.externalApplication)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal membuka file")),
                  );
                }
              },
              icon: const Icon(
                Icons.insert_drive_file,
                color: Colors.white, // ⬅ ICON PUTIH
                size: 30,
              ),
              label: const Text(
                "File",
                style: TextStyle(
                  color: Colors.white, // ⬅ TEKS PUTIH
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE4572E), // ⬅ ORANYE
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // taruh di kanan
            children: [
              // BUTTON TOLAK
              ElevatedButton(
                onPressed: () {
                  showRejectConfirm(context, id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 238, 64, 45), // warna oranye
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "TOLAK",
                  style: TextStyle(color: Colors.white), // teks putih
                ),
              ),

              const SizedBox(width: 12),

              // BUTTON TERIMA
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('pengajuan_izin')
                      .doc(id)
                      .update({
                    "status": "Disetujui",
                    "tanggal_verifikasi": Timestamp.now(),
                  });
                  showSuccessPopup(context);
                  setState(() => expandedIndex = -1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF36546C), // biru gelap
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "TERIMA",
                  style: TextStyle(color: Colors.white), // teks putih
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================== POPUP TERIMA ======================
  void showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 45),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pengajuan telah disetujui",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text("OK", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================== POPUP KONFIRM TOLAK (update firestore ketika YA) ======================
  void showRejectConfirm(BuildContext context, String id) {
    final currentContext = context; // simpan context yang valid

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Apakah Anda yakin ingin menolak?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Tidak",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context); // tutup dialog dulu
                          try {
                            await FirebaseFirestore.instance
                                .collection('pengajuan_izin')
                                .doc(id)
                                .update({
                              "status": "Ditolak",
                              "tanggal_verifikasi": Timestamp.now(),
                            });

                            // cek apakah widget masih mounted
                            if (!mounted) return;

                            // pakai context yang valid
                            showRejectSuccess(currentContext);

                            setState(() => expandedIndex = -1);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(content: Text('Gagal menolak: $e')),
                            );
                          }
                        },
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF36546C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Ya",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================== POPUP TOLAK SUKSES ======================
  void showRejectSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 45),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pengajuan telah ditolak",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text("OK", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================== UI ======================
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
              stream: getPengajuanIzin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Tidak ada pengajuan izin"));
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  if (keyword.isEmpty) return true;
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['user_name'] ?? '').toString().toLowerCase();
                  final email =
                      (d['user_email'] ?? '').toString().toLowerCase();
                  final perihal = (d['periha;'] ?? '').toString().toLowerCase();
                  return name.contains(keyword) ||
                      email.contains(keyword) ||
                      perihal.contains(keyword);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("Tidak ditemukan"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    return izinTile(
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

  // HEADER (DINAMIC ROLE)
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
            mainAxisSize: MainAxisSize.min,
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

  // TAB BAR
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
            String role = widget.role; // role dari halaman sebelumnya

            // ⬇ jika role tidak ditemukan, default ke dosen
            if (role != "Admin" && role != "Karyawan" && role != "Dosen") {
              role = "Dosen";
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RekapanAdminIzinPage(role: role),
              ),
            );
            return;
          }

          // Untuk tab pengajuan
          setState(() => selectedTab = index);
        },
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // SEARCH BAR
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
                onChanged: (value) =>
                    setState(() => keyword = value.toLowerCase()),
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
}
