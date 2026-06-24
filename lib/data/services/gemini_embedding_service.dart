import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiEmbeddingService {
  static const String defaultApiKey = 'AIzaSyA10ZTeZJH3dq-UQyBmBe8CZBNcqySczxM';
  final String apiKey;

  GeminiEmbeddingService([String? apiKey]) : apiKey = apiKey ?? defaultApiKey;

  /// توليد الـ Vector بحجم 768 بعداً باستخدام نموذج Google Gemini الحديث
  Future<List<double>> generateEmbedding(String text) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "models/gemini-embedding-001",
          "content": {
            "parts": [
              {"text": text}
            ]
          },
          "outputDimensionality": 768
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'فشل الاتصال بـ Gemini API: كود الحالة ${response.statusCode}\nالتفاصيل: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      
      if (data['embedding'] == null || data['embedding']['values'] == null) {
        throw Exception('الرد المستلم من Google لا يحتوي على الـ Vector المطلوب: $data');
      }

      final values = data['embedding']['values'] as List;
      return values.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      print('=== GEMINI EMBEDDING ERROR: فشل توليد الـ Vector ===');
      print('الخطأ: $e');
      rethrow;
    }
  }
}
