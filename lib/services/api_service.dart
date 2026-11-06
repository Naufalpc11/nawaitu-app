import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hadis_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.myquran.com/v3/hadis/enc';

  /// Mengambil 1 Hadis Acak dari API MyQuran (HadeethEnc)
  /// Dilengkapi filter otomatis agar memprioritaskan hadis yang pendek & padat
  static Future<HadisModel> fetchDailyHadis({int maxChars = 280}) async {
    // Coba hingga 3 kali untuk mendapatkan hadis yang ringkas (< 280 karakter)
    for (int attempt = 0; attempt < 3; attempt++) {
      final t = DateTime.now().millisecondsSinceEpoch + attempt;
      final url = Uri.parse('$baseUrl/random?t=$t');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == true && body['data'] != null) {
          final hadis =
              HadisModel.fromJson(body['data'] as Map<String, dynamic>);
          // Jika teks terjemahannya ringkas atau ini percobaan terakhir, pakai hadis ini
          if (hadis.terjemahan.length <= maxChars || attempt == 2) {
            return hadis;
          }
        }
      }
    }

    throw Exception('Gagal memuat hadis dari server');
  }
}
