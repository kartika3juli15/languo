import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/cuti_service.dart';
import '../rekapan/cuti_rekapan_user_page.dart';

class PengajuanCutiPage extends StatefulWidget {
  const PengajuanCutiPage({super.key});

  @override
  State<PengajuanCutiPage> createState() => _PengajuanCutiPageState();
}

class _PengajuanCutiPageState extends State<PengajuanCutiPage> {
  final _cutiService = CutiService();
  final _auth = FirebaseAuth.instance;

  int selectedTab = 0;
  DateTime? startDate;
  DateTime? endDate;

  Uint8List? lampiranBytes;
  String? lampiranName;

  final TextEditingController alasanController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  bool isSubmitted = false;
  bool isLoading = false;

  num? sisaCutiSaatPengajuan;
  bool isFetchingCuti = true;

  @override
  void initState() {
    super.initState();
    fetchSisaCuti();
  }

  Future<void> fetchSisaCuti() async {
    String userId = _auth.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();

    setState(() {
      sisaCutiSaatPengajuan = (doc.data()?["sisa_cuti"] ?? 0) as num;
      isFetchingCuti = false;
    });
  }

  // ======================== TANGGAL ========================
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

  // ======================== LAMPIRAN ========================
  Future<void> pickLampiran() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        lampiranBytes = result.files.first.bytes;
        lampiranName = result.files.first.name;
      });
    }
  }

  void removeLampiran() {
    setState(() {
      lampiranBytes = null;
      lampiranName = null;
    });
  }

  // ======================== VALIDASI SEBELUM KONFIRM ========================
  bool _validateFormBeforeConfirm() {
    if (alasanController.text.isEmpty) {
      _showMessage("Alasan cuti belum diisi");
      return false;
    }
    if (startDate == null || endDate == null) {
      _showMessage("Tanggal belum dipilih");
      return false;
    }
    if (endDate!.isBefore(startDate!)) {
      _showMessage("Tanggal akhir harus setelah tanggal mulai");
      return false;
    }

    // Hitung jumlah hari cuti (termasuk hari awal dan akhir)
    int totalHariCuti = endDate!.difference(startDate!).inDays + 1;

    if (sisaCutiSaatPengajuan == null) {
      _showMessage("Gagal memuat data sisa cuti");
      return false;
    }

    if (totalHariCuti > sisaCutiSaatPengajuan!) {
      _showMessage(
          "Pengajuan melebihi sisa cuti.\nSisa cuti Anda: $sisaCutiSaatPengajuan hari");
      return false;
    }

    return true;
  }

  void _onKirimPressed() {
    if (isSubmitted || isLoading) return;
    if (_validateFormBeforeConfirm()) {
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                "Apakah anda yakin untuk mengirim?",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _submitFromButton();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1666A9)),
                      child: const Text("Ya",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF05454)),
                      child: const Text("Tidak",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ]),
          ),
        );
      },
    );
  }

  void _submitFromButton() async {
    setState(() => isLoading = true);
    final success = await submitForm();
    setState(() => isLoading = false);

    if (success) showSuccessDialog();
  }

  // ======================== POPUP SUKSES ========================
  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => isSubmitted = false);
                },
                child: const Icon(Icons.close, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.green),
            ),
            const SizedBox(height: 15),
            const Text(
              "Pengajuan Berhasil Dikirim",
              style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => isSubmitted = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text("OK",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  // ======================== KIRIM DATA ========================
  Future<bool> submitForm() async {
    try {
      String userId = _auth.currentUser?.uid ?? "unknown";

      await _cutiService.kirimPengajuan(
        userId: userId,
        alasan: alasanController.text,
        startDate: startDate!,
        endDate: endDate!,
        keterangan: keteranganController.text,
        lampiranBytes: lampiranBytes,
        fileName: lampiranName,
        sisaCutiSaatPengajuan: sisaCutiSaatPengajuan,
      );

      // reset form
      setState(() {
        isSubmitted = true;
        alasanController.clear();
        keteranganController.clear();
        startDate = null;
        endDate = null;
        lampiranBytes = null;
        lampiranName = null;
      });

      return true;
    } catch (e) {
      _showMessage("Gagal mengirim pengajuan: $e");
      return false;
    }
  }

  // ======================== UI PAGE ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildTabBar(),
          if (selectedTab == 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 8, left: 20, right: 20), // jarak atas 8 saja
                  child: isFetchingCuti
                      ? const CircularProgressIndicator()
                      : Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Sisa cuti Anda: ${sisaCutiSaatPengajuan!.toInt()} hari",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8), // jarak bawah ke form
              ],
            ),
          Expanded(
            child: selectedTab == 0 ? _buildForm() : const RekapanCutiPage(),
          ),
        ],
      ),
    );
  }

  // ===== HEADER =====
  Widget _buildHeader() {
    return Container(
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
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Cuti",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20)
            .copyWith(bottom: 0),
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
                    _tabButton("Pengajuan", 0),
                    _tabButton("Rekapan", 1),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selectedTab == index ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ===== FORM =====
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Alasan Cuti",
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
            controller: alasanController,
            decoration: const InputDecoration(
                hintText: "Tulis alasan cuti...", border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 25),
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
        const Text("Lampiran (Opsional)",
            style: TextStyle(
                color: Color(0xFF7F7F7F), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickLampiran,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text("Upload Lampiran",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (lampiranBytes != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file,
                    size: 22, color: Colors.black54),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lampiranName ?? "Lampiran",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: removeLampiran,
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text("Keterangan (Opsional)",
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
                hintText: "Tulis keterangan...", border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: (isSubmitted) ? null : _onKirimPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:
                  isSubmitted ? Colors.blue.shade300 : const Color(0xFF2B3541),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isSubmitted ? "Sudah Terkirim" : "Kirim",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ]),
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
          children: [Text(text), const Icon(Icons.calendar_today, size: 18)]),
    );
  }

  String _monthName(int m) {
    const b = [
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
    return b[m - 1];
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
