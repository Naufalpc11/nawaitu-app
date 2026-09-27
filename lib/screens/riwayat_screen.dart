import 'package:flutter/material.dart';

import '../widgets/custom_widgets.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Light Gray Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C8259), // Primary Green
        elevation: 0,
        title: const Text(
          'Riwayat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: screenWidth,
          color: const Color(0xFFF7F7F7),
          child: const Column(
            children: [
              Expanded(
                child: EmptyStateView(
                  icon: Icons.history,
                  title: 'Belum ada riwayat',
                  subtitle: 'Riwayat ibadah akan muncul setelah jadwal pertama dijalankan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
