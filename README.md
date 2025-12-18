# 📱 SIPRES-JTI  
Sistem Presensi Jurusan Teknologi Informasi

## 👥 KELOMPOK 1 – SIB3C
- Gerly Vaeyungfan — NIM. 2341760195  
- Ismi Atika — NIM. 2341760036  
- Kartika Tri Juliana — NIM. 2341760116  
- Khoir Karol Nurzuraidah — NIM. 2341760048  

---

## A. Deskripsi SIPRES-JTI
SIPRES-JTI merupakan sistem presensi digital berbasis mobile yang dikembangkan khusus untuk Jurusan Teknologi Informasi. Aplikasi ini dirancang untuk mempermudah dan meningkatkan efektivitas proses absensi.

SIPRES-JTI memiliki beberapa keunggulan utama, antara lain:
- Presensi dilakukan menggunakan **QR Code** sehingga lebih praktis dan mengurangi ketergantungan pada fingerprint
- Dilengkapi dengan **validasi lokasi (GPS)** untuk memastikan presensi dilakukan di area yang telah ditentukan
- Menggunakan **database real-time** sehingga data kehadiran langsung tersimpan dan dapat diakses dengan cepat
- Menerapkan **role-based access** untuk membedakan hak akses antara karyawan/dosen dan admin

---

## B. Fitur Aplikasi

### Fitur User (Karyawan/Dosen)
- Autentikasi Akun  
- Homepage  
- Presensi menggunakan QR Code  
- Rekapan Kehadiran  
- Profil & Pengaturan  
- Pengajuan Izin, Sakit, & Cuti  
- Maps (validasi lokasi presensi)

### Fitur Admin
- Dashboard Admin  
- Monitoring Presensi  
- Verifikasi Pengajuan  
- Manajemen Pengguna  
- Rekapan & Laporan  

---

## C. Instalasi Aplikasi

1. Clone repository:
   git clone <https://github.com/kartika3juli15/SipresJTI.git> 

2. Jalankan perintah berikut pada terminal: flutter pub get

3. Untuk menjalankan aplikasi, terdapat dua cara:
   a. Development Mode : Mode ini mendukung hot reload. Tekan r atau hot reload untuk melihat perubahan tampilan secara langsung atau update.
   perintah : flutter run
   b. Build APK : Perintah ini akan menghasilkan file .apk yang dapat dibagikan kepada pengguna lain, namun tidak mendukung pembaruan perubahan kode
   perintah : flutter run atau flutter build apk --release

4. Install aplikasi pada perangkat Android dan jalankan sebagai Admin atau User sesuai hak akses.
