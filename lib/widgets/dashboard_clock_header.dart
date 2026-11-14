import 'dart:async';

import 'package:flutter/material.dart';

class DashboardClockHeader extends StatefulWidget {
  const DashboardClockHeader({super.key});

  @override
  State<DashboardClockHeader> createState() => _DashboardClockHeaderState();
}

class _DashboardClockHeaderState extends State<DashboardClockHeader> {
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
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateDateTime();
    });
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 22,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Assalamu'alaikum",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _currentDate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTime,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
