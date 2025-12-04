import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../admin/home_page.dart';
import '../users/karyawan/home_page.dart';
import '../users/dosen/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User SUDAH login → Home
        if (snapshot.hasData) {
          final user = snapshot.data!;

          return FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!roleSnap.hasData || !roleSnap.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text("Role user tidak ditemukan")),
                );
              }

              final role = roleSnap.data!.get('user_role');

              if (role == "Admin") {
                return const HomeAdmin();
              } else if (role == "Karyawan") {
                return const HomeKaryawan();
              } else if (role == "Dosen") {
                return const HomeDosen();
              } else  {
                return const Scaffold(
                  body: Center(child: Text("Role tidak dikenali")),
                );
              }
            },
          );
        }

        // User BELUM login → LoginScreen atau RegisterScreen
        debugPrint(
            "User not logged in - showing ${showLogin ? 'Login' : 'Register'}");

        if (showLogin) {
          return LoginScreen(
            onRegisterTap: () {
              setState(() => showLogin = false);
            },
          );
        } else {
          return RegisterScreen(
            onSignInTap: () {
              setState(() => showLogin = true);
            },
          );
        }
      },
    );
  }
}
