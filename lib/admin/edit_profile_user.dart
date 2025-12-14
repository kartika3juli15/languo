import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EditProfileUserPage extends StatefulWidget {
  final String uid;

  const EditProfileUserPage({super.key, required this.uid});

  @override
  State<EditProfileUserPage> createState() => _EditProfileUserPageState();
}

class _EditProfileUserPageState extends State<EditProfileUserPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final sisaCutiController = TextEditingController();

  String? photoUrl;
  Uint8List? pickedImageBytes;

  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;
  String? userRole; // Tambahkan untuk menampilkan role user

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    if (doc.exists) {
      nameController.text = doc['user_name'] ?? '';
      emailController.text = doc['user_email'] ?? '';
      sisaCutiController.text = (doc['sisa_cuti'] ?? 0).toString();
      photoUrl = doc['user_photo'];
      userRole = doc['user_role'] ?? 'User';
    }

    setState(() => isLoading = false);
  }

  // ===================== UPLOAD FOTO =====================
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Cek ekstensi
    final mime = picked.mimeType;
    final extName = picked.name.toLowerCase();

    if (!((mime?.startsWith("image/") ?? false) ||
        extName.endsWith(".png") ||
        extName.endsWith(".jpg") ||
        extName.endsWith(".jpeg") ||
        extName.endsWith(".webp") ||
        extName.endsWith(".gif"))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yang di-upload harus file gambar")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final ext = picked.name.split('.').last.toLowerCase();
      final userFolder = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(widget.uid);
      final ref = userFolder.child('profile.$ext');

      // hapus foto lama
      try {
        final list = await userFolder.listAll();
        for (var f in list.items) {
          await f.delete();
        }
      } catch (_) {}

      if (kIsWeb) {
        pickedImageBytes = await picked.readAsBytes();
        await ref.putData(pickedImageBytes!);
      } else {
        await ref.putFile(File(picked.path));
        pickedImageBytes = await File(picked.path).readAsBytes();
      }

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'user_photo': downloadUrl});

      setState(() => photoUrl = downloadUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil user berhasil diperbarui")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal upload: $e")));
    }

    setState(() => isUploading = false);
  }

  // ===================== SIMPAN =====================
  Future<void> saveChanges() async {
    setState(() => isSaving = true);

    try {
      final updates = <String, dynamic>{
        'user_name': nameController.text.trim(),
        'sisa_cuti': int.tryParse(sisaCutiController.text) ?? 0,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(updates);

      // update email Auth
      if (emailController.text.isNotEmpty) {
        await FirebaseFunctions.instance.httpsCallable('updateUserEmail').call({
          'uid': widget.uid,
          'newEmail': emailController.text.trim(),
        });
      }

      // update password Auth
      if (passwordController.text.isNotEmpty) {
        await FirebaseFunctions.instance
            .httpsCallable('updateUserPassword')
            .call({
          'uid': widget.uid,
          'newPassword': passwordController.text.trim(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil user berhasil diperbarui")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? profileImage;

    if (pickedImageBytes != null) {
      profileImage = MemoryImage(pickedImageBytes!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      profileImage = NetworkImage(photoUrl!);
    } else {
      profileImage = null;
    }

    return Scaffold(
      backgroundColor: Colors.white,

      /// ================= APPBAR SEDERHANA =================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF36546C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profil",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// ================= HEADER BAWAH =================
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
                    ),

                    /// FOTO PROFIL FLOATING
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -50,
                      child: Center(
                        child: GestureDetector(
                          onTap: pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: profileImage,
                                  backgroundColor: Colors.grey.shade300,
                                  child: profileImage == null
                                      ? Icon(Icons.person,
                                          size: 50, color: Colors.grey.shade600)
                                      : null,
                                ),
                              ),

                              /// OVERLAY LOADING UPLOAD
                              if (isUploading)
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              /// ICON CAMERA
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFF36546C),
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                /// ================= FORM =================
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
                        ),
                        _buildInput(
                          Icons.lock_reset_outlined,
                          passwordController,
                          "Password Baru",
                          obscure: true,
                        ),
                        _buildInput(
                          Icons.event_available_outlined,
                          sisaCutiController,
                          "Sisa Cuti",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveChanges,
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
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
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
        ),
      ),
    );
  }

  // Widget _buildInput yang baru (sesuai kode EditProfilePage)
  Widget _buildInput(
    IconData icon,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: controller.text.isEmpty ? label : null,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  onChanged: (_) {
                    // update UI agar hint hilang saat ada teks
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
