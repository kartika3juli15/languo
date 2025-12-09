import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/sakit_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class SakitRekapanData {
  final String id;
  final String diagnosa;
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

  SakitRekapanData({
    required this.id,
    required this.diagnosa,
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

class RekapanSakitPage extends StatefulWidget {
  const RekapanSakitPage({super.key});

  @override
  State<RekapanSakitPage> createState() => _RekapanSakitPageState();
}

class _RekapanSakitPageState extends State<RekapanSakitPage> {
  final _sakitService = SakitService();
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
      return {'userName': 'Data Tidak Ditemukan', 'userEmail': 'N/A'};
    }
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    final data = userDoc.data();

    return {
      'userName': data?['user_name'] ?? 'Data Tidak Ditemukan',
      'userEmail': data?['user_email'] ?? 'Email Tidak Ditetapkan',
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
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }

        final userData = userSnapshot.data!;
        final stream = FirebaseFirestore.instance
            .collection('pengajuan_sakit')
            .where('user_id', isEqualTo: currentUser.uid)
            .snapshots();

        return Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text('Error: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("Belum ada pengajuan sakit",
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    );
                  }

                  final sakitList = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;

                    final createdAt =
                        (data['created_at'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                    final tanggalMulai =
                        (data['tanggal_mulai'] as Timestamp).toDate();
                    final tanggalSelesai =
                        (data['tanggal_selesai'] as Timestamp).toDate();

                    return SakitRekapanData(
                      id: d.id,
                      diagnosa: (data['diagnosa'] ?? 'Sakit').toString(),
                      tanggalMulai: tanggalMulai,
                      tanggalSelesai: tanggalSelesai,
                      status: (data['status'] ?? 'Diajukan').toString(),
                      lampiranUrl: data['lampiran_url']?.toString(),
                      storagePath: data['storage_path']?.toString(),
                      keterangan: (data['keterangan'] ?? '-').toString(),
                      tanggalPengajuan: createdAt,
                      userName: userData['userName']!,
                      userEmail: userData['userEmail']!,
                      userRole: userData['userRole']!,
                    );
                  }).toList()
                    ..sort((a, b) =>
                        b.tanggalPengajuan.compareTo(a.tanggalPengajuan));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: sakitList.length,
                    itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTile(sakitList[i])),
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
    return "${hari[date.weekday % 7]}, ${date.day} ${bulan[date.month - 1]} ${date.year}";
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _hapusPengajuan(String sakitId) async {
    try {
      await _sakitService.hapusPengajuanSakit(sakitId);
      _showMsg("Pengajuan sakit berhasil dihapus.");
    } catch (e) {
      _showMsg("Gagal menghapus pengajuan: $e");
    }
  }

  void _confirmDelete(String sakitId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus pengajuan sakit ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _hapusPengajuan(sakitId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMsg('Gagal membuka lampiran.');
    }
  }

  Widget _buildTile(SakitRekapanData sakit) {
    final periode =
        "${sakit.tanggalMulai.day}/${sakit.tanggalMulai.month}/${sakit.tanggalMulai.year} "
        "s.d. ${sakit.tanggalSelesai.day}/${sakit.tanggalSelesai.month}/${sakit.tanggalSelesai.year}";
    final canDelete = sakit.status.toLowerCase() == 'diajukan';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(sakit.diagnosa,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(children: [
          const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text("Periode: $periode",
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (sakit.lampiranUrl != null && sakit.lampiranUrl!.isNotEmpty)
            const Icon(Icons.attachment, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _statusColor(sakit.status),
                borderRadius: BorderRadius.circular(20)),
            child: Text(sakit.status,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ]),
        children: [
          const Divider(indent: 16, endIndent: 16, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildDetail("Nama", sakit.userName),
              _buildDetail("Email", sakit.userEmail),
              _buildDetail("Jabatan", sakit.userRole),
              const SizedBox(height: 12),
              _buildDetail(
                  "Tanggal Pengajuan", _formatTanggal(sakit.tanggalPengajuan)),
              _buildDetail("Status", sakit.status,
                  isStatus: true, color: _statusColor(sakit.status)),
              _buildDetail("Keterangan",
                  sakit.keterangan.isEmpty ? "-" : sakit.keterangan),
              if (sakit.lampiranUrl != null && sakit.lampiranUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(sakit.lampiranUrl!),
                    icon: const Icon(Icons.file_download, color: Colors.white),
                    label: const Text("Lihat Lampiran",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1666A9),
                        minimumSize: const Size(double.infinity, 40)),
                  ),
                ),
              if (canDelete)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(sakit.id),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text("Hapus Pengajuan",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 40)),
                  ),
                ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value,
      {bool isStatus = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: color))
                : Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87))),
      ]),
    );
  }
}
