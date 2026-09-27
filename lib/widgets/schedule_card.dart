import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool
  isMissed; // Tambahan untuk halaman Riwayat yang ada status "Terlewat"

  const ScheduleCard({
    super.key,
    required this.title,
    required this.time,
    this.isDone = false,
    this.isMissed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Penentuan Warna Background & Text berdasarkan Status
    Color bgColor;
    Color textColor;
    String statusText;

    if (isMissed) {
      bgColor = const Color(0xFFFDE9E9); // Merah muda terang
      textColor = const Color(0xFFE53935); // Merah tua
      statusText = "Terlewat";
    } else if (isDone) {
      bgColor = const Color(0xFFE2F5ED); // Hijau mint terang
      textColor = const Color(0xFF16C289); // Hijau Nawaitu
      statusText = "Terlaksana";
    } else {
      bgColor = const Color(0xFFEEEEEE); // Abu-abu
      textColor = Colors.grey.shade600;
      statusText = "Belum";
    }

    return Container(
      // Responsive: Lebar menyesuaikan pembungkusnya
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info Teks (Kiri)
          // Expanded agar teks tidak nabrak label jika judulnya kepanjangan (responsif)
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
                  maxLines: 1, // Agar rapi
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

          // Spacer kecil
          const SizedBox(width: 12),

          // Label Status (Kanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
