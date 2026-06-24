import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gemini_embedding_service.dart';

class AiService {
  // رابط الـ API المرفوع لايف على Hugging Face
  // شغال 24/7 ومجاني ومحدش يقدر يوقفه!
  static const String _apiUrl = 'https://martino564-retaj.hf.space/embed';
  final _geminiService = GeminiEmbeddingService();

  Future<List<double>> generateEmbedding(String text, {bool isSearch = false, bool useGemini = false}) async {
    if (useGemini) {
      try {
        print('=== AI SERVICE (Google Gemini): جاري الحساب (768 بعداً) ===');
        final vector = await _geminiService.generateEmbedding(text);
        print('=== تم بنجاح من Gemini ✅، حجم الـ Vector: ${vector.length} ===');
        return vector;
      } catch (e) {
        print('=== AI SERVICE (Google Gemini) ERROR ===');
        print('=== الخطأ: $e ===');
        rethrow;
      }
    }

    try {
      print('=== AI SERVICE (Python Microservice): جاري الحساب ===');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'is_query': isSearch, // إحنا بنرمي الكورة في ملعب السيرفر وهو بيتصرف!
        }),
      );

      if (response.statusCode != 200) {
        print('=== AI SERVICE ERROR: status ${response.statusCode} ===');
        print('=== Body: ${response.body} ===');
        throw Exception('فشل الاتصال بالـ API: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      
      final vector = (decoded['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      print('=== تم بنجاح ✅، حجم الـ Vector: ${vector.length} ===');
      return vector;
    } catch (e, stackTrace) {
      print('=== AI SERVICE ERROR ===');
      print('=== الخطأ: $e ===');
      print('=== التفاصيل: $stackTrace ===');
      rethrow;
    }
  }
}
