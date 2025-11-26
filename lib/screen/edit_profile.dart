import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

String hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();

  UserModel? user;
  bool isLoading = true;
  bool isSaving = false;

  File? pickedImage;

  Future<void> loadUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists) {
      user = UserModel.fromFirestore(doc);
      nameController.text = user!.userName;
      emailController.text = user!.userEmail;
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => pickedImage = File(picked.path));

    final firebaseUser = FirebaseAuth.instance.currentUser!;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("profile_images")
        .child("${firebaseUser.uid}.jpg");

    await storageRef.putFile(pickedImage!);
    final url = await storageRef.getDownloadURL();

    await firebaseUser.updatePhotoURL(url);
    await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .update({"user_photo": url});

    setState(() {}); // refresh foto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Foto profil berhasil diperbarui")),
    );
  }

  Future<void> updateProfile() async {
    if (user == null) return;
    setState(() => isSaving = true);

    final firebaseUser = FirebaseAuth.instance.currentUser!;
    final newName = nameController.text.trim();
    final oldPass = oldPassController.text.trim();
    final newPass = newPassController.text.trim();

    try {
      // Update Nama
      if (newName.isNotEmpty && newName != user!.userName) {
        await firebaseUser.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .update({"user_name": newName});
      }

      // Update Password
      if (oldPass.isNotEmpty || newPass.isNotEmpty) {
        if (oldPass.isEmpty || newPass.isEmpty) {
          throw "Password lama dan password baru wajib diisi.";
        }

        final encodedOld = hashPassword(oldPass);
        if (encodedOld != user!.userPass) {
          throw "Password lama tidak sesuai!";
        }

        final cred = EmailAuthProvider.credential(
          email: user!.userEmail,
          password: oldPass,
        );
        await firebaseUser.reauthenticateWithCredential(cred);
        await firebaseUser.updatePassword(newPass);

        final encodedNew = hashPassword(newPass);
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .update({"user_password": encodedNew});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Stack(
          children: [
            // Background solid AppBar
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF36546C),
              ),
            ),

            // Ikon buku di belakang tulisan Edit Profile
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.menu_book_rounded,
                size: 140,
                color: Colors.white.withOpacity(0.12),
              ),
            ),

            // AppBar transparan dengan tombol panah & title di depan ikon
            AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                "Edit Profile",
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // HEADER
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

                    // FOTO PROFIL DI DEPAN HEADER
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -50,
                      child: Center(
                        child: GestureDetector(
                          onTap: pickAndUploadImage,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: user?.userPhoto != null &&
                                          user!.userPhoto!.isNotEmpty
                                      ? NetworkImage(user!.userPhoto!)
                                      : null,
                                  backgroundColor: Colors.grey.shade300,
                                  child: (user?.userPhoto == null ||
                                          user!.userPhoto!.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade600,
                                        )
                                      : null,
                                ),
                              ),

                              // ICON EDIT CAMERA
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF36546C),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),
                Text(user?.userName ?? "",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(user?.userRole ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 25),

                // FORM
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInput(
                          Icons.person_outline,
                          nameController,
                          "Nama Lengkap",
                        ),
                        _buildInput(
                          Icons.email_outlined,
                          emailController,
                          "Email",
                          readOnly: true,
                        ),
                        _buildInput(
                          Icons.lock_outline,
                          oldPassController,
                          "Password Lama",
                          obscure: true,
                        ),
                        _buildInput(
                          Icons.lock_reset_outlined,
                          newPassController,
                          "Password Baru",
                          obscure: true,
                        ),

                        /// Jarak tambahan antara field terakhir & tombol simpan
                        const SizedBox(height: 40),

                        /// Tombol SIMPAN (margin lebih luas & konsisten)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20,
                              20), // ⬅ perbesar kanan–kiri & beri bawah
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B4A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  )
                                : const Text(
                                    "Simpan",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInput(
    IconData icon,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool readOnly = false,
  }) {
    // kontrol eye icon hanya kalau obscure = true
    final isObscure = ValueNotifier<bool>(obscure);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
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

          /// INPUT TEXT
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: isObscure,
              builder: (context, hide, _) {
                return TextField(
                  controller: controller,
                  obscureText: hide,
                  readOnly: readOnly,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,

                    /// hint tampil dulu & hilang saat user mengetik
                    hintText: controller.text.isEmpty ? label : null,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  onChanged: (_) {
                    // update UI biar hint hilang saat ada teks
                    setState(() {});
                  },
                );
              },
            ),
          ),

          /// EYE BUTTON (hanya untuk obscure field)
          if (obscure)
            ValueListenableBuilder<bool>(
              valueListenable: isObscure,
              builder: (context, hide, _) {
                return GestureDetector(
                  onTap: () => isObscure.value = !hide,
                  child: Icon(
                    hide
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 22,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
