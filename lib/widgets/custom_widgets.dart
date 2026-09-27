import 'package:flutter/material.dart';

/// Reusable Card untuk menampilkan jadwal ibadah beserta statusnya.
class ScheduleCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.time,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    // Penentuan styling badge status berdasarkan status `isDone`
    final Color badgeBgColor = isDone
        ? const Color(0xFFE2F5ED)
        : const Color(0xFFEEEEEE);
    final Color badgeTextColor = isDone
        ? const Color(0xFF16C289)
        : Colors.grey.shade600;
    final String badgeText = isDone ? 'Terlaksana' : 'Belum';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Kiri: Judul dan Jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Bagian Kanan: Badge Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Widget untuk menampilkan tampilan kosong (empty state)
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: const Color(0xFF16C289)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
