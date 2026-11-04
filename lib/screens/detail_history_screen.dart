import 'package:flutter/material.dart';

import '../models/history_model.dart';
import '../widgets/status_badge.dart';

class DetailHistoryScreen extends StatefulWidget {
  final HistoryModel? history;

  const DetailHistoryScreen({
    super.key,
    this.history,
  });

  @override
  State<DetailHistoryScreen> createState() => _DetailHistoryScreenState();
}

class _DetailHistoryScreenState extends State<DetailHistoryScreen> {
  late HistoryModel _currentHistory;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      if (widget.history != null) {
        _currentHistory = widget.history!;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is HistoryModel) {
          _currentHistory = args;
        } else {
          _currentHistory = const HistoryModel(
            id: '',
            title: '',
            date: '',
            scheduledTime: '',
            actualTime: '-',
            isCompleted: false,
          );
        }
      }
      _isInitialized = true;
    }
  }

  void _toggleStatus() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    setState(() {
      if (_currentHistory.isCompleted) {
        _currentHistory = _currentHistory.copyWith(
          isCompleted: false,
          actualTime: '-',
        );
      } else {
        _currentHistory = _currentHistory.copyWith(
          isCompleted: true,
          actualTime: formattedTime,
        );
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _currentHistory.isCompleted
              ? 'Status diubah: Terlaksana (pukul ${_currentHistory.actualTime})'
              : 'Status diubah: Terlewat',
        ),
        backgroundColor: _currentHistory.isCompleted
            ? const Color(0xFF0D5C3A)
            : const Color(0xFFE53935),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentHistory);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context, _currentHistory),
          ),
          title: const Text(
            'Detail Riwayat',
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
              // 1. Card Info Utama (Waktu, Judul, Tanggal, Pill)
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
                      _currentHistory.scheduledTime,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentHistory.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5C3A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentHistory.date,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StatusBadge.fromStatus(
                      isCompleted: _currentHistory.isCompleted,
                      icon: _currentHistory.isCompleted
                          ? Icons.check
                          : Icons.close,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      fontSize: 13,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Section "Catatan Waktu"
              const Text(
                'Catatan Waktu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Waktu Seharusnya',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _currentHistory.scheduledTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade100,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Waktu Terlaksana',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _currentHistory.actualTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _currentHistory.isCompleted
                                ? const Color(0xFF0D5C3A)
                                : const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Tombol Aksi: Mengubah Status Riwayat (Use Case)
              ElevatedButton(
                onPressed: _toggleStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentHistory.isCompleted
                      ? const Color(0xFFFFF1F0)
                      : const Color(0xFF0D5C3A),
                  foregroundColor: _currentHistory.isCompleted
                      ? const Color(0xFFE53935)
                      : Colors.white,
                  side: _currentHistory.isCompleted
                      ? const BorderSide(color: Color(0xFFFFA39E))
                      : BorderSide.none,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentHistory.isCompleted
                          ? Icons.undo
                          : Icons.check_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentHistory.isCompleted
                          ? 'Tandai Menjadi Terlewat'
                          : 'Tandai Sudah Terlaksana',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
