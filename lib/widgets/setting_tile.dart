import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget trailingWidget;
  final EdgeInsetsGeometry padding;

  const SettingTile({
    super.key,
    required this.label,
    required this.icon,
    this.iconColor = const Color(0xFFF59E0B),
    required this.trailingWidget,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ),
        ),
      ],
    );
  }
}

