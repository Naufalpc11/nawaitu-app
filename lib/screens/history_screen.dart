import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../database/database_helper.dart';
import '../models/history_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/history_card.dart';
import '../widgets/history_date_filter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  List<HistoryModel> _histories = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncAndLoadHistories();
    DatabaseHelper.instance.historyChangeNotifier.addListener(_loadHistories);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DatabaseHelper.instance.historyChangeNotifier
        .removeListener(_loadHistories);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndLoadHistories();
    }
  }

  Future<void> _syncAndLoadHistories() async {
    await DatabaseHelper.instance.markMissedSchedulesForToday();
    await _loadHistories();
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

  List<HistoryModel> get _filteredHistories {
    final range = _selectedDateRange;
    if (range == null) return _histories;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    return _histories.where((item) {
      final parsed = parseHistoryDate(item.date);
      if (parsed == null) return false;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);
    }).toList();
  }

  Future<void> _navigateToDetail(HistoryModel history) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.detailHistory,
      arguments: history,
    );

    if (result is HistoryModel) {
      await DatabaseHelper.instance.updateHistoryStatus(
        id: result.id,
        isCompleted: result.isCompleted,
        actualTime: result.actualTime,
      );
      if (!mounted) return;
      setState(() {
        final idx = _histories.indexWhere((h) => h.id == result.id);
        if (idx != -1) {
          _histories[idx] = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistories = _filteredHistories;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Riwayat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF042F1E), Color(0xFF0C8259)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D5C3A)),
            )
          : _histories.isEmpty
              ? const EmptyStateView(
                  icon: Icons.history,
                  title: 'Belum ada riwayat',
                  subtitle:
                      'Riwayat ibadah akan muncul setelah jadwal pertama dijalankan',
                )
              : Column(
                  children: [
                    HistoryDateFilterBar(
                      selectedRange: _selectedDateRange,
                      onRangeChanged: (range) {
                        setState(() {
                          _selectedDateRange = range;
                        });
                      },
                    ),
                    Expanded(
                      child: filteredHistories.isEmpty
                          ? const EmptyStateView(
                              icon: Icons.date_range_outlined,
                              title: 'Tidak ada riwayat',
                              subtitle:
                                  'Tidak ada catatan ibadah pada rentang tanggal yang dipilih',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              itemCount: filteredHistories.length,
                              itemBuilder: (context, index) {
                                final history = filteredHistories[index];
                                return HistoryCard(
                                  history: history,
                                  onTap: () => _navigateToDetail(history),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
