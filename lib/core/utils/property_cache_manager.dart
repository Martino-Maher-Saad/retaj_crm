

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PropertyCacheManager {
  static const String _cacheKey = 'property_images_cache';

  // إنشاء نسخة واحدة (Singleton) تعمل بكفاءة على الويب
  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30), // حفظ الصور لمدة 30 يوم في المتصفح
      maxNrOfCacheObjects: 1000, // أقصى عدد صور يتم تخزينها

      // ملاحظة تقنية: قمنا بحذف حقل الـ repo تماماً
      // على الويب، المكتبة ستستخدم تلقائياً الـ WebCacheInfoRepository
      // الذي يخزن البيانات في IndexedDB (مخزن المتصفح الدائم)
      // دون الحاجة لـ path_provider أو ملفات نظام.
    ),
  );
}
