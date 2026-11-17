import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/schedule_model.dart';
import '../widgets/daily_hadis_card.dart';
import '../widgets/dashboard_clock_header.dart';
import '../widgets/schedule_card.dart';
import '../widgets/today_progress_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  List<TodayScheduleItem> _todaySchedules = [];
  bool _isLoading = true;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodaySchedules();
    DatabaseHelper.instance.historyChangeNotifier
        .addListener(_loadTodaySchedules);
    DatabaseHelper.instance.scheduleChangeNotifier
        .addListener(_loadTodaySchedules);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DatabaseHelper.instance.historyChangeNotifier
        .removeListener(_loadTodaySchedules);
    DatabaseHelper.instance.scheduleChangeNotifier
        .removeListener(_loadTodaySchedules);
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DatabaseHelper.instance.markMissedSchedulesForToday().then((_) {
        _loadTodaySchedules();
      });
    }
  }

  void _toggleSheet() {
    if (_sheetController.isAttached) {
      final currentSize = _sheetController.size;
      final targetSize = currentSize > 0.30 ? 0.11 : 0.65;
      _sheetController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadTodaySchedules() async {
    final data = await DatabaseHelper.instance.getTodayDashboardSchedules();
    if (mounted) {
      setState(() {
        _todaySchedules = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final int total = _todaySchedules.length;
    final int completed = _todaySchedules
        .where((item) => item.status == TodayScheduleStatus.terlaksana)
        .length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardClockHeader(),
                    TodayProgressCard(
                      total: total,
                      completed: completed,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 24.0,
                          right: 24.0,
                          bottom: (screenHeight * 0.11) + 14.0,
                        ),
                        child: const DailyHadisCard(),
                      ),
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.11,
                minChildSize: 0.11,
                maxChildSize: 0.65,
                snap: true,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 12,
                              offset: Offset(0, -3),
                            ),
                          ],
                        ),
                        child: ListView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 10,
                            left: 24,
                            right: 24,
                            bottom: 24,
                          ),
                          children: [
                            GestureDetector(
                              onTap: _toggleSheet,
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _toggleSheet,
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                "Jadwal Hari Ini",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0D5C3A),
                                  ),
                                ),
                              )
                            else if (_todaySchedules.isEmpty)
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
                              ..._todaySchedules.map((item) {
                                return ScheduleCard(
                                  title: item.title,
                                  time: item.time,
                                  todayStatus: item.status,
                                );
                              }),
                          ],
                        ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
