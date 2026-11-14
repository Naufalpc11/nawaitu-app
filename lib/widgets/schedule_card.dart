import 'package:flutter/material.dart';

import '../models/schedule_model.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String time;
  final bool? isDone;
  final TodayScheduleStatus? todayStatus;
  final bool? isActive;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.time,
    this.isDone,
    this.todayStatus,
    this.isActive,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Penentuan styling badge untuk mode dashboard (3 status atau fallback isDone)
    final TodayScheduleStatus resolvedStatus = todayStatus ??
        ((isDone ?? false)
            ? TodayScheduleStatus.terlaksana
            : TodayScheduleStatus.belumWaktunya);

    final Color badgeBgColor;
    final Color badgeTextColor;
    final String badgeText;

    switch (resolvedStatus) {
      case TodayScheduleStatus.terlaksana:
        badgeBgColor = const Color(0xFFD7F5E5);
        badgeTextColor = const Color(0xFF0D5C3A);
        badgeText = 'Terlaksana';
      case TodayScheduleStatus.terlewat:
        badgeBgColor = const Color(0xFFFDE6E6);
        badgeTextColor = const Color(0xFFE53935);
        badgeText = 'Terlewat';
      case TodayScheduleStatus.belumWaktunya:
        badgeBgColor = const Color(0xFFEEEEEE);
        badgeTextColor = Colors.grey.shade600;
        badgeText = 'Belum Waktunya';
    }

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.titleMedium ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            time,
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

                // Bagian Kanan: Switch Toggle ATAU Status Badge
                if (onToggle != null)
                  Switch(
                    value: isActive ?? false,
                    onChanged: onToggle,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF0D5C3A),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  )
                else if (todayStatus != null || isDone != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: badgeTextColor,
                                fontWeight: FontWeight.w600,
                              ) ??
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
