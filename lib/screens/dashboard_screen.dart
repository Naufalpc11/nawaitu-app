import 'package:flutter/material.dart';

import '../database/mock_data.dart';
import '../widgets/schedule_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final histories = dummyHistories;
    final int total = histories.length;
    final int completed = histories.where((item) => item.isCompleted).length;
    final double progress = total > 0 ? (completed / total) : 0.0;
    return Scaffold(
      body: Container(
        width: screenWidth,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF042F1E), // Very Dark Green (gelap di kiri atas)
              Color(0xFF0C8259), // Primary Green (terang di kanan bawah)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HEADER
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
                    Text(
                      "Assalamu'alaikum",
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Senin, 8 September 2026",
                      // ignore: deprecated_member_use
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "08:30",
                      style: Theme.of(context).textTheme.displayLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // PROGRESS CARD (Kotak melayang di atas: 0xFF042F1E)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF042F1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            // Ganti "3 Jadwal Hari Ini" menjadi:
                            "$total Jadwal Hari Ini",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF67C29F)),
                          ),
                          Text(
                            // Ganti "2/3 Terlaksana" menjadi:
                            "$completed/$total Terlaksana",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF67C29F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 8,
                            // Ganti angka paten 0.66 menjadi variabel progress:
                            width: (screenWidth - 88) * progress,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16C289),
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
              // AREA BAWAH: SCHEDULE LIST (Light Gray: 0xFFF7F7F7)
              // ==========================================
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jadwal Hari Ini",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: histories.length,
                          itemBuilder: (context, index) {
                            final history = histories[index];
                            return ScheduleCard(
                              title: history.title,
                              time: history.scheduledTime,
                              isDone: history.isCompleted,
                            );
                          },
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
