import 'package:flutter/material.dart';

const Map<String, int> _indonesianMonths = {
  'januari': 1,
  'februari': 2,
  'maret': 3,
  'april': 4,
  'mei': 5,
  'juni': 6,
  'juli': 7,
  'agustus': 8,
  'september': 9,
  'oktober': 10,
  'november': 11,
  'desember': 12,
};

const List<String> _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

DateTime? parseHistoryDate(String dateStr) {
  final trimmed = dateStr.trim();
  if (trimmed.isEmpty) return null;

  final datePart =
      trimmed.contains(',') ? trimmed.split(',').last.trim() : trimmed;
  final parts = datePart.split(RegExp(r'\s+'));
  if (parts.length == 3) {
    final int? day = int.tryParse(parts[0]);
    final int? month = _indonesianMonths[parts[1].toLowerCase()];
    final int? year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return DateTime.tryParse(trimmed);
}

String formatShortIndonesianDate(DateTime date) {
  return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
}

class HistoryDateFilterBar extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onRangeChanged;

  const HistoryDateFilterBar({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  Future<DateTime?> _pickSingleDate(
    BuildContext context,
    DateTime initialDate,
  ) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D5C3A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textTheme: baseTheme.textTheme.copyWith(
              displayLarge: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate = selectedRange?.start ?? today;
    DateTime endDate = selectedRange?.end ?? today;

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildDateBox({
              required String label,
              required DateTime value,
              required VoidCallback onTap,
            }) {
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0D5C3A).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF0D5C3A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatShortIndonesianDate(value),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.edit_calendar_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Pilih Rentang Tanggal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildDateBox(
                    label: 'Dari Tanggal',
                    value: startDate,
                    onTap: () async {
                      final result = await _pickSingleDate(context, startDate);
                      if (result != null) {
                        setDialogState(() {
                          startDate = result;
                          if (endDate.isBefore(startDate)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  buildDateBox(
                    label: 'Sampai Tanggal',
                    value: endDate,
                    onTap: () async {
                      final result = await _pickSingleDate(context, endDate);
                      if (result != null) {
                        setDialogState(() {
                          endDate = result;
                          if (startDate.isAfter(endDate)) {
                            startDate = endDate;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    DateTimeRange(start: startDate, end: endDate),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5C3A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      onRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
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
            onTap: () => _pickDateRange(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    size: 20,
                    color: Color(0xFF0D5C3A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedRange == null
                          ? 'Filter Rentang Tanggal (Semua)'
                          : '${formatShortIndonesianDate(selectedRange!.start)} - ${formatShortIndonesianDate(selectedRange!.end)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selectedRange == null
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: selectedRange == null
                            ? Colors.grey.shade700
                            : const Color(0xFF0D5C3A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedRange != null)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Reset filter tanggal',
                      onPressed: () => onRangeChanged(null),
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
