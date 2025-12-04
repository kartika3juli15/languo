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

  Future<void> submit() async {
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

        // SAVE USER DOCUMENT MATCHING USERMODEL FORMAT
        await _firestore.collection('users').doc(uid).set({
          'user_id': uid,
          'user_name': enteredName, // Input dari register form
          'user_email': enteredEmail,
          'user_role': 'Dosen', // default role
          'user_photo': null,
          'created_at': Timestamp.now(),
        });
      }

      notifyListeners(); // Update UI
    } catch (e) {
      print("Error Auth: $e");
    }
  }
}
