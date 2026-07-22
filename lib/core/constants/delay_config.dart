// ملف مركزي لكل الـ hard-coded values المتعلقة بنظام الـ Delay والجدولة
// عدّل القيم هنا براحتك بدون ما تدور في كل الكود

class DelayConfig {
  const DelayConfig._();

  // ══════════════════════════════════════════
  // وحدات الـ Delay المتاحة
  // يجب أن تكون نفس قيم CHECK constraint في قاعدة البيانات:
  // CHECK (delay_unit IN ('minutes', 'hours', 'days'))
  // ══════════════════════════════════════════

  static const String unitMinutes = 'minutes';
  static const String unitHours = 'hours';
  static const String unitDays = 'days';

  /// قائمة الوحدات للعرض في الـ Dropdown
  static const List<DelayUnit> units = [
    DelayUnit(value: 'minutes', labelAr: 'دقيقة'),
    DelayUnit(value: 'hours', labelAr: 'ساعة'),
    DelayUnit(value: 'days', labelAr: 'يوم'),
  ];

  /// تحويل كود الوحدة إلى اسم عربي
  static String unitToArabic(String? unit) {
    return units
        .firstWhere(
          (u) => u.value == unit,
          orElse: () => DelayUnit(value: unit ?? '', labelAr: unit ?? ''),
        )
        .labelAr;
  }

  // ══════════════════════════════════════════
  // القيم الافتراضية لو stage مش عنده delay
  // ══════════════════════════════════════════

  static const int defaultDelayValue = 48;
  static const String defaultDelayUnit = unitHours;

  // ══════════════════════════════════════════
  // أزرار الجدولة السريعة في نافذة الأكشن
  // عدّل القائمة هنا لو عايز تغيير الخيارات
  // ══════════════════════════════════════════

  static const List<QuickSchedule> quickScheduleOptions = [
    QuickSchedule(label: 'بعد ساعة', minutes: 60),
    QuickSchedule(label: 'بعد ساعتين', minutes: 120),
    QuickSchedule(label: 'غداً', minutes: 1440),
    QuickSchedule(label: 'الأسبوع القادم', minutes: 10080),
  ];

  // ══════════════════════════════════════════
  // حساب هل العميل "متأخر"
  // ══════════════════════════════════════════

  /// يرجع true لو العميل تجاوز وقت الـ delay
  static bool isLeadDelayed({
    required DateTime? lastActionAt,
    required int? delayValue,
    required String? delayUnit,
  }) {
    if (lastActionAt == null || delayValue == null || delayUnit == null) {
      return false;
    }

    final Duration delayDuration = _toDuration(delayValue, delayUnit);
    final DateTime deadline = lastActionAt.add(delayDuration);
    return DateTime.now().isAfter(deadline);
  }

  /// حساب الوقت المتبقي قبل أن يصبح العميل "متأخراً"
  /// يرجع null لو تجاوز الوقت بالفعل
  static Duration? remainingTime({
    required DateTime? lastActionAt,
    required int? delayValue,
    required String? delayUnit,
  }) {
    if (lastActionAt == null || delayValue == null || delayUnit == null) {
      return null;
    }

    final Duration delayDuration = _toDuration(delayValue, delayUnit);
    final DateTime deadline = lastActionAt.add(delayDuration);
    final Duration remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  static Duration _toDuration(int value, String unit) {
    switch (unit) {
      case unitMinutes:
        return Duration(minutes: value);
      case unitHours:
        return Duration(hours: value);
      case unitDays:
        return Duration(days: value);
      default:
        return Duration(hours: value);
    }
  }
}

// ─── Helper Classes ───

class DelayUnit {
  final String value;
  final String labelAr;
  const DelayUnit({required this.value, required this.labelAr});
}

class QuickSchedule {
  final String label;
  final int minutes; // عدد الدقائق من الآن
  const QuickSchedule({required this.label, required this.minutes});

  DateTime get targetDateTime =>
      DateTime.now().add(Duration(minutes: minutes));
}
