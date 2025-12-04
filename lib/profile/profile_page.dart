import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../screen/edit_profile.dart';
import '../../routes/routes_manager.dart';
import '../../screen/qr_scanner_screen.dart';
import '../users/karyawan/home_page.dart';
import '../users/dosen/home_page.dart';
import '../admin/home_page.dart';
import 'notifikasi_page.dart';
import 'pengaturan_page.dart';
import 'faq_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<UserModel?> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF36546C),
              ),
            ),

            // Ikon buku di belakang teks
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.menu_book_rounded,
                size: 140,
                color: Colors.white.withOpacity(0.12),
              ),
            ),

            // Title AppBar di depan ikon
            AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: const Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      body: FutureBuilder<UserModel?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Data user tidak ditemukan"));
          }
          final user = snapshot.data!;

          return Column(
            children: [
              // Header dengan background
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: Color(0xFF36546C),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: -56,
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 140,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Picture - positioned to overlap header
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -50,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: user.userPhoto != null
                              ? NetworkImage(user.userPhoto!)
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          child: user.userPhoto == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade600,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Name and Role
              Text(
                user.userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.userRole,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _menuItem(
                      Icons.edit_outlined,
                      "Edit Profil",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage()),
                        );
                      },
                    ),
                    _menuItem(
                      Icons.notifications_outlined,
                      "Notifikasi",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotifikasiPage()),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.settings_outlined,
                      "Pengaturan",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PengaturanPage()),
                        );
                      },
                    ),

                    _menuItem(
                      Icons.help_outline,
                      "FAQ",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FaqPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    // Log Out Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B4A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF36546C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget getHomeByRole(String role) {
    switch (role) {
      case "Karyawan":
        return const HomeKaryawan();
      case "Admin":
        return const HomeAdmin();
      case "Dosen":
        return const HomeDosen();
      default:
        return const HomeKaryawan();
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  // ambil data user dari Firestore
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get();

                  final userRole = userDoc['user_role'];
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => getHomeByRole(userRole)),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_outlined,
                        color: Colors.grey[400], size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "Beranda",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 28, color: Color(0xFF36546C)),
                  SizedBox(height: 4),
                  Text(
                    "Profile",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF36546C),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        Positioned(
          top: -28,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerPage()),
              );
            },
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF36546C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF36546C).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}