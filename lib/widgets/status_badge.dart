import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize = 12,
  });

  /// Factory untuk status riwayat ibadah (Terlaksana / Terlewat).
  factory StatusBadge.fromStatus({
    Key? key,
    required bool isCompleted,
    String? text,
    IconData? icon,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    double fontSize = 12,
  }) {
    return StatusBadge(
      key: key,
      text: text ?? (isCompleted ? 'Terlaksana' : 'Terlewat'),
      bgColor:
          isCompleted ? const Color(0xFFD7F5E5) : const Color(0xFFFDE6E6),
      textColor:
          isCompleted ? const Color(0xFF0D5C3A) : const Color(0xFFE53935),
      icon: icon,
      padding: padding,
      fontSize: fontSize,
    );
  }

  /// Factory untuk status aktif/nonaktif jadwal.
  factory StatusBadge.activeSchedule({
    Key? key,
    required bool isActive,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    double fontSize = 13,
  }) {
    return StatusBadge(
      key: key,
      text: isActive ? 'Status : Aktif' : 'Status : Nonaktif',
      bgColor: isActive ? const Color(0xFFD7F5E5) : const Color(0xFFEEEEEE),
      textColor: isActive ? const Color(0xFF0D5C3A) : Colors.grey.shade600,
      padding: padding,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 16,
              color: textColor,
            ),
          ],
        ],
      ),
    );
  }
}

