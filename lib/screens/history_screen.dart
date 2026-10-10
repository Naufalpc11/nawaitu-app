import 'package:flutter/material.dart';

import '../database/mock_data.dart';
import '../models/history_model.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/history_card.dart';
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
                return HistoryCard(
                  history: history,
                  onTap: () => _navigateToDetail(history),
                );
              },
            ),
    );
  }
}
