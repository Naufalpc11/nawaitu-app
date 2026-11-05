import 'dart:async';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/history_model.dart';
import '../widgets/daily_doa_card.dart';
import '../widgets/schedule_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<HistoryModel> _histories = [];
  bool _isLoading = true;

  Timer? _clockTimer;
  String _currentDate = '';
  String _currentTime = '';

  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    // Timer dicek setiap detik agar tepat saat menit berganti, tampilan jam langsung terupdate
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDateTime();
    });
    _loadHistories();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final dayName = _days[now.weekday - 1];
    final monthName = _months[now.month - 1];
    final dateStr = '$dayName, ${now.day} $monthName ${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (_currentDate != dateStr || _currentTime != timeStr) {
      if (mounted) {
        setState(() {
          _currentDate = dateStr;
          _currentTime = timeStr;
        });
      } else {
        _currentDate = dateStr;
        _currentTime = timeStr;
      }
    }
  }

  Future<void> _loadHistories() async {
    final data = await DatabaseHelper.instance.getAllHistories();
    if (mounted) {
      setState(() {
        _histories = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int total = _histories.length;
    final int completed = _histories.where((item) => item.isCompleted).length;
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
                      _currentDate,
                      // ignore: deprecated_member_use
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentTime,
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
                            "$total Jadwal Hari Ini",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF67C29F)),
                          ),
                          Text(
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
              // AREA BAWAH: DO'A HARIAN (API) & JADWAL (SQLITE)
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
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // 1. Kartu Doa Hari Ini (Hasil Hit REST API Online)
                      const DailyDoaCard(),

                      // 2. Judul Section Jadwal Ibadah
                      Text(
                        "Jadwal Hari Ini",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),

                      // 3. Daftar Kartu dari Database SQLite Lokal
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D5C3A),
                            ),
                          ),
                        )
                      else if (_histories.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              'Belum ada jadwal ibadah hari ini',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._histories.map((history) {
                          return ScheduleCard(
                            title: history.title,
                            time: history.scheduledTime,
                            isDone: history.isCompleted,
                          );
                        }),
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
