import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/cuti_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CutiRekapanData {
  final String id;
  final String alasan;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String status;
  final String? lampiranUrl;
  final String? lampiranName;
  final String keterangan;
  final DateTime tanggalPengajuan;
  final String userName;
  final String userEmail;
  final String userRole;

  CutiRekapanData({
    required this.id,
    required this.alasan,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    this.lampiranUrl,
    this.lampiranName,
    required this.keterangan,
    required this.tanggalPengajuan,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });
}

class RekapanCutiPage extends StatefulWidget {
  const RekapanCutiPage({super.key});

  @override
  State<RekapanCutiPage> createState() => _RekapanCutiPageState();
}

class _RekapanCutiPageState extends State<RekapanCutiPage> {
  final _cutiService = CutiService();
  final _auth = FirebaseAuth.instance;

  int? _selectedMonth;
  int? _selectedYear;

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  bool _matchMonthYear(DateTime date) {
    if (_selectedMonth != null && date.month != _selectedMonth) return false;
    if (_selectedYear != null && date.year != _selectedYear) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(
          child: Text("Anda harus login untuk melihat rekapan."));
    }

    return Column(
      children: [
        /// FILTER BULAN & TAHUN
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedMonth,
                  hint: const Text("Semua Bulan"),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Semua Bulan"),
                    ),
                    ...List.generate(12, (i) {
                      return DropdownMenuItem<int?>(
                        value: i + 1,
                        child: Text(_getMonthName(i + 1)),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedMonth = v),
                  decoration: const InputDecoration(
                    labelText: "Filter Bulan",
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
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
                  onChanged: (v) => setState(() => _selectedYear = v),
                  decoration: const InputDecoration(
                    labelText: "Tahun",
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// DATA
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _cutiService.getRekapanCuti(currentUser.uid),
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
                    "Belum ada pengajuan cuti",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return FutureBuilder<Map<String, String>>(
                future: _fetchUserData(currentUser.uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData = userSnapshot.data ??
                      {
                        'userName': 'Data Tidak Ditemukan',
                        'userEmail': 'N/A',
                        'userRole': 'N/A',
                      };

                  final cutiList = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;

                    final tanggalMulai =
                        (data['tanggal_mulai'] as Timestamp).toDate();
                    final tanggalSelesai =
                        (data['tanggal_selesai'] as Timestamp).toDate();
                    final tanggalPengajuan =
                        (data['created_at'] as Timestamp?)?.toDate() ??
                            DateTime.now();

                    return CutiRekapanData(
                      id: d.id,
                      alasan: data['alasan'] ?? 'Cuti',
                      tanggalMulai: tanggalMulai,
                      tanggalSelesai: tanggalSelesai,
                      status: data['status'] ?? "Diajukan",
                      lampiranUrl: data['lampiran_url'],
                      lampiranName: data['file_name'] ?? 'Lampiran',
                      keterangan: data['keterangan'] ?? '-',
                      tanggalPengajuan: tanggalPengajuan,
                      userName: userData['userName']!,
                      userEmail: userData['userEmail']!,
                      userRole: userData['userRole']!,
                    );
                  }).where((c) {
                    return _matchMonthYear(c.tanggalPengajuan);
                  }).toList();

                  if (cutiList.isEmpty) {
                    return const Center(child: Text("Data tidak ditemukan"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cutiList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCutiRekapanTile(cutiList[index], context),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // BAGIAN BAWAH TIDAK DIUBAH
  // =========================

  Future<Map<String, String>> _fetchUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    final data = userDoc.data();
    return {
      'userName': data?['user_name'] ?? 'Data Tidak Ditemukan',
      'userEmail': data?['user_email'] ?? _auth.currentUser?.email ?? 'N/A',
      'userRole': data?['user_role'] ?? 'N/A',
    };
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _hapusPengajuan(String cutiId) async {
    try {
      await _cutiService.hapusPengajuanCuti(cutiId);
      _showMessage("Pengajuan cuti berhasil dihapus.");
    } catch (e) {
      _showMessage("Gagal menghapus pengajuan: $e");
    }
  }

  void _showConfirmDeleteDialog(String cutiId) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Konfirmasi Hapus"),
        content: const Text(
            "Anda yakin ingin menghapus pengajuan cuti ini? Aksi ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _hapusPengajuan(cutiId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
        _showMessage(
            "Gagal mengunduh lampiran (status: ${response.statusCode}).");
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan saat membuka PDF.");
    }
  }

  Widget _buildCutiRekapanTile(CutiRekapanData cuti, BuildContext context) {
    String periodeCuti =
        "${cuti.tanggalMulai.day}/${cuti.tanggalMulai.month}/${cuti.tanggalMulai.year} s.d. ${cuti.tanggalSelesai.day}/${cuti.tanggalSelesai.month}/${cuti.tanggalSelesai.year}";

    final bool canDelete = cuti.status.toLowerCase() == 'diajukan';

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
            title: Text(
              cuti.alasan,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2B3541),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Periode: $periodeCuti",
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cuti.lampiranUrl != null && cuti.lampiranUrl!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.attachment,
                        color: Colors.deepOrange, size: 20),
                  ),
                statusBadge(cuti.status, _statusColor(cuti.status)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
            children: [
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Nama", cuti.userName),
                    _buildDetailRow("Email", cuti.userEmail),
                    _buildDetailRow("Jabatan", cuti.userRole),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        "Tgl Pengajuan", _formatTanggal(cuti.tanggalPengajuan)),
                    _buildDetailRow("Status", cuti.status,
                        isStatus: true, statusColor: _statusColor(cuti.status)),
                    _buildDetailRow("Keterangan",
                        cuti.keterangan.isEmpty ? "-" : cuti.keterangan),
                    if (cuti.lampiranUrl != null &&
                        cuti.lampiranUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _openPdf(cuti.lampiranUrl!),
                          icon: const Icon(Icons.file_download,
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
                    if (canDelete)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: OutlinedButton.icon(
                          onPressed: () => _showConfirmDeleteDialog(cuti.id),
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
