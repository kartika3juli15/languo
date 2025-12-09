import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../screen/edit_profile.dart';
import 'package:languo/screen/buat_qr.dart';
import '../users/home_page.dart';
import '../admin/home_page.dart';
import 'notifikasi_user_page.dart';
import 'notifikasi_admin_page.dart';
import 'faq_user_page.dart';
import 'faq_admin_page.dart';
import 'logout_dialog.dart';
import '../screen/qr_scanner_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _lastScannedData;
  String? userRole; // nilai role (mis. "Admin" / "Karyawan" / "Dosen" dll)

  late Future<UserModel?> futureUser;

  @override
  void initState() {
    super.initState();
    // panggil sekali
    futureUser = getUserData();
  }

  /// Ambil user model dan juga baca field role dari Firestore.
  /// Mencoba beberapa nama field (user_role / userRole) dan fallback ke UserModel.
  Future<UserModel?> getUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    final roleFromDb = data['user_role'] ?? data['userRole'];
    final String? roleString = roleFromDb is String ? roleFromDb : null;

    // update & rebuild UI (BOTTOM NAV)
    if (mounted) {
      setState(() {
        userRole = roleString;
      });
    }

    return UserModel.fromFirestore(doc);
  }

  // helper: apakah role saat ini adalah admin? (case-insensitive)
  bool get _isAdmin {
    return (userRole ?? "").toLowerCase() == "admin";
  }

  Widget getHomeByRole(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return const HomeAdmin();
      default:
        return const HomePageUser();
    }
  }

  Future<void> _goToHome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};
    final role =
        (data['user_role'] ?? data['userRole'] ?? 'Karyawan') as String;
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => getHomeByRole(role)));
  }

  void _goToProfile() {
    // already on profile, no-op
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
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.menu_book_rounded,
                size: 140,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
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
        future: futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Data user tidak ditemukan"));
          }

          final user = snapshot.data!;

          // Jika userRole belum terisi (null) -> coba isi dari model user
          // dan panggil setState sekali untuk memaksa rebuild bottom nav.
          if ((userRole == null || userRole!.isEmpty) && mounted) {
            final fallback = user.userRole;
            // setState via postFrame agar tidak di-call di tengah build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                // prefer role yang sudah kita baca dari Firestore (userRole),
                // kalau null, pakai UserModel.userRole
                userRole = (userRole != null && userRole!.isNotEmpty)
                    ? userRole
                    : fallback;
              });
            });
          }

          return Column(
            children: [
              // Header
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

                  // Profile Picture
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -50,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
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

              // Name and Role text
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

              // Menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _menuItem(Icons.edit_outlined, "Edit Profil", () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage()));
                    }),
                    _menuItem(Icons.notifications_outlined, "Notifikasi", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              (user.userRole.toLowerCase() == 'admin')
                                  ? const NotifikasiAdminPage()
                                  : const NotifikasiPage(),
                        ),
                      );
                    }),
                    _menuItem(Icons.help_outline, "FAQ", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              (user.userRole.toLowerCase() == 'admin')
                                  ? const FaqAdminPage()
                                  : const FaqPage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          LogoutDialog.show(context);
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
              child: Icon(icon, color: Colors.white, size: 22),
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
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 20,
              child: Container(
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
                      onTap: _goToHome,
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
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.person,
                              size: 28, color: Color(0xFF36546C)),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // floating center button: icon berdasarkan userRole
            Positioned(
              top: -20,
              child: GestureDetector(
                onTap: () async {
                  // jika belum ada userRole, boleh tampilkan default behaviour tapi di sini kita cegah
                  if (userRole == null) return;

                  if (_isAdmin) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BuatQRPage()),
                    );
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScannerPage()),
                    );

                    if (!mounted) return;
                    if (result != null) {
                      setState(() => _lastScannedData = result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("QR Code berhasil dipindai!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF36546C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Icon(
                    // Perbandingan tanpa case-sensitivity
                    _isAdmin ? Icons.add : Icons.qr_code_scanner,
                    color: Colors.white,
                    size: _isAdmin ? 38 : 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
