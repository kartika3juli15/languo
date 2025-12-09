

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> performCheckIn() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) {
    throw Exception('User tidak login');
  }

  // Ambil data user dari collection dosen atau karyawan
  DocumentSnapshot? userDoc;
  String role = '';
  
  // Cek di collection dosen
  userDoc = await firestore.collection('dosen').doc(currentUserId).get();
  if (userDoc.exists) {
    role = 'dosen';
  } else {
    // Cek di collection karyawan
    userDoc = await firestore.collection('karyawan').doc(currentUserId).get();
    if (userDoc.exists) {
      role = 'karyawan';
    }
  }
  
  if (!userDoc.exists || role.isEmpty) {
    throw Exception('Data user tidak ditemukan');
  }
  
  final userData = userDoc.data() as Map<String, dynamic>;
  final nama = userData['nama'] ?? userData['name'] ?? 'Tanpa Nama';
  final email = userData['email'] ?? 'Tanpa Email';
  
  // Buat waktu check-in
  final now = DateTime.now();
  final timeNow = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  
  // Simpan ke collection absensi dengan field lengkap
  await firestore.collection('absensi').add({
    'user_id': currentUserId,
    'role': role,                    // ← PENTING: Field untuk filter admin
    'nama': nama,                     // ← PENTING: Untuk ditampilkan di admin
    'email': email,                   // ← PENTING: Untuk ditampilkan di admin
    'check_in': timeNow,
    'check_out': '',
    'date': Timestamp.now(),
    'status': 'Proses',
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  });
  
  print('Check-in berhasil untuk $nama ($role)');
}

