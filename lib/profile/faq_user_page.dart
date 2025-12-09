import 'package:flutter/material.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  TextEditingController searchController = TextEditingController();
  String keyword = "";

  final List<Map<String, dynamic>> faqList = [
    {
      "icon": Icons.live_help_outlined,
      "title": "Apa itu Aplikasi Languo SIAKU?",
      "subtitle":
          "Languo Siaku adalah singkatan dari Language Go Sistem Informasi Absensi Kursus, yang diperuntukkan untuk absensi di kursus bahasa.",
    },
    {
      "icon": Icons.featured_play_list_outlined,
      "title": "Fitur apa saja pada Languo SIAKU?",
      "subtitle":
          "Aplikasi menyediakan fitur absensi, laporan kehadiran, manajemen kursus, dan monitoring siswa.",
    },
    {
      "icon": Icons.error_outline,
      "title": "Jika terjadi error seperti tidak bisa login, penyebabnya apa?",
      "subtitle":
          "Biasanya karena koneksi internet tidak stabil, akun tidak terdaftar, atau server sedang maintenance.",
    }
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

                  // Menampilkan hasil FAQ
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

  // =====================================================
  // HEADER
  // =====================================================
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
              "FAQ",
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
              child: Icon(
                Icons.menu_book,
                color: Colors.white54,
                size: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SEARCH BAR DENGAN LOGIC
  // =====================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF7F9FB4), // WARNA KOTAK
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: Colors.white, // ICON PUTIH
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white), // TEKS PUTIH
                onChanged: (value) {
                  setState(() => keyword = value.toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: "Cari...",
                  hintStyle: TextStyle(color: Colors.white70), // HINT PUTIH
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FAQ EXPANSION CARD
  // =====================================================
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

        // Icon bulat oranye
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
