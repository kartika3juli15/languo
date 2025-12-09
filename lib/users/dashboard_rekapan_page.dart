import 'package:flutter/material.dart';
import 'package:languo/users/rekapan/kehadiran_rekapan_user_page.dart';
import 'package:languo/users/rekapan/cuti_rekapan_user_page.dart';
import 'package:languo/users/rekapan/izin_rekapan_user_page.dart';
import 'package:languo/users/rekapan/sakit_rekapan_user_page.dart';

class DashboardRekapanPage extends StatefulWidget {
  const DashboardRekapanPage({super.key});

  @override
  State<DashboardRekapanPage> createState() => _DashboardRekapanPageState();
}

class _DashboardRekapanPageState extends State<DashboardRekapanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  KehadiranPage(),
                  RekapanCutiPage(),
                  RekapanIzinPage(),
                  RekapanSakitPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              "Dashboard Rekapan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF36546C),
        indicator: BoxDecoration(
          color: const Color(0xFF36546C),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: "Hadir"),
          Tab(text: "Cuti"),
          Tab(text: "Izin"),
          Tab(text: "Sakit"),
        ],
      ),
    );
  }
}
