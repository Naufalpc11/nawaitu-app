import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hadis_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.myquran.com/v3/hadis/enc';

  static Future<HadisModel> fetchDailyHadis({int maxChars = 280}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      final t = DateTime.now().millisecondsSinceEpoch + attempt;
      final url = Uri.parse('$baseUrl/random?t=$t');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == true && body['data'] != null) {
          final hadis = HadisModel.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          if (hadis.terjemahan.length <= maxChars || attempt == 2) {
            return hadis;
          }
        }
      }
    }

    throw Exception('Gagal memuat hadis dari server');
  }
}
