import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sakit_service.dart';

class PengajuanSakitPage extends StatefulWidget {
  const PengajuanSakitPage({super.key});

  @override
  State<PengajuanSakitPage> createState() => _PengajuanSakitPageState();
}

class _PengajuanSakitPageState extends State<PengajuanSakitPage> {
  final _sakitService = SakitService();
  final _auth = FirebaseAuth.instance;

  int selectedTab = 0;
  DateTime? startDate;
  DateTime? endDate;
  XFile? lampiranXFile;
  final picker = ImagePicker();
  final TextEditingController keteranganController = TextEditingController();

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? (startDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> pickLampiran() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => lampiranXFile = img);
    }
  }

  // ================================
  // SUBMIT FORM
  // ================================
  Future<void> submitForm() async {
    if (startDate == null || endDate == null) {
      return _showMessage("Tanggal belum dipilih");
    }
    // Cek XFile yang baru
    if (lampiranXFile == null) {
      return _showMessage("Lampiran belum diupload");
    }
    if (keteranganController.text.isEmpty) {
      return _showMessage("Keterangan masih kosong");
    }

    try {
      String userId = _auth.currentUser?.uid ?? "unknown";

      final Uint8List lampiranBytes = await lampiranXFile!.readAsBytes();
      final String fileName = lampiranXFile!.name; // Ambil nama file

      await _sakitService.kirimPengajuan(
        userId: userId,
        startDate: startDate!,
        endDate: endDate!,
        keterangan: keteranganController.text,
        lampiranBytes: lampiranBytes,
        fileName: fileName,
      );

      _showMessage("Pengajuan Sakit Berhasil Dikirim!");

      setState(() {
        startDate = null;
        endDate = null;
        lampiranXFile = null;
        keteranganController.clear();
      });
    } catch (e) {
      // REVISI: Tampilkan error yang lebih spesifik di snackbar
      print("Error submitForm: $e");
      String errorMessage = e.toString().contains("firebase_storage")
          ? "Gagal upload lampiran."
          : e.toString().contains("PERMISSION_DENIED")
              ? "Gagal mengirim: Izin ditolak (Security Rules)."
              : "Gagal mengirim pengajuan: $e";

      _showMessage(errorMessage);
    }
  }
  // ---------------------------------------------------------------------------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _monthName(int m) {
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
    return bulan[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFF36546C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child:
                          Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Sakit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TAB
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(40),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 2;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        left: selectedTab == 0 ? 0 : tabWidth,
                        child: Container(
                          height: 55,
                          width: tabWidth,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.deepOrange, Colors.redAccent],
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTab = 0),
                              child: Center(
                                child: Text(
                                  "Pengajuan",
                                  style: TextStyle(
                                    color: selectedTab == 0
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTab = 1),
                              child: Center(
                                child: Text(
                                  "Rekapan",
                                  style: TextStyle(
                                    color: selectedTab == 1
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: selectedTab == 0
                ? _buildForm()
                : Center(
                    child: Text("Buka halaman Rekapan untuk melihat data")),
          )
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text("Tanggal",
              style: TextStyle(
                  color: Color(0xFF7F7F7F), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: pickStartDate,
                  child: _dateBox(startDate == null
                      ? "Pilih Tanggal"
                      : "${startDate!.day} ${_monthName(startDate!.month)} ${startDate!.year}"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: pickEndDate,
                  child: _dateBox(endDate == null
                      ? "Pilih Tanggal"
                      : "${endDate!.day} ${_monthName(endDate!.month)} ${endDate!.year}"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: pickLampiran,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // --- BAGIAN 4: Cek status variabel baru (lampiranXFile) ---
                child: Text(
                  lampiranXFile == null
                      ? "Upload Lampiran"
                      : "Lampiran Terpilih",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Keterangan",
              style: TextStyle(
                  color: Color(0xFF7F7F7F), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: keteranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Tulis keterangan...",
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: submitForm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3541),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  "Kirim",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _dateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          const Icon(Icons.calendar_today, size: 18),
        ],
      ),
    );
  }
}
