import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<String>? onDayToggle;

  static const List<String> defaultDays = [
    'Ahd',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
  ];

  const DaySelector({
    super.key,
    required this.selectedDays,
    this.onDayToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: defaultDays.map((day) {
        final bool isSelected = selectedDays.contains(day);
        final bool isInteractive = onDayToggle != null;

        Widget chip = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFF0D5C3A) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D5C3A)
                  : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        );

        if (isInteractive) {
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onDayToggle!(day),
            child: chip,
          );
        }

        return chip;
      }).toList(),
    );
  }
}

