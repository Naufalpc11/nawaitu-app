import 'package:flutter/material.dart';

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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info Teks (Kiri)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
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
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Label Status (Kanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: badgeTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
