import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screen/login_screen.dart';
import '../admin/home_page.dart';
import '../users/home_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C48)),
            ),
          );
        }

        if (authSnap.hasError) {
          return Scaffold(
            body: Center(child: Text("Auth Error: ${authSnap.error}")),
          );
        }

        final user = authSnap.data;

        if (user == null) {
          // User belum login → tampil LoginScreen
          return const LoginScreen();
        }

        // User sudah login → ambil role realtime dari Firestore
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF47C48)),
                ),
              );
            }

            if (roleSnap.hasError) {
              return Scaffold(
                body: Center(child: Text("Firestore Error: ${roleSnap.error}")),
              );
            }

            final role = roleSnap.data?.data()?['user_role'] ?? '';

            if (role.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Role user tidak ditemukan")),
              );
            }

            // Redirect berdasarkan role
            return role == "Admin" ? const HomeAdmin() : const HomePageUser();
          },
        );
      },
    );
  }
}
