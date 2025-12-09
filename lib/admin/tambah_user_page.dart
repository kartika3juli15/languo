import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class TambahUserPage extends StatefulWidget {
  final String role;

  const TambahUserPage({super.key, required this.role});

  @override
  State<TambahUserPage> createState() => _TambahUserPageState();
}

class _TambahUserPageState extends State<TambahUserPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  Future<void> tambahUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // VALIDASI
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi.")),
      );
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid.")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Generate UID di Cloud Function (optional)
      final callable =
          FirebaseFunctions.instance.httpsCallable('createUserWithPassword');
      final result = await callable.call({
        "email": email,
        "password": password,
        "role": widget.role,
        "name": name,
      });

      if (result.data['success'] != true) {
        throw Exception("Respons Cloud Function tidak valid.");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User berhasil ditambahkan")),
      );
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      // Error spesifik dari Cloud Function
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal membuat CLOUD (${e.code}): ${e.message}",
          ),
        ),
      );
    } catch (e) {
      // Error umum
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat UMUM: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF36546C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  top: 50,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                  ),
                ),
                const Center(
                  child: Text(
                    "Tambah User",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Tambah ${widget.role}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _inputField(
                    icon: Icons.person_outline,
                    hint: "Nama User",
                    controller: nameController,
                  ),
                  _inputField(
                    icon: Icons.email_outlined,
                    hint: "Email",
                    controller: emailController,
                  ),
                  _inputField(
                    icon: Icons.lock_outline,
                    hint: "Password",
                    controller: passwordController,
                    obscure: !showPassword,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : tambahUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B3541),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Tambah User",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // CUSTOM INPUT FIELD
  Widget _inputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => showPassword = !showPassword),
                )
              : null,
        ),
      ),
    );
  }
}
