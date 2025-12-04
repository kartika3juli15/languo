import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _isProcessing = false;
  Rect? _barcodeRect;
  Size? _cameraSize;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
    } else {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
        _isLoading = false;
      });

      if (!result.isGranted) {
        _showPermissionDialog();
      }
    }
  }

  void _showScanResult(String result) {
    setState(() {
      _barcodeRect = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Color(0xFF36546C)),
            const SizedBox(width: 10),
            const Text("Hasil Scan"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data QR Code:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result,
                style: const TextStyle(fontSize: 15, fontFamily: "monospace"),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Waktu: ${DateTime.now().toString().substring(0, 19)}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
              controller.start();
            },
            child: const Text(
              "Scan Lagi",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey, width: 1),
              elevation: 0,
            ),
            child: const Text("Selesai"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Izin Kamera Diperlukan"),
        content:
            const Text("Aplikasi memerlukan akses kamera untuk memindai QR."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _hasPermission
              ? _buildScanner()
              : _buildPermissionDenied(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Background Scanner (camera feed)
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final barcode = capture.barcodes.first;
            final String? data = barcode.rawValue;

            // Update posisi dan ukuran kotak sesuai barcode
            if (barcode.corners != null && barcode.corners!.isNotEmpty) {
              final corners = barcode.corners!;

              double minX = corners[0].dx;
              double maxX = corners[0].dx;
              double minY = corners[0].dy;
              double maxY = corners[0].dy;

              for (var corner in corners) {
                if (corner.dx < minX) minX = corner.dx;
                if (corner.dx > maxX) maxX = corner.dx;
                if (corner.dy < minY) minY = corner.dy;
                if (corner.dy > maxY) maxY = corner.dy;
              }

              setState(() {
                _barcodeRect = Rect.fromLTRB(minX, minY, maxX, maxY);
              });
            }

            if (!_isProcessing && data != null) {
              setState(() => _isProcessing = true);
              controller.stop();
              _showScanResult(data);
            }
          },
        ),

        // Kotak putih dinamis yang muncul saat ada barcode
        if (_barcodeRect != null && !_isProcessing)
          Positioned(
            left: _barcodeRect!.left,
            top: _barcodeRect!.top,
            child: Container(
              width: _barcodeRect!.width,
              height: _barcodeRect!.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner bracket kiri atas
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 5),
                          left: BorderSide(color: Colors.white, width: 5),
                        ),
                      ),
                    ),
                  ),
                  // Corner bracket kanan atas
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 5),
                          right: BorderSide(color: Colors.white, width: 5),
                        ),
                      ),
                    ),
                  ),
                  // Corner bracket kiri bawah
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 5),
                          left: BorderSide(color: Colors.white, width: 5),
                        ),
                      ),
                    ),
                  ),
                  // Corner bracket kanan bawah
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 5),
                          right: BorderSide(color: Colors.white, width: 5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // UI Overlay
        Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Scan QR Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Text description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Pindahkan Kode QR untuk Absensi",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Button Batal
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE75636),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black87,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined,
              size: 80, color: Colors.white54),
          const SizedBox(height: 20),
          const Text(
            "Izin Kamera Ditolak",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Aplikasi memerlukan akses kamera untuk memindai QR code",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE75636),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Buka Pengaturan",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
