import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DailyDoaCard extends StatefulWidget {
  const DailyDoaCard({super.key});

  @override
  State<DailyDoaCard> createState() => _DailyDoaCardState();
}

class _DailyDoaCardState extends State<DailyDoaCard> {
  DoaModel? _doa;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDoa();
  }

  Future<void> _loadDoa() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await ApiService.fetchDailyDoa();
      if (mounted) {
        setState(() {
          _doa = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu: Judul & Tombol Muat Ulang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Color(0xFF0C8259),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Doa Hari Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: const Color(0xFF0C8259),
                tooltip: 'Muat ulang',
                onPressed: _isLoading ? null : _loadDoa,
              ),
            ],
          ),

          const Divider(height: 16, thickness: 0.8),

          // Konten Doa
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0C8259),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Memuat doa harian...',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak dapat memuat doa. Periksa koneksi internet Anda.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else if (_doa != null) ...[
            Text(
              _doa!.judul,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D5C3A),
              ),
            ),
            if (_doa!.doaArab.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _doa!.doaArab,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                    height: 1.8,
                  ),
                ),
              ),
            ],
            if (_doa!.arti.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Artinya:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '"${_doa!.arti}"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
