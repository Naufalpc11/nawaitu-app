import 'package:flutter/material.dart';

import '../widgets/custom_widgets.dart';

class JadwalScreen extends StatelessWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Light Gray Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C8259), // Primary Green
        elevation: 0,
        title: const Text(
          'Jadwal Ibadah',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {},
                tooltip: 'Tambah Jadwal',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: screenWidth,
          color: const Color(0xFFF7F7F7),
          child: const Column(
            children: [
              Expanded(
                child: EmptyStateView(
                  icon: Icons.calendar_today,
                  title: 'Belum ada jadwal ibadah',
                  subtitle: 'Tap + untuk menambah jadwal baru',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
