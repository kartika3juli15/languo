import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/home_page.dart';
import '../users/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;

  // Colors
  static const Color accentColor = Color(0xFFE75636);
  static const Color primaryColor = Color(0xFF2B3541);
  static const Color backgroundColor = Color(0xFFF3F7F7);

  static const int alpha70 = 179;
  static const int alpha50 = 128;

  // ===============================================================
  //                          LOGIN USER
  // ===============================================================
  Future<void> loginUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // ========================================================
    // VALIDASI INPUTAN
    // ========================================================

    // Tidak isi email + password
    if (email.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belum mengisi email dan password")),
      );
      return;
    }

    // Hanya isi email, password kosong
    if (email.isNotEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password belum diisi")),
      );
      return;
    }

    // Hanya isi password, email kosong
    if (email.isEmpty && password.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email belum diisi")),
      );
      return;
    }

    // Format email tidak valid
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$");
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak sesuai format")),
      );
      return;
    }

    // ========================================================
    // PROSES LOGIN FIREBASE
    // ========================================================
    try {
      UserCredential userCred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Login berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login berhasil")),
      );

      final user = userCred.user;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final role = doc.data()?['user_role'] ?? 'Karyawan';

        Widget nextPage =
            role == "Admin" ? const HomeAdmin() : const HomePageUser();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Error dari Firebase
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password anda salah")),
        );
      } else if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data tidak terdaftar")),
        );
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email anda salah")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email dan Password tidak sesuai.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ===============================================================
  //                       LOGIN GOOGLE
  // ===============================================================
  Future<void> loginGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCred.user;
      if (user == null) return;

      final docRef =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          "user_id": user.uid,
          "user_name": user.displayName ?? "User Baru",
          "user_email": user.email ?? "",
          "user_role": "Karyawan",
          "sisa_cuti": 100,
          "user_photo": user.photoURL ?? "",
          "created_at": FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Google Berhasil")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Error: $e")),
      );
    }
  }

  // ===============================================================
  //                      LOGIN FACEBOOK
  // ===============================================================
  Future<void> loginFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final credential =
            FacebookAuthProvider.credential(result.accessToken!.token);

        await FirebaseAuth.instance.signInWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Facebook Berhasil")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facebook login gagal")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Error: $e")),
      );
    }
  }

  // ===============================================================
  //                          UI LOGIN PAGE
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER =====================================================
              Container(
                height: 80,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF36546C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      "Selamat Datang",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color.fromARGB(255, 92, 92, 92),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: -2,
                            right: 16,
                            child: Image.asset(
                              "assets/bgbelakang.png",
                              width: 115,
                            ),
                          ),
                          Positioned(
                            child: Image.asset(
                              "assets/bgdepan.png",
                              width: 110,
                            ),
                          ),
                          Positioned(
                            child: Image.asset(
                              "assets/logosipres.png",
                              width: 90,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "S",
                          style: TextStyle(
                            fontSize: 30,
                            color: primaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          "ipres",
                          style: TextStyle(
                            fontSize: 22,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Image.asset(
                          "assets/jti.png",
                          height: 30,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Silakan Logn untuk melanjutkan!",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryColor.withAlpha(alpha70),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= INPUT EMAIL =================
                    _inputField(
                      icon: Icons.email_outlined,
                      hint: "Email",
                      controller: emailController,
                    ),

                    // ================= INPUT PASSWORD ===============
                    _inputField(
                      icon: Icons.lock_outline,
                      hint: "Password",
                      controller: passwordController,
                      obscure: !showPassword,
                      isPassword: true,
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Or Sign In With",
                            style: TextStyle(
                              color: primaryColor.withAlpha(alpha70),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          icon: "assets/google.png",
                          label: "Google",
                          onTap: loginGoogle,
                        ),
                        const SizedBox(width: 20),
                        _socialButton(
                          icon: "assets/facebook.png",
                          label: "Facebook",
                          onTap: loginFacebook,
                        ),
                      ],
                    ),

                    const SizedBox(height: 160),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // WIDGET INPUT FIELD
  // ===============================================================
  Widget _inputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: primaryColor,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          hintText: hint,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withAlpha(alpha50)),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: primaryColor,
                  ),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ===============================================================
  // SOCIAL BUTTONS
  // ===============================================================
  Widget _socialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 24, height: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
