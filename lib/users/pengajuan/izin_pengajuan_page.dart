import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/izin_service.dart';
import '../rekapan/izin_rekapan_user_page.dart';
import 'package:intl/intl.dart';
import 'package:languo/users/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanIzinPage extends StatefulWidget {
  final int initialTab;

  const PengajuanIzinPage({super.key, this.initialTab = 0});

  @override
  State<PengajuanIzinPage> createState() => _PengajuanIzinPageState();
}

class _PengajuanIzinPageState extends State<PengajuanIzinPage> {
  final _izinService = IzinService();
  final _auth = FirebaseAuth.instance;

  int selectedTab = 0;
  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
    Intl.defaultLocale = 'id_ID';
    loadHolidays();
  }

  DateTime? tanggalMulai;
  DateTime? tanggalSelesai;

  Uint8List? lampiranBytes;
  String? lampiranName;

  final TextEditingController perihalController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  bool isSubmitted = false;
  bool isLoading = false;

  List<DateTime> _holidays = [];

  Future<void> loadHolidays() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection("holidays").get();

      final List<DateTime> fetched = snap.docs.map((d) {
        final ts = d['date'] as Timestamp;
        final dt = ts.toDate();
        return DateTime(dt.year, dt.month, dt.day);
      }).toList();

      setState(() {
        _holidays = fetched;
      });
    } catch (e) {
      _showMessage("Gagal memuat hari libur");
    }
  }

  bool isHoliday(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _holidays.any((h) => h.isAtSameMomentAs(normalized));
  }

  bool _isSelectableDay(DateTime day) {
    // Sabtu / Minggu
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }

    // Hari libur nasional
    if (isHoliday(day)) {
      return false;
    }

    return true;
  }

  DateTime _getNextSelectableDate() {
    DateTime date = DateTime.now();
    while (!_isSelectableDay(date)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  // ======================== TANGGAL ========================
  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalMulai ?? _getNextSelectableDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: _isSelectableDay,
    );

    if (picked != null) {
      setState(() {
        tanggalMulai = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalSelesai ?? tanggalMulai ?? _getNextSelectableDate(),
      firstDate: tanggalMulai ?? DateTime(2000),
      lastDate: DateTime(2100),
      selectableDayPredicate: _isSelectableDay,
    );

    if (picked != null) {
      setState(() {
        tanggalSelesai = DateTime(picked.year, picked.month, picked.day);
      });
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

  // ======================== VALIDASI SEBELUM KONFIRM ========================
  bool _validateFormBeforeConfirm() {
    if (perihalController.text.isEmpty) {
      _showMessage("Perihal izin belum diisi");
      return false;
    }
    if (tanggalMulai == null || tanggalSelesai == null) {
      _showMessage("Tanggal belum dipilih");
      return false;
    }
    if (lampiranBytes == null || lampiranName == null) {
      _showMessage("Lampiran belum diunggah");
      return false;
    }

    if (!lampiranName!.toLowerCase().endsWith('.pdf')) {
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
                fontSize: 17,
              ),
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

      await _izinService.kirimPengajuan(
        userId: userId,
        perihal: perihalController.text,
        tanggalMulai: tanggalMulai!,
        tanggalSelesai: tanggalSelesai!,
        keterangan: keteranganController.text,
        lampiranBytes: lampiranBytes!,
        fileName: lampiranName!,
      );

      setState(() {
        isSubmitted = true;
        perihalController.clear();
        keteranganController.clear();
        tanggalMulai = null;
        tanggalSelesai = null;
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
      body: Column(children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: selectedTab == 0 ? _buildForm() : const RekapanIzinPage(),
        )
      ]),
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
              "Izin",
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

  // ===== TAB =====
  Widget _buildTabBar() {
    return Transform.translate(
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
        const SizedBox(height: 10),
        const Text("Perihal Izin",
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
            controller: perihalController,
            decoration: const InputDecoration(
                hintText: "Tulis perihal izin...", border: InputBorder.none),
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
                child: _dateBox(tanggalMulai == null
                    ? "Pilih Tanggal"
                    : "${tanggalMulai!.day} ${_monthName(tanggalMulai!.month)} ${tanggalMulai!.year}"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: pickEndDate,
                child: _dateBox(tanggalSelesai == null
                    ? "Pilih Tanggal"
                    : "${tanggalSelesai!.day} ${_monthName(tanggalSelesai!.month)} ${tanggalSelesai!.year}"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text("Lampiran",
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
