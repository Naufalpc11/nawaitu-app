import 'package:flutter/material.dart';

import '../database/mock_data.dart';
import '../models/history_model.dart';
import '../widgets/empty_state_view.dart';
import 'detail_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<HistoryModel> _histories;

  @override
  void initState() {
    super.initState();
    _histories = List.from(dummyHistories);
  }

  void _navigateToDetail(HistoryModel history) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailHistoryScreen(history: history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: _histories.isEmpty
          ? const EmptyStateView(
              icon: Icons.history,
              title: 'Belum ada riwayat',
              subtitle:
                  'Riwayat ibadah akan muncul setelah jadwal pertama dijalankan',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _histories.length,
              itemBuilder: (context, index) {
                final history = _histories[index];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
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
                      onTap: () => _navigateToDetail(history),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Info Riwayat (Kiri)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    history.title,
                                    style: Theme.of(context)
                                            .textTheme
                                            .titleMedium ??
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    history.date,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        history.scheduledTime,
                                        style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.grey,
                                                ) ??
                                            const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Badge Status Pill (Kanan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: history.isCompleted
                                    ? const Color(0xFFD7F5E5)
                                    : const Color(0xFFFDE6E6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                history.isCompleted ? 'Terlaksana' : 'Terlewat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: history.isCompleted
                                      ? const Color(0xFF0D5C3A)
                                      : const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
