import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../database/database_helper.dart';
import '../models/history_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/history_card.dart';

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

  static const Map<String, int> _indonesianMonths = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistories();
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
      _loadHistories();
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

  DateTime? _parseHistoryDate(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;

    // Format utama: "Senin, 14 November 2026"
    final datePart = trimmed.contains(',')
        ? trimmed.split(',').last.trim()
        : trimmed;
    final parts = datePart.split(RegExp(r'\s+'));
    if (parts.length == 3) {
      final int? day = int.tryParse(parts[0]);
      final int? month = _indonesianMonths[parts[1].toLowerCase()];
      final int? year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  List<HistoryModel> get _filteredHistories {
    final range = _selectedDateRange;
    if (range == null) return _histories;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    return _histories.where((item) {
      final parsed = _parseHistoryDate(item.date);
      if (parsed == null) return false;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);
    }).toList();
  }

  String _formatShortDate(DateTime date) {
    return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _selectedDateRange,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      saveText: 'Terapkan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D5C3A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickDateRange,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.date_range_outlined,
                                    size: 20,
                                    color: Color(0xFF0D5C3A),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedDateRange == null
                                          ? 'Filter Rentang Tanggal (Semua)'
                                          : '${_formatShortDate(_selectedDateRange!.start)} - ${_formatShortDate(_selectedDateRange!.end)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _selectedDateRange == null
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                        color: _selectedDateRange == null
                                            ? Colors.grey.shade700
                                            : const Color(0xFF0D5C3A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_selectedDateRange != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Reset filter tanggal',
                                      onPressed: _clearDateRange,
                                    )
                                  else
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
