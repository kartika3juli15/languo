import 'package:flutter/material.dart';
import 'package:languo/admin/verifikasi/cuti_verifikasi_admin_page.dart';
import 'package:languo/admin/home_page.dart';

class PengajuanCutiPage extends StatefulWidget {
  const PengajuanCutiPage({super.key});

  @override
  State<PengajuanCutiPage> createState() => _PengajuanCutiPageState();
}

class _PengajuanCutiPageState extends State<PengajuanCutiPage> {
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

  // =========================== HEADER ============================
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeAdmin(),
                  ),
                );
              },
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 10),
            Text("Cuti",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ========================= MENU PILIH ROLE =========================
  Widget _menuRole(String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifikasiCutiPage(role: role),
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
