import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Completer<GoogleMapController> _controller = Completer();

  /// TITIK KANTOR (GANTI SESUAI KEBUTUHAN)
  final LatLng kantorPos = const LatLng(-7.9797, 112.6304); // contoh Malang

  Position? currentPosition;
  double? distanceMeter;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cekGpsDanLokasi();
  }

  /// =====================================================
  /// CEK IZIN GPS + DAPATKAN POSISI DEVICE
  /// =====================================================
  Future<void> _cekGpsDanLokasi() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    // Cek hak akses lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => loading = false);
      return;
    }

    // Ambil lokasi sekarang
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Hitung jarak
    double jarak = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      kantorPos.latitude,
      kantorPos.longitude,
    );

    setState(() {
      currentPosition = pos;
      distanceMeter = jarak;
      loading = false;
    });
  }

  /// =====================================================
  /// VALIDASI RADIUS (100 Meter)
  /// =====================================================
  bool get isDalamRadius {
    if (distanceMeter == null) return false;
    return distanceMeter! <= 100;
  }

  /// =====================================================
  /// KIRIM NILAI KEHALAMAN KEHADIRAN
  /// =====================================================
  void _kirimResult() {
    Navigator.pop(context, isDalamRadius);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentPosition == null) {
      return const Scaffold(
        body: Center(child: Text("Lokasi tidak tersedia")),
      );
    }

    final posisiUser = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Lokasi Anda",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // ← memastikan judul di tengah
        backgroundColor: const Color(0xFF36546C),
        iconTheme: const IconThemeData(
          color: Colors.white, // ← panah back putih
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: posisiUser,
              zoom: 17,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("posisi"),
                position: posisiUser,
                infoWindow: const InfoWindow(title: "Posisi Anda"),
              ),
              Marker(
                markerId: const MarkerId("kantor"),
                position: kantorPos,
                infoWindow: const InfoWindow(title: "Kantor"),
              )
            },
            circles: {
              Circle(
                circleId: const CircleId("radius"),
                center: kantorPos,
                radius: 100, // 👉 100 METER
                strokeColor: Colors.blue,
                strokeWidth: 2,
                fillColor: Colors.blue.withOpacity(0.2),
              )
            },
            onMapCreated: (ctr) => _controller.complete(ctr),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          /// =====================================================
          /// INFO PANEL
          /// =====================================================
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Jarak ke kantor : ${distanceMeter!.toStringAsFixed(2)} m",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDalamRadius ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _kirimResult,
                      child: Text(
                        isDalamRadius
                            ? "DALAM RADIUS – LANJUT CHECK OUT"
                            : "DI LUAR RADIUS – TIDAK BISA CHECK OUT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
