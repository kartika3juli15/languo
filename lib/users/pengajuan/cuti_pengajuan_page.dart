import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/cuti_service.dart';
import '../rekapan/cuti_rekapan_user_page.dart';
import 'package:intl/intl.dart';
import 'package:languo/users/home_page.dart';

class PengajuanCutiPage extends StatefulWidget {
  final int initialTab;

  const PengajuanCutiPage({super.key, this.initialTab = 0});

  @override
  State<PengajuanCutiPage> createState() => _PengajuanCutiPageState();
}

class _PengajuanCutiPageState extends State<PengajuanCutiPage> {
  // ======================== PROPERTI & CONTROLLER ========================
  final _cutiService = CutiService();
  final _auth = FirebaseAuth.instance;

  DateTime? startDate;
  DateTime? endDate;
  num? sisaCutiSaatPengajuan;
  List<DateTime> _holidays = [];

  bool isFetchingCuti = true;
  bool isLoading = false;
  bool isSubmitted = false;

  Uint8List? lampiranBytes;
  String? lampiranName;

  final TextEditingController alasanController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  int selectedTab = 0;

  // ======================== INIT & DISPOSE ========================
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    selectedTab = widget.initialTab;
    fetchSisaCuti();
    loadHolidays();
  }

  @override
  void dispose() {
    alasanController.dispose();
    keteranganController.dispose();
    super.dispose();
  }

  // ======================== FIREBASE FETCHERS ========================

  /// Mengambil daftar Hari Libur Nasional dari Firestore dan menyimpannya di [_holidays].
  Future<void> loadHolidays() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection("holidays").get();

      final List<DateTime> fetchedHolidays = snap.docs.map((d) {
        final ts = d['date'] as Timestamp;
        final dt = ts.toDate();
        // Normalisasi hanya ke tanggal (mengabaikan waktu)
        return DateTime(dt.year, dt.month, dt.day);
      }).toList();

      setState(() {
        _holidays = fetchedHolidays;
      });
    } catch (e) {
      _showMessage("Gagal memuat hari libur: $e");
    }
  }

  Future<void> fetchSisaCuti() async {
    setState(() => isFetchingCuti = true);
    try {
      String userId = _auth.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      setState(() {
        sisaCutiSaatPengajuan = (doc.data()?["sisa_cuti"] ?? 0) as num;
      });
    } catch (e) {
      _showMessage("Gagal memuat sisa cuti: $e");
      setState(() {
        sisaCutiSaatPengajuan = 0;
      });
    } finally {
      setState(() => isFetchingCuti = false);
    }
  }

  // ======================== HELPERS TANGGAL ========================

  /// Mengembalikan nama bulan sesuai indeks
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
    // Karena list 0-indexed dan bulan 1-indexed
    return b[m - 1];
  }

  /// Format tanggal penuh (e.g., 12 Januari 2025) menggunakan helper manual.
  String _formatFullDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year}";
  }

  /// Format tanggal dengan hari (e.g., Senin, 12 Januari 2025). Tetap pakai DateFormat.
  String _formatFullDateWithDay(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  /// Cek apakah tanggal adalah Hari Libur Nasional
  bool isHoliday(DateTime date) {
    // Normalisasi tanggal yang diperiksa (mengabaikan waktu)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _holidays.any((h) => h.isAtSameMomentAs(normalizedDate));
  }

  /// Predikat untuk showDatePicker: memblokir Sabtu, Minggu, dan Hari Libur
  bool _isSelectableDay(DateTime day) {
    // Memblokir Sabtu (6) dan Minggu (7)
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }
    // Memblokir Hari Libur Nasional
    if (isHoliday(day)) {
      return false;
    }
    return true;
  }

  /// Hitung hari kerja (Senin-Jumat) antara start..end, mengabaikan _holidays dan Sabtu/Minggu.
  int _hitungHariKerja(DateTime start, DateTime end, List<DateTime> libur) {
    if (end.isBefore(start)) return 0;
    int count = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(last)) {
      if (_isSelectableDay(current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  // ======================== DATE PICKERS ========================
  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // Menerapkan pembatasan hari
      selectableDayPredicate: _isSelectableDay,
    );
    if (picked != null) {
      // Normalisasi waktu ke awal hari
      setState(
          () => startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> pickEndDate() async {
    final init = endDate ?? (startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: _isSelectableDay,
    );
    if (picked != null) {
      // Normalisasi waktu ke awal hari
      setState(() => endDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  // ======================== LAMPIRAN ========================
  Future<void> pickLampiran() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name.toLowerCase();

    if (!fileName.endsWith('.pdf')) {
      _showMessage("Lampiran yang diunggah wajib berupa file PDF");
      return;
    }

    setState(() {
      lampiranBytes = file.bytes;
      lampiranName = file.name;
    });
  }

  void removeLampiran() {
    setState(() {
      lampiranBytes = null;
      lampiranName = null;
    });
  }

  // ======================== VALIDASI & SUBMIT ========================

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
      _showMessage(
          "Tanggal akhir harus setelah atau sama dengan tanggal mulai");
      return false;
    }

    int totalHariCuti = _hitungHariKerja(startDate!, endDate!, _holidays);

    if (totalHariCuti <= 0) {
      _showMessage(
          "Tidak ada hari kerja dalam rentang tanggal (mungkin hanya weekend/libur).");
      return false;
    }

    if (sisaCutiSaatPengajuan == null || isFetchingCuti) {
      _showMessage("Gagal memuat data sisa cuti. Coba lagi.");
      return false;
    }

    if (totalHariCuti > sisaCutiSaatPengajuan!) {
      _showMessage(
          "Pengajuan melebihi sisa cuti.\nSisa cuti Anda: ${sisaCutiSaatPengajuan!.toInt()} hari");
      return false;
    }

    if (lampiranName != null && !lampiranName!.toLowerCase().endsWith('.pdf')) {
      _showMessage("Lampiran yang diunggah wajib berupa file PDF");
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

      await fetchSisaCuti(); // refetch sisa cuti
      return true;
    } catch (e) {
      _showMessage("Gagal mengirim pengajuan: $e");
      return false;
    }
  }

  Future<void> _submitFromDialog() async {
    setState(() => isLoading = true);
    final success = await submitForm();
    setState(() => isLoading = false);

    if (success) {
      showSuccessDialog();
    }
  }

  // ======================== DIALOGS ========================
  void _showConfirmDialog() {
    final int hariCuti = _hitungHariKerja(startDate!, endDate!, _holidays);
    final int sisaNow = sisaCutiSaatPengajuan!.toInt();
    final int sisaAfter = sisaNow - hariCuti;

    Color sisaColor = sisaAfter <= 0
        ? Colors.red
        : (sisaAfter <= 2 ? Colors.orange : Colors.green);

    showGeneralDialog(
      barrierDismissible: true, // Ubah agar bisa ditutup
      barrierLabel: "Konfirmasi Cuti",
      context: context,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOutBack.transform(animation.value);
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: 0.92 + 0.08 * curved,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                      "Apakah anda yakin untuk mengirim?",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Detail Tanggal
                    if (startDate != null && endDate != null) ...[
                      _buildDetailRow(
                          "Tanggal mulai:", _formatFullDateWithDay(startDate!)),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          "Tanggal selesai:", _formatFullDateWithDay(endDate!)),
                      const SizedBox(height: 12),
                    ],

                    // Ringkasan Cuti
                    _buildSummaryRow("Cuti diajukan:", "$hariCuti hari",
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow("Sisa cuti sekarang:", "$sisaNow hari",
                        isBold: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        "Sisa setelah pengajuan:", "$sisaAfter hari",
                        isBold: true, valueColor: sisaColor),

                    const SizedBox(height: 16),

                    // Tombol Ya/Tidak
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _submitFromDialog();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1666A9)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text("Ya",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF05454)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text("Tidak",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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

  // ======================== BUILDERS DIALOG ========================

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black),
        ),
      ],
    );
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
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePageUser()),
                  (route) => false,
                );
              },
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

  // ===== TAB BAR =====
  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 0),
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(40)),
        child: LayoutBuilder(builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              left: selectedTab == 0 ? 0 : tabWidth,
              child: Container(
                height: 55,
                width: tabWidth,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.deepOrange, Colors.redAccent]),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            Row(children: [
              _tabButton("Pengajuan", 0),
              _tabButton("Rekapan", 1)
            ])
          ]);
        }),
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
                color:
                    selectedTab == index ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ===== FORM CONTENT =====
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        _buildSectionTitle("Alasan Cuti"),
        const SizedBox(height: 8),
        _buildTextField(alasanController, "Tulis alasan cuti...", maxLines: 1),
        const SizedBox(height: 25),
        _buildSectionTitle("Tanggal"),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: GestureDetector(
                  onTap: pickStartDate,
                  // Menggunakan _formatFullDate
                  child: _dateBox(startDate == null
                      ? "Pilih Tanggal Mulai"
                      : _formatFullDate(startDate!)))),
          const SizedBox(width: 10),
          Expanded(
              child: GestureDetector(
                  onTap: pickEndDate,
                  // Menggunakan _formatFullDate
                  child: _dateBox(endDate == null
                      ? "Pilih Tanggal Selesai"
                      : _formatFullDate(endDate!)))),
        ]),
        const SizedBox(height: 25),
        _buildSectionTitle("Lampiran (Opsional)"),
        const SizedBox(height: 8),
        _buildUploadButton(),
        const SizedBox(height: 10),
        if (lampiranBytes != null) _buildFileAttachment(),
        const SizedBox(height: 20),
        _buildSectionTitle("Keterangan (Opsional)"),
        const SizedBox(height: 8),
        _buildTextField(keteranganController, "Tulis keterangan...",
            maxLines: 4),
        const SizedBox(height: 25),
        _buildSubmitButton(),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF7F7F7F), fontWeight: FontWeight.w600));
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F7F7),
          borderRadius: BorderRadius.circular(10)),
      child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration:
              InputDecoration(hintText: hint, border: InputBorder.none)),
    );
  }

  Widget _dateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F7F7),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        const Icon(Icons.calendar_today, size: 18)
      ]),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: pickLampiran,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: Colors.deepOrange, borderRadius: BorderRadius.circular(10)),
        child: const Center(
            child: Text("Upload Lampiran",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildFileAttachment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF3F7F7),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.insert_drive_file, size: 22, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
            child: Text(lampiranName ?? "Lampiran",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600))),
        GestureDetector(
            onTap: removeLampiran,
            child: const Icon(Icons.close, color: Colors.black54)),
      ]),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: (isSubmitted || isFetchingCuti) ? null : _onKirimPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: (isSubmitted || isFetchingCuti)
                ? Colors.blue.shade300
                : const Color(0xFF2B3541),
            borderRadius: BorderRadius.circular(25)),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  isSubmitted
                      ? "Sudah Terkirim"
                      : (isFetchingCuti ? "Memuat..." : "Kirim"),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
