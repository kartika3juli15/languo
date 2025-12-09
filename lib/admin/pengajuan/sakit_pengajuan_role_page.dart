import 'package:flutter/material.dart';
import 'package:languo/admin/verifikasi/sakit_verifikasi_admin_page.dart';
import 'package:languo/admin/home_page.dart';

class AdminSakitPage extends StatefulWidget {
  const AdminSakitPage({super.key});

  @override
  State<AdminSakitPage> createState() => _AdminSakitPageState();
}

class _AdminSakitPageState extends State<AdminSakitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _menuRole("Karyawan"),
          const SizedBox(height: 15),
          _menuRole("Dosen"),
        ],
      ),
    );
  }

  // ========================= HEADER =========================
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
      child: Stack(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeAdmin()),
                (route) => false,
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
        ),
        const Align(
          alignment: Alignment.center,
          child: Text(
            "Sakit",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }

  // ===================== MENU DINAMIS (ROLE) =====================
  Widget _menuRole(String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifikasiSakitPage(role: role),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6D51),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
