import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  bool islogin = true;

  final form = GlobalKey<FormState>();
  String enteredEmail = "";
  String enteredPassword = "";
  String enteredName = "";

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> submit(BuildContext context) async {
    if (!form.currentState!.validate()) return;

    form.currentState!.save();

    try {
      if (islogin) {
        // ===== LOGIN =====
        await _auth.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
      } else {
        // ===== REGISTER =====
        UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );

        final uid = userCred.user!.uid;

        await _firestore.collection('users').doc(uid).set({
          'user_id': uid,
          'user_name': enteredName,
          'user_email': enteredEmail,
          'user_role': 'Dosen',
          'user_photo': null,
          'created_at': Timestamp.now(),
        });
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      final msg = e.message?.toLowerCase() ?? "";

      // ======================
      // ERROR HANDLING LOGIN
      // ======================
      if (e.code == "wrong-password" ||
          msg.contains("wrong password") ||
          msg.contains("auth credential is incorrect")) {
        _showMsg(context, "Password anda salah");
      } else if (e.code == "user-not-found" || msg.contains("no user record")) {
        _showMsg(context, "Data tidak terdaftar");
      } else if (e.code == "invalid-email" || msg.contains("badly formatted")) {
        _showMsg(context, "Email tidak sesuai format");
      } else if (msg.contains("malformed") || msg.contains("expired")) {
        _showMsg(context, "Email atau Password salah");
      }

      // ======================
      // ERROR REGISTER
      // ======================
      else if (e.code == "email-already-in-use") {
        _showMsg(context, "Email sudah digunakan");
      }

      // ======================
      // ERROR DEFAULT
      // ======================
      else {
        _showMsg(context, "Error: ${e.message}");
      }
    } catch (e) {
      print("Error Auth: $e");
      _showMsg(context, "Terjadi kesalahan.");
    }
  }

  // SnackBar
  void _showMsg(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
