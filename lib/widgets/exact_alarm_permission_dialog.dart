import 'package:flutter/material.dart';

/// Dialog konfirmasi untuk mengarahkan pengguna ke pengaturan izin alarm presisi.
Future<bool?> showExactAlarmPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        'Izin Alarm Presisi',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: const Text(
        'Agar pengingat ibadah dan fitur Ingatkan Nanti (snooze) muncul tepat waktu tanpa tertunda sistem baterai, aktifkan izin "Alarm & pengingat" untuk Nawaitu.',
        style: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            'Nanti',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D5C3A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Buka Pengaturan'),
        ),
      ],
    ),
  );
}
