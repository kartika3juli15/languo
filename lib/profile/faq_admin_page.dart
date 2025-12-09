import 'package:flutter/material.dart';

class FaqAdminPage extends StatefulWidget {
  const FaqAdminPage({super.key});

  @override
  State<FaqAdminPage> createState() => _FaqAdminPageState();
}

class _FaqAdminPageState extends State<FaqAdminPage> {
  TextEditingController searchController = TextEditingController();
  String keyword = "";

  final List<Map<String, dynamic>> faqList = [
    {
      "icon": Icons.people_alt_outlined,
      "title": "Bagaimana cara menambahkan user baru?",
      "subtitle": "Masuk ke menu Manajemen User → Tambah User → Isi data lengkap → Simpan.",
    },
    {
      "icon": Icons.lock_reset,
      "title": "Bagaimana mereset password user?",
      "subtitle":
          "Buka Manajemen User → pilih user → Reset Password. User akan mendapatkan password baru.",
    },
    {
      "icon": Icons.approval,
      "title": "Bagaimana menyetujui atau menolak cuti karyawan?",
      "subtitle":
          "Masuk menu Pengajuan Cuti → pilih pengajuan → klik Setujui atau Tolak.",
    },
    {
      "icon": Icons.print_outlined,
      "title": "Bagaimana export data absensi?",
      "subtitle":
          "Masuk halaman Laporan Absensi → pilih tanggal → klik Export ke Excel atau PDF.",
    },
    {
      "icon": Icons.error_outline,
      "title": "Bagaimana jika terdapat kesalahan absensi (double scan)?",
      "subtitle":
          "Admin dapat menghapus atau mengoreksi absensi melalui menu Riwayat Absensi.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // FILTER DATA FAQ
    List filteredFaq = faqList.where((item) {
      final title = item["title"].toString().toLowerCase();
      final sub = item["subtitle"].toString().toLowerCase();
      return title.contains(keyword) || sub.contains(keyword);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // LIST
                  for (var item in filteredFaq) ...[
                    _faqItem(
                      icon: item["icon"],
                      title: item["title"],
                      subtitle: item["subtitle"],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (filteredFaq.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        "Tidak ada hasil ditemukan...",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context) {
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
              "FAQ Admin",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child:
                  Icon(Icons.admin_panel_settings, color: Colors.white54, size: 80),
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF7F9FB4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => keyword = value.toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: "Cari...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD FAQ
  Widget _faqItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            color: Color(0xFFFF7043),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
