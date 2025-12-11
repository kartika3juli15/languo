import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // --- Warna dari LoginScreen ---
  static const Color accentColor = Color(0xFFE75636); // Deep Orange
  static const Color primaryColor = Color(0xFF2B3541); // Biru Tua
  static const Color backgroundColorOnboarding =
      Color(0xFF223546); // Latar Belakang Onboarding (Navy)
  static const Color primaryLightColor = Color(0xFF7F9FB4); // Biru Muda Pucat

  // --- Page View Controller & State ---
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // --- Konten Onboarding ---
  final List<Map<String, dynamic>> _onboardingData = const [
    {
      'title': 'Selamat Datang',
      'subtitle': 'Sistem Informasi Presensi JTI',
      'description':
          'Aplikasi presensi modern yang dirancang khusus untuk kenyamanan dan efisiensi di lingkungan JTI.',
      'image': 'assets/bgdepan.png',
    },
    {
      'title': 'Presensi Cepat',
      'subtitle': 'Lacak Kehadiran Anda',
      'description':
          'Lakukan presensi hanya dengan beberapa ketukan. Catatan kehadiran Anda tersimpan aman dan akurat secara real-time.',
      'image': 'assets/bgbelakang.png',
    },
    {
      'title': 'Manajemen Cuti',
      'subtitle': 'Ajukan Cuti Dengan Mudah',
      'description':
          'Kirim permintaan cuti langsung dari aplikasi dan pantau sisa jatah cuti Anda tanpa perlu dokumen fisik.',
      'image': 'assets/logosipres.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        final page = _pageController.page;
        if (page != null && page.isFinite) {
          setState(() {
            _currentPage = page.round();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(() {});
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // --- Widget Logo ---
  // Warna primaryLightColor dibutuhkan di sini untuk teks JTI
// Pastikan variabel primaryLightColor di atas tersedia di scope class Anda.
// static const Color primaryLightColor = Color(0xFF7F9FB4);

  Widget _buildLogoHeader({double logoSize = 150, bool isFullText = false}) {
    // --- SKALA DARI UKURAN DASAR LOGO (DIAMBIL DARI LOGIN: 150) ---
    // Gunakan 150 sebagai referensi dasar skala.
    const double baseLogoSize = 90.0;
    final double scaleFactor = logoSize / baseLogoSize;

    // --- Ukuran yang diskalakan (Diambil dari proporsi login 180x180) ---
    final double finalStackSize = 180.0 * scaleFactor;
    final double bgBelakangWidth = 120.0 * scaleFactor;
    final double bgDepanWidth = 110.0 * scaleFactor;
    final double logoUtamaWidth = 80.0 * scaleFactor;
    final double jtiIconHeight =
        0.35 * logoSize; // Pertahankan rasio dengan logoSize input

    // --- Pergeseran yang diskalakan ---
    final double offsetTopBelakang = 10.0 * scaleFactor;
    final double offsetRightBelakang = 25.0 * scaleFactor;
    final double offsetBottomDepan = .0 * scaleFactor;

    return Column(
      children: [
        // Stack Logo Utama
        SizedBox(
          width: finalStackSize,
          height: finalStackSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Background Biru (Bg Belakang) - DIGESER
              Positioned(
                top: offsetTopBelakang,
                right: offsetRightBelakang,
                child: Image.asset(
                  "assets/bgbelakang.png",
                  width: bgBelakangWidth,
                ),
              ),

              // 2. Background Putih (Bg Depan) - DIGESER
              Positioned(
                bottom: offsetBottomDepan,
                child: Image.asset(
                  "assets/bgdepan.png",
                  width: bgDepanWidth,
                ),
              ),

              // 3. Logo Utama - Tetap di tengah (Di atas Bg Depan)
              Image.asset("assets/logosipres.png", width: logoUtamaWidth),
            ],
          ),
        ),

        // Teks SipresJTI
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "S",
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 0.9,
              ),
            ),
            const Text(
              "ipres",
              style: TextStyle(
                fontSize: 24,
                color: primaryLightColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
              ),
              child: Image.asset(
                "assets/jti.png",
                height: jtiIconHeight,
                fit: BoxFit.fitHeight,
              ),
            ),
          ],
        ),

        if (isFullText)
          Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Sistem Informasi Presensi JTI",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // --- Widget untuk Setiap Halaman Onboarding ---
  Widget _buildOnboardingPage(
      {required String title,
      required String subtitle,
      required String description}) {
    return SingleChildScrollView(
      // Bungkus konten dalam Padding
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 50),
          // 1. Header Logo (Ukuran besar)
          _buildLogoHeader(logoSize: 130),

          const SizedBox(height: 30),

          // Teks
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: primaryLightColor.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 35),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColorOnboarding,
      body: SafeArea(
        child: Column(
          children: [
            // Area PageView (Mengambil sebagian besar ruang)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  if (index >= _onboardingData.length) {
                    return const SizedBox.shrink();
                  }
                  return _buildOnboardingPage(
                    title: _onboardingData[index]['title']!,
                    subtitle: _onboardingData[index]['subtitle']!,
                    description: _onboardingData[index]['description']!,
                  );
                },
              ),
            ),
            const SizedBox(height: 5),

            // Area Indikator dan Tombol
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
              child: Column(
                children: [
                  // Indikator Titik-titik (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? accentColor
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tombol Mulai / Selanjutnya
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage < _onboardingData.length - 1) {
                          // Geser ke halaman berikutnya
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeIn,
                          );
                        } else {
                          // Navigasi ke LoginScreen
                          _navigateToLogin();
                        }
                      },
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? "Mulai"
                            : "Selanjutnya",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
