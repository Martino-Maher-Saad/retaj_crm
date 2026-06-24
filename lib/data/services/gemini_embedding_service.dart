import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiEmbeddingService {
  final String? _manualApiKey;

  GeminiEmbeddingService([String? apiKey]) : _manualApiKey = apiKey;

  /// توليد الـ Vector بحجم 768 بعداً باستخدام نموذج Google Gemini الحديث
  Future<List<double>> generateEmbedding(String text) async {
    String apiKey = _manualApiKey ?? '';

    // جلب المفتاح ديناميكياً من قاعدة البيانات في حالة عدم تمريره يدوياً
    if (apiKey.isEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('system_settings')
            .select('value')
            .eq('key', 'gemini_api_key')
            .maybeSingle();

        apiKey = response?['value']?.toString() ?? '';
      } catch (e) {
        print('=== GEMINI EMBEDDING ERROR: فشل جلب الـ API Key من قاعدة البيانات ===');
        print('الخطأ: $e');
      }
    }

    if (apiKey.isEmpty) {
      throw Exception('خطأ: لم يتم العثور على مفتاح Gemini API Key في إعدادات النظام.');
    }

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
