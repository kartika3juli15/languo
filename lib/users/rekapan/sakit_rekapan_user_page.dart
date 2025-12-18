import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/sakit_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// ===============================
/// HELPER FILTER BULAN & TAHUN
/// ===============================
class MonthYearFilterHelper {
  static bool match({
    required DateTime tanggal,
    int? selectedMonth,
    int? selectedYear,
  }) {
    if (selectedMonth != null && tanggal.month != selectedMonth) {
      return false;
    }
    if (selectedYear != null && tanggal.year != selectedYear) {
      return false;
    }
    return true;
  }
}

/// ===============================
/// MODEL DATA REKAPAN SAKIT
/// ===============================
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

/// ===============================
/// PAGE REKAPAN SAKIT
/// ===============================
class RekapanSakitPage extends StatefulWidget {
  const RekapanSakitPage({super.key});

  @override
  State<RekapanSakitPage> createState() => _RekapanSakitPageState();
}

class _RekapanSakitPageState extends State<RekapanSakitPage> {
  final _sakitService = SakitService();
  final _auth = FirebaseAuth.instance;

  late Future<Map<String, String>> _userDataFuture;

  int? _selectedMonth;
  int? _selectedYear;

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
        'userRole': 'N/A',
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
        child: Text("Anda harus login untuk melihat rekapan."),
      );
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
            .collection('pengajuan_sakit')
            .where('user_id', isEqualTo: currentUser.uid)
            .snapshots();

        return Column(
          children: [
            /// ===== FILTER UI =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedMonth,
                      hint: const Text("Semua Bulan"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Semua Bulan"),
                        ),
                        ...List.generate(12, (index) {
                          final months = [
                            'Januari',
                            'Februari',
                            'Maret',
                            'April',
                            'Mei',
                            'Juni',
                            'Juli',
                            'Agustus',
                            'September',
                            'Oktober',
                            'November',
                            'Desember'
                          ];
                          return DropdownMenuItem<int?>(
                            value: index + 1,
                            child: Text(months[index]),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMonth = value),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Filter Bulan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedYear,
                      hint: const Text("Semua Tahun"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("Semua Tahun"),
                        ),
                        ...List.generate(5, (i) {
                          final year = DateTime.now().year - i;
                          return DropdownMenuItem<int?>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedYear = value),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Tahun',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ===== DATA =====
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
                      child: Text(
                        "Belum ada pengajuan sakit",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final sakitList = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;

                    final Timestamp? createdAtTs =
                        data['created_at'] as Timestamp?;

                    final createdAt = createdAtTs?.toDate() ?? DateTime.now();

                    return SakitRekapanData(
                      id: d.id,
                      diagnosa: (data['diagnosa'] ?? 'Sakit').toString(),
                      tanggalMulai:
                          (data['tanggal_mulai'] as Timestamp).toDate(),
                      tanggalSelesai:
                          (data['tanggal_selesai'] as Timestamp).toDate(),
                      status: (data['status'] ?? 'Diajukan').toString(),
                      lampiranUrl: data['lampiran_url']?.toString(),
                      storagePath: data['storage_path']?.toString(),
                      keterangan: (data['keterangan'] ?? '-').toString(),
                      tanggalPengajuan: createdAt,
                      userName: userData['userName']!,
                      userEmail: userData['userEmail']!,
                      userRole: userData['userRole']!,
                    );
                  }).toList();

                  final filteredList = sakitList.where((e) {
                    return MonthYearFilterHelper.match(
                      tanggal: e.tanggalPengajuan,
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                    );
                  }).toList()
                    ..sort((a, b) =>
                        b.tanggalPengajuan.compareTo(a.tanggalPengajuan));

                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text(
                        "Data tidak ditemukan",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSakitRekapanTile(
                            filteredList[index], context),
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

  // =========================
  // BAGIAN BAWAH TIDAK DIUBAH
  // =========================
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'diajukan':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTanggal(DateTime date) {
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
    return "${date.day} ${bulan[date.month - 1]} ${date.year}";
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
    try {
      // === Jika Web ===
      if (kIsWeb) {
        html.window.open(url, '_blank');
        return;
      }

      // === Jika Android/iOS ===
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Simpan sementara di device
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/lampiran.pdf";

        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Buka file menggunakan aplikasi di HP
        await OpenFile.open(filePath);
      } else {
        _showMsg("Gagal mengunduh lampiran (status: ${response.statusCode}).");
      }
    } catch (e) {
      _showMsg("Terjadi kesalahan saat membuka PDF.");
    }
  }

  Widget _buildSakitRekapanTile(SakitRekapanData sakit, BuildContext context) {
    final String periode =
        "${sakit.tanggalMulai.day}/${sakit.tanggalMulai.month}/${sakit.tanggalMulai.year} "
        "s.d. ${sakit.tanggalSelesai.day}/${sakit.tanggalSelesai.month}/${sakit.tanggalSelesai.year}";

    final bool canDelete = sakit.status.toLowerCase() == 'diajukan';

    Widget statusBadge(String status, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: InkWell(
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            // === TITLE ===
            title: Text(
              sakit.diagnosa,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2B3541),
              ),
            ),

            // === SUBTITLE: PERIODE ===
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Periode: $periode",
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // === TRAILING BADGE + ATTACHMENT ICON ===
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sakit.lampiranUrl != null && sakit.lampiranUrl!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.attachment,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                  ),
                statusBadge(sakit.status, _statusColor(sakit.status)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),

            // === EXPANDED CONTENT ===
            children: [
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Nama", sakit.userName),
                    _buildDetailRow("Email", sakit.userEmail),
                    _buildDetailRow("Jabatan", sakit.userRole),
                    const SizedBox(height: 12),
                    _buildDetailRow("Tanggal Pengajuan",
                        _formatTanggal(sakit.tanggalPengajuan)),
                    _buildDetailRow("Status", sakit.status,
                        isStatus: true,
                        statusColor: _statusColor(sakit.status)),
                    _buildDetailRow("Keterangan",
                        sakit.keterangan.isEmpty ? "-" : sakit.keterangan),

                    // === BUTTON LIHAT LAMPIRAN ===
                    if (sakit.lampiranUrl != null &&
                        sakit.lampiranUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdf(sakit.lampiranUrl!),
                          icon: const Icon(Icons.picture_as_pdf,
                              size: 20, color: Colors.white),
                          label: const Text(
                            "Lihat Lampiran",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1666A9),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                    // === BUTTON HAPUS ===
                    if (canDelete)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(sakit.id),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red, size: 20),
                          label: const Text(
                            "Hapus Pengajuan",
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isStatus = false, Color statusColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isStatus
                ? Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
          ),
        ],
      ),
    );
  }
}
