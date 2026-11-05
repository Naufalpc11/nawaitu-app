import 'dart:convert';

import 'package:http/http.dart' as http;

/// Model data untuk menampung respon JSON dari API Doa Harian
class DoaModel {
  final String judul;
  final String doaArab;
  final String arti;

  const DoaModel({
    required this.judul,
    required this.doaArab,
    required this.arti,
  });

  factory DoaModel.fromJson(Map<String, dynamic> json) {
    return DoaModel(
      judul: (json['judul'] as String?)?.trim() ?? 'Doa Harian',
      doaArab: (json['doa'] as String?)?.trim() ?? '',
      arti: (json['artinya'] as String?)?.trim() ?? '',
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://api.myquran.com/v2';
  static const String doaEndpoint = '/doa/acak';

  /// Melakukan HTTP GET Request ke server internet
  static Future<DoaModel> fetchDailyDoa() async {
    final url = Uri.parse('$baseUrl$doaEndpoint');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['status'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          return DoaModel.fromJson(data);
        } else {
          throw Exception('Format data API tidak sesuai');
        }
      } else {
        throw Exception(
          'Gagal mengambil data dari server (Kode: ${response.statusCode})',
        );
      }
    } catch (e) {
      // Tangani jika offline / gagal koneksi
      rethrow;
    }
  }
}
