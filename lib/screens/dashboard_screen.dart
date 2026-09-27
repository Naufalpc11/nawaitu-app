import 'package:flutter/material.dart';

import '../widgets/custom_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil lebar layar untuk kebutuhan responsivitas
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0C8259), // Primary Green
      body: SafeArea(
        child: Container(
          width: screenWidth,
          color: const Color(0xFF0C8259),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // BAGIAN ATAS: HEADER
              // ==========================================
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 32,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assalamu'alaikum",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Senin, 8 September 2026",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "08:30",
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // BAGIAN TENGAH: PROGRESS CARD
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF096343), // Dark Green
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "3 Jadwal Hari Ini",
                            style: TextStyle(
                              color: Color(0xFF67C29F), // Text Highlight Mint
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "2/3 Terlaksana",
                            style: TextStyle(
                              color: Color(0xFF67C29F), // Text Highlight Mint
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar menggunakan Stack
                      Stack(
                        children: [
                          // Background Bar
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Foreground Progress Bar (66% dari lebar container)
                          Container(
                            height: 8,
                            width: (screenWidth - 88) * 0.66,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16C289), // Mint Green
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // BAGIAN BAWAH: SCHEDULE LIST AREA
              // ==========================================
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F7F7), // Light Gray Background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jadwal Hari Ini",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List Jadwal
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: const [
                            ScheduleCard(
                              title: "Sholat Tahajud",
                              time: "04:30",
                              isDone: true,
                            ),
                            ScheduleCard(
                              title: "Sholat Dhuha",
                              time: "08:10",
                              isDone: true,
                            ),
                            ScheduleCard(
                              title: "Sholat Taubat",
                              time: "13:00",
                              isDone: false,
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
