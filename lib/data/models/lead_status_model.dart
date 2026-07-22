import 'package:flutter/material.dart';

/// موديل نوع المرحلة — من جدول stage_types
/// يحدد السلوك البرمجي لكل مرحلة
class StageTypeModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final StageTypeBehavior behavior;

  const StageTypeModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.behavior,
  });

  factory StageTypeModel.fromJson(Map<String, dynamic> json) {
    return StageTypeModel(
      id: json['id'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      behavior: StageTypeBehavior.fromString(json['behavior']),
    );
  }
}

/// سلوك المرحلة - يحدد أي حقول إضافية تظهر في نافذة الأكشن
enum StageTypeBehavior {
  fresh,      // جديد - لا يحتاج أكشن (الحالة الافتراضية)
  following,  // متابعة - موعد + ملاحظة + هل تم الرد
  meeting,    // اجتماع - موعد + نوع + مكان + غرض
  exclusion,  // استبعاد - سبب الاستبعاد
  doneDeal;   // تعاقد - كود العقار + ربح الشركة

  static StageTypeBehavior fromString(String? val) {
    switch (val) {
      case 'fresh':
        return StageTypeBehavior.fresh;
      case 'following':
        return StageTypeBehavior.following;
      case 'meeting':
        return StageTypeBehavior.meeting;
      case 'exclusion':
        return StageTypeBehavior.exclusion;
      case 'done_deal':
        return StageTypeBehavior.doneDeal;
      default:
        return StageTypeBehavior.following;
    }
  }

  String get toDbString {
    switch (this) {
      case StageTypeBehavior.fresh:
        return 'fresh';
      case StageTypeBehavior.following:
        return 'following';
      case StageTypeBehavior.meeting:
        return 'meeting';
      case StageTypeBehavior.exclusion:
        return 'exclusion';
      case StageTypeBehavior.doneDeal:
        return 'done_deal';
    }
  }

  /// هل هذه المرحلة نهائية (لا يمكن إضافة أكشن بعدها)
  bool get isTerminal =>
      this == StageTypeBehavior.exclusion || this == StageTypeBehavior.doneDeal;

  /// هل تحتاج تحديد موعد متابعة
  bool get requiresSchedule =>
      this == StageTypeBehavior.following || this == StageTypeBehavior.meeting;
}

// ─────────────────────────────────────────────────────────
/// موديل حالة العميل — من جدول lead_statuses
/// كل حالة = tab في الواجهة
// ─────────────────────────────────────────────────────────
class LeadStatusModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? stageTypeId;
  final StageTypeBehavior? behavior; // من stage_types عبر JOIN
  final int? delayValue;
  final String? delayUnit;
  final bool isDefault;
  final bool isTerminal;
  final bool requiresSchedule;
  final int stageOrder;
  final String? colorHex;
  final bool isActive;

  const LeadStatusModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.stageTypeId,
    this.behavior,
    this.delayValue,
    this.delayUnit,
    this.isDefault = false,
    this.isTerminal = false,
    this.requiresSchedule = false,
    this.stageOrder = 99,
    this.colorHex,
    this.isActive = true,
  });

  factory LeadStatusModel.fromJson(Map<String, dynamic> json) {
    // نقرأ behavior من stage_types إذا كان موجوداً كـ JOIN
    final stageTypeMap = json['stage_types'] as Map<String, dynamic>?;
    final behavior = stageTypeMap != null
        ? StageTypeBehavior.fromString(stageTypeMap['behavior'])
        : StageTypeBehavior.fromString(json['behavior']);

    return LeadStatusModel(
      id: json['id'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      stageTypeId: json['stage_type_id']?.toString(),
      behavior: behavior,
      delayValue: json['delay_value'] as int?,
      delayUnit: json['delay_unit']?.toString(),
      isDefault: json['is_default'] ?? false,
      isTerminal: json['is_terminal'] ?? false,
      requiresSchedule: json['requires_schedule'] ?? false,
      stageOrder: json['stage_order'] ?? 99,
      colorHex: json['color_hex']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }

  /// لون الحالة كـ Flutter Color
  Color get color {
    if (colorHex == null || colorHex!.isEmpty) return const Color(0xFF6B7280);
    try {
      final hex = colorHex!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6B7280);
    }
  }

  /// هل هي مرحلة Fresh
  bool get isFresh => behavior == StageTypeBehavior.fresh;
}
