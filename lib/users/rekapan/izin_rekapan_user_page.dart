import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/izin_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class IzinRekapanData {
  final String id;
  final String perihal;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String status;
  final String? lampiranUrl;
  final String? storagePath;
  final String keterangan;
  final DateTime tanggalPengajuan;
  final String userName;
  final String userEmail;
  final String userRole;

  IzinRekapanData({
    required this.id,
    required this.perihal,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    this.lampiranUrl,
    this.storagePath,
    required this.keterangan,
    required this.tanggalPengajuan,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });
}

class RekapanIzinPage extends StatefulWidget {
  const RekapanIzinPage({super.key});

  @override
  State<RekapanIzinPage> createState() => _RekapanIzinPageState();
}

class _RekapanIzinPageState extends State<RekapanIzinPage> {
  final _izinService =
      IzinService(); // tetap tersedia (tidak digunakan sebagai stream)
  final _auth = FirebaseAuth.instance;

  late Future<Map<String, String>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, String>> _fetchUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {
        'userName': 'Data Tidak Ditemukan',
        'userEmail': 'N/A',
      };
    }

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    final data = userDoc.data();

    return {
      'userName': data?['user_name'] ?? 'Data Tidak Ditemukan',
      'userEmail': data?['user_email'] ??
          _auth.currentUser!.email ??
          'Email Tidak Ditetapkan',
      'userRole': data?['user_role'] ?? 'Jabatan Tidak Ditetapkan',
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(
          child: Text("Anda harus login untuk melihat rekapan."));
    }
    return FutureBuilder<Map<String, String>>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(
              child: Text('Error loading user data: ${userSnapshot.error}'));
        }

        final userData = userSnapshot.data!;

        final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
            .collection('pengajuan_izin')
            .where('user_id', isEqualTo: currentUser.uid)
            .snapshots();

        return Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Belum ada pengajuan izin",
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey)));
                  }

                  // Map docs to model, being tolerant to different field names
                  final izinList = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;

                    // handle timestamp fields with multiple possible names
                    Timestamp? createdAtTs = (data['createdAt'] is Timestamp)
                        ? data['createdAt'] as Timestamp
                        : (data['created_at'] is Timestamp)
                            ? data['created_at'] as Timestamp
                            : null;

                    final DateTime createdAt =
                        createdAtTs?.toDate() ?? DateTime.now();

                    DateTime tanggalMulai;
                    DateTime tanggalSelesai;
                    try {
                      tanggalMulai =
                          (data['tanggalMulai'] as Timestamp).toDate();
                    } catch (_) {
                      tanggalMulai = DateTime.now();
                    }
                    try {
                      tanggalSelesai =
                          (data['tanggalSelesai'] as Timestamp).toDate();
                    } catch (_) {
                      tanggalSelesai = tanggalMulai;
                    }

                    return IzinRekapanData(
                      id: d.id,
                      perihal: (data['perihal'] ?? 'Izin').toString(),
                      tanggalMulai: tanggalMulai,
                      tanggalSelesai: tanggalSelesai,
                      status: (data['status'] ?? 'Diajukan').toString(),
                      lampiranUrl: (data['lampiran_url'])?.toString(),
                      storagePath: (data['storage_path'])?.toString(),
                      keterangan: (data['keterangan'] ?? '-').toString(),
                      tanggalPengajuan: createdAt,
                      userName: userData['userName'] ?? 'Data Tidak Ditemukan',
                      userEmail:
                          userData['userEmail'] ?? 'Email Tidak Ditetapkan',
                      userRole:
                          userData['userRole'] ?? 'Jabatan Tidak Ditetapkan',
                    );
                  }).toList();

                  // sort client-side by createdAt desc (newest first)
                  izinList.sort((a, b) =>
                      b.tanggalPengajuan.compareTo(a.tanggalPengajuan));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: izinList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildIzinRekapanTile(izinList[index], context),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green.shade600;
      case 'ditolak':
        return Colors.red.shade600;
      case 'diajukan':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatTanggal(DateTime date) {
    const hari = [
      "Minggu",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu"
    ];
    const bulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    String namaHari = hari[date.weekday % 7];
    String namaBulan = bulan[date.month - 1];
    return "$namaHari, ${date.day} $namaBulan ${date.year}";
  }

  void _showMessage(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _hapusPengajuan(String izinId) async {
    try {
      await _izinService.hapusPengajuanIzin(izinId);
      _showMessage("Pengajuan izin berhasil dihapus.");
    } catch (e) {
      _showMessage("Gagal menghapus pengajuan: $e");
    }
  }

  void _showConfirmDeleteDialog(String izinId) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Konfirmasi Hapus"),
        content: const Text(
            "Anda yakin ingin menghapus pengajuan izin ini? Aksi ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _hapusPengajuan(izinId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> openPdf(String url, BuildContext context) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Gagal membuka lampiran: URL tidak valid');
      }
    }
  }

  Widget _buildIzinRekapanTile(IzinRekapanData izin, BuildContext context) {
    String periodeIzin =
        "${izin.tanggalMulai.day}/${izin.tanggalMulai.month}/${izin.tanggalMulai.year} s.d. ${izin.tanggalSelesai.day}/${izin.tanggalSelesai.month}/${izin.tanggalSelesai.year}";
    final bool canDelete = izin.status.toLowerCase() == 'diajukan';

    Widget statusBadge(String status, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(status,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(izin.perihal,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2B3541))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                  child: Text("Periode: $periodeIzin",
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87))),
            ]),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (izin.lampiranUrl != null && izin.lampiranUrl!.isNotEmpty)
              const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.attachment,
                      color: Colors.deepOrange, size: 20)),
            statusBadge(izin.status, _statusColor(izin.status)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ]),
          children: [
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Nama", izin.userName),
                    _buildDetailRow("Email", izin.userEmail),
                    _buildDetailRow("Jabatan", izin.userRole),
                    const SizedBox(height: 12),
                    _buildDetailRow("tanggal Pengajuan",
                        _formatTanggal(izin.tanggalPengajuan)),
                    _buildDetailRow("Status", izin.status,
                        isStatus: true, statusColor: _statusColor(izin.status)),
                    _buildDetailRow("Keterangan",
                        izin.keterangan.isEmpty ? "-" : izin.keterangan),
                    if (izin.lampiranUrl != null &&
                        izin.lampiranUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: ElevatedButton.icon(
                          onPressed: () => openPdf(izin.lampiranUrl!, context),
                          icon: const Icon(Icons.file_download,
                              size: 20, color: Colors.white),
                          label: const Text("Lihat Lampiran",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1666A9),
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                    if (canDelete)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfirmDeleteDialog(izin.id),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red, size: 20),
                          label: const Text("Hapus Pengajuan",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isStatus = false, Color statusColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 130,
            child: Text("$label:",
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.black54))),
        const SizedBox(width: 8),
        Expanded(
          child: isStatus
              ? Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: statusColor))
              : Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ]),
    );
  }
}
