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

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryModel> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
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

  Future<void> _navigateToDetail(int index) async {
    final history = _histories[index];
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
      setState(() {
        _histories[index] = result;
      });
    }
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
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _histories.length,
                  itemBuilder: (context, index) {
                    final history = _histories[index];
                    return HistoryCard(
                      history: history,
                      onTap: () => _navigateToDetail(index),
                    );
                  },
                ),
    );
  }
}
