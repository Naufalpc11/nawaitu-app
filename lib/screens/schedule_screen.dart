import 'package:flutter/material.dart';

import '../database/mock_data.dart';
import '../models/schedule_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/schedule_card.dart';
import 'create_schedule_screen.dart';
import 'detail_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late List<ScheduleModel> _schedules;

  @override
  void initState() {
    super.initState();
    _schedules = List.from(dummySchedules);
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push<ScheduleModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateScheduleScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _schedules.add(result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal "${result.title}" berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF0D5C3A),
          ),
        );
      }
    }
  }

  Future<void> _navigateToDetail(int index) async {
    final schedule = _schedules[index];
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScheduleScreen(schedule: schedule),
      ),
    );

    if (!mounted) return;

    if (result == 'delete') {
      setState(() {
        _schedules.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal "${schedule.title}" berhasil dihapus.'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } else if (result is ScheduleModel) {
      setState(() {
        _schedules[index] = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal "${result.title}" berhasil diperbarui.'),
          backgroundColor: const Color(0xFF0D5C3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Jadwal Ibadah',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _navigateToCreate,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _schedules.isEmpty
          ? const EmptyStateView(
              icon: Icons.calendar_month,
              title: 'Belum ada jadwal ibadah',
              subtitle: 'Tap + untuk menambah jadwal baru',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return ScheduleCard(
                  title: schedule.title,
                  time: schedule.time,
                  isActive: schedule.isActive,
                  onToggle: (newValue) {
                    setState(() {
                      _schedules[index] = schedule.copyWith(isActive: newValue);
                    });
                  },
                  onTap: () => _navigateToDetail(index),
                );
              },
            ),
    );
  }
}
