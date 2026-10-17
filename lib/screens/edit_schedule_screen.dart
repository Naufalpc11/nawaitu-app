import 'package:flutter/material.dart';

import '../models/schedule_model.dart';
import '../widgets/day_selector.dart';
import '../widgets/description_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/setting_tile.dart';
import '../widgets/time_picker_card.dart';

class EditScheduleScreen extends StatefulWidget {
  final ScheduleModel? schedule;

  const EditScheduleScreen({
    super.key,
    this.schedule,
  });

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  ScheduleModel? _schedule;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);
  late TextEditingController _titleController;
  late TextEditingController _descController;
  Set<String> _selectedDays = {};
  String _maxNotification = '5 Kali';
  String _snooze = '15 Menit';
  bool _isInitialized = false;

  final List<String> _maxNotificationOptions = const [
    '1 Kali',
    '3 Kali',
    '5 Kali',
    '10 Kali',
  ];

  final List<String> _snoozeOptions = const [
    '5 Menit',
    '10 Menit',
    '15 Menit',
    '30 Menit',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final scheduleData = widget.schedule ??
          (ModalRoute.of(context)?.settings.arguments as ScheduleModel?);

      _schedule = scheduleData;

      int hour = 8;
      int minute = 30;
      if (scheduleData != null) {
        final parts = scheduleData.time.split(':');
        if (parts.length == 2) {
          hour = int.tryParse(parts[0]) ?? 8;
          minute = int.tryParse(parts[1]) ?? 30;
        }
      }
      _selectedTime = TimeOfDay(hour: hour, minute: minute);

      _titleController = TextEditingController(
        text: scheduleData?.title ?? '',
      );
      _descController = TextEditingController(
        text: scheduleData?.description ?? '',
      );
      _selectedDays = Set<String>.from(scheduleData?.days ?? []);
      _maxNotification = scheduleData?.maxNotification ?? '5 Kali';
      _snooze = scheduleData?.snooze ?? '15 Menit';

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _titleController.dispose();
      _descController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D5C3A),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveChanges() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama ibadah tidak boleh kosong!'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    final String formattedTime =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    final baseSchedule = _schedule ??
        ScheduleModel(
          id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          time: formattedTime,
          days: _selectedDays.toList(),
          description: _descController.text.trim(),
          maxNotification: _maxNotification,
          snooze: _snooze,
          isActive: true,
        );

    final updatedSchedule = baseSchedule.copyWith(
      title: title,
      time: formattedTime,
      days: _selectedDays.toList(),
      description: _descController.text.trim(),
      maxNotification: _maxNotification,
      snooze: _snooze,
    );

    Navigator.pop(context, updatedSchedule);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Jadwal',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Card Picker Waktu
            TimePickerCard(
              timeString: formattedTime,
              onTap: _pickTime,
            ),

            const SizedBox(height: 24),

            // 2. Nama Ibadah
            const Text(
              'Nama Ibadah',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama ibadah... (cth: Sholat Dhuha)',
                  hintStyle:
                      TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0D5C3A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Hari Pelaksanaan
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
              selectedDays: _selectedDays.toList(),
              onDayToggle: (day) {
                setState(() {
                  if (_selectedDays.contains(day)) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
            ),

            const SizedBox(height: 20),

            // 4. Deskripsi
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
              controller: _descController,
              hintText: 'Tambahkan catatan khusus disini..',
            ),

            const SizedBox(height: 20),

            // 5. Pengaturan Lanjutan
            const Text(
              'Pengaturan Lanjutan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Maksimal Notifikasi Row
            SettingTile(
              label: 'Maksimal Notifikasi',
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFFF59E0B),
              trailingWidget: DropdownButton<String>(
                value: _maxNotification,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: _maxNotificationOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() {
                      _maxNotification = newVal;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // Jeda (Snooze) Row
            SettingTile(
              label: 'Jeda (Snooze)',
              icon: Icons.alarm,
              iconColor: const Color(0xFFF59E0B),
              trailingWidget: DropdownButton<String>(
                value: _snooze,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                items: _snoozeOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) {
                    setState(() {
                      _snooze = newVal;
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 32),

            // Tombol Simpan Perubahan
            PrimaryButton(
              text: 'Simpan Perubahan',
              onPressed: _saveChanges,
            ),
          ],
        ),
      ),
    );
  }
}
