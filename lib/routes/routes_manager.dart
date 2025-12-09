import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screen/login_screen.dart';
import '../admin/home_page.dart';
import '../users/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Cek login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user login, cek role
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

              return role == "Admin" ? const HomeAdmin() : const HomePageUser();
            },
          );
        }

        // User belum login, hanya tampilkan Login
        return const LoginScreen();
      },
    );
  }
}
