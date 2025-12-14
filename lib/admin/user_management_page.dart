import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:languo/admin/tambah_user_page.dart';
import 'edit_profile_user.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  int selectedTab = 0;
  TextEditingController searchController = TextEditingController();
  int expandedIndex = -1;
  String keyword = "";

  Future<List<QueryDocumentSnapshot>> fetchUsers(String role) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user_role', isEqualTo: role)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs;
  }

  Future<void> updateUserPassword(String uid, String newPassword) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('updateUserPassword');

    final result = await callable.call({
      'uid': uid,
      'newPassword': newPassword,
    });

    if (result.data?['success'] != true) {
      throw Exception(
          "Gagal memperbarui password: Respons server tidak valid.");
    }
  }

  Future<void> updateUserEmail(String uid, String newEmail) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('updateUserEmail');

    final result = await callable.call({
      'uid': uid,
      'newEmail': newEmail,
    });

    // Cloud Function Anda mengembalikan { success: true } saat berhasil
    if (result.data?['success'] != true) {
      throw Exception(
          "Gagal memperbarui email Auth: Respons server tidak valid.");
    }
  }

  Future<void> deleteUserAuth(String uid) async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
    await callable.call({
      'uid': uid,
    });
  }

  void _showDeleteConfirmationDialog(QueryDocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus User Permanen"),
        content: const Text(
            "Apakah Anda yakin ingin menghapus user ini? Tindakan ini akan menghapus data dari Auth dan Firestore."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await deleteUserAuth(user.id); // panggil cloud function

                // Setelah berhasil hapus di Auth & Firestore
                if (!mounted) return;
                Navigator.pop(context); // tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("User berhasil dihapus secara permanen")),
                );
                setState(() {}); // refresh list
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal menghapus user: $e")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
          _buildHeader(),
          _buildTabBar(),
          searchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                "Tambah ${selectedTab == 0 ? "Dosen" : "Karyawan"}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1666A9),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TambahUserPage(
                        role: selectedTab == 0 ? "Dosen" : "Karyawan"),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: fetchUsers(selectedTab == 0 ? "Dosen" : "Karyawan"),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1666A9),
                    ),
                  );
                }

                final users = snapshot.data!;

                final filteredUsers = users.where((user) {
                  final name =
                      (user['user_name'] ?? "").toString().toLowerCase();
                  final email =
                      (user['user_email'] ?? "").toString().toLowerCase();

                  return keyword.isEmpty ||
                      name.contains(keyword) ||
                      email.contains(keyword);
                }).toList();
                if (filteredUsers.isEmpty) {
                  return const Center(
                      child: Text(
                    "User tidak ditemukan",
                    style: TextStyle(color: Colors.grey),
                  ));
                }

                // Bagian 2: Ganti seluruh blok ListView.builder Anda dengan kode ini

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    final name = user['user_name'] ?? "";
                    final email = user['user_email'] ?? "";
                    final photoUrl = user['user_photo'] ?? "";
                    final num sisaCuti = (user['sisa_cuti'] ?? 0) as num;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          "$email • Sisa cuti: $sisaCuti hari",
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfileUserPage(uid: user.id),
                                  ),
                                );
                              },
                            ),
                            // START MODIFIKASI HAPUS
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    user); // Panggil fungsi konfirmasi
                              },
                            ),
                            // END MODIFIKASI HAPUS
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== HEADER =====
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
              "Manajemen User",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===== TABBAR =====
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
                    _tabButton("Dosen", 0),
                    _tabButton("Karyawan", 1),
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
        onTap: () => setState(() => selectedTab = index),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

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
