import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/schedule_model.dart';
import '../widgets/day_selector.dart';
import '../widgets/description_card.dart';
import '../widgets/setting_tile.dart';
import '../widgets/status_badge.dart';

class DetailScheduleScreen extends StatefulWidget {
  final ScheduleModel? schedule;

  const DetailScheduleScreen({
    super.key,
    this.schedule,
  });

  @override
  State<DetailScheduleScreen> createState() => _DetailScheduleScreenState();
}

class _DetailScheduleScreenState extends State<DetailScheduleScreen> {
  late ScheduleModel _currentSchedule;
  bool _isInitialized = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      if (widget.schedule != null) {
        _currentSchedule = widget.schedule!;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is ScheduleModel) {
          _currentSchedule = args;
        } else {
          _currentSchedule = const ScheduleModel(
            id: '',
            title: '',
            time: '08:30',
            days: [],
            description: '',
            maxNotification: '5 Kali',
            snooze: '15 Menit',
            isActive: false,
          );
        }
      }
      _isInitialized = true;
    }
  }

  Future<void> _navigateToEdit() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.editSchedule,
      arguments: _currentSchedule,
    );

    if (updated is ScheduleModel) {
      setState(() {
        _currentSchedule = updated;
      });
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Jadwal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus jadwal "${_currentSchedule.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Tutup dialog
                Navigator.pop(context, 'delete'); // Kembali dengan instruksi hapus
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context, _currentSchedule),
        ),
        title: const Text(
          'Detail Jadwal',
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
          // Tombol Edit (Bulat Hijau Muda / Pensil)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _navigateToEdit,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFFFBBF24), // Pensil kuning keemasan
                  size: 20,
                ),
              ),
            ),
          ),

          // Tombol Hapus (Bulat Merah Muda / Tempat Sampah)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _confirmDelete,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFFCA5A5),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Card Info Utama (Waktu, Judul, Pill Status)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              child: Column(
                children: [
                  Text(
                    _currentSchedule.time,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSchedule.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D5C3A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusBadge.activeSchedule(
                    isActive: _currentSchedule.isActive,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Hari Pelaksanaan
            const Text(
              'Hari Pelaksanaan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            DaySelector(
              selectedDays: _currentSchedule.days,
            ),

            const SizedBox(height: 20),

            // 3. Deskripsi
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DescriptionCard(
              text: _currentSchedule.description,
            ),

            const SizedBox(height: 20),

            // 4. Pengaturan Lanjutan
            const Text(
              'Pengaturan Lanjutan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Maksimal Notifikasi
            SettingTile(
              label: 'Maksimal Notifikasi',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              trailingWidget: Text(
                _currentSchedule.maxNotification,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Jeda (Snooze)
            SettingTile(
              label: 'Jeda (Snooze)',
              icon: Icons.alarm,
              iconColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              trailingWidget: Text(
                _currentSchedule.snooze,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
