/// موديل خيار واحد في الحقل الديناميكي
/// label: الاسم الظاهري (يمكن تغييره)
/// value: الكود الثابت (لا يتغير أبداً — هذا ما يُخزَّن في الداتا بيز)
class FieldOption {
  final String label;
  final String value;

  const FieldOption({required this.label, required this.value});

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is FieldOption && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

// ─────────────────────────────────────────────────────────
/// موديل حقل العميل — من جدول form_field_definitions
/// يُستخدم لبناء نماذج الإضافة والتعديل ديناميكياً
// ─────────────────────────────────────────────────────────
class FormFieldModel {
  final String id;
  final String entityType;

  /// الكود الثابت الذي لا يتغير أبداً — يُستخدم كـ key في custom_fields
  final String fieldKey;

  /// الاسم الظاهري بالعربية — قابل للتغيير من الأدمن
  final String titleAr;

  /// الاسم الظاهري بالإنجليزية — قابل للتغيير من الأدمن
  final String titleEn;

  final FormFieldInputType inputType;
  final bool isSystem;
  final bool isRequired;
  final bool isEditableSales;
  final bool isEditableTeamLeader;
  final bool isEditableManager;
  final bool isActive;
  final bool showInForm;
  final bool showInCard;
  final bool canFilter;
  final bool isExportable;
  final bool isShowSales;
  final bool isShowManager;
  final bool isShowTeamLeader;

  /// للـ selectStatic: قائمة اختيارات ثابتة — كل خيار {label, value}
  /// القيمة المحفوظة في custom_fields هي دائماً value (ثابتة)
  final List<FieldOption> options;

  /// للـ select_ref: اسم الجدول المرجعي في الداتا بيز
  /// مثال: 'cities', 'lead_statuses', 'property_types'
  final String? refTable;

  final String? placeholderAr;
  final int fieldOrder;

  const FormFieldModel({
    required this.id,
    required this.entityType,
    required this.fieldKey,
    required this.titleAr,
    this.titleEn = '',
    required this.inputType,
    this.isSystem = false,
    this.isRequired = false,
    this.isEditableSales = true,
    this.isEditableTeamLeader = true,
    this.isEditableManager = true,
    this.isActive = true,
    this.showInForm = true,
    this.showInCard = false,
    this.canFilter = false,
    this.isExportable = true,
    this.isShowSales = true,
    this.isShowManager = true,
    this.isShowTeamLeader = true,
    this.options = const [],
    this.refTable,
    this.placeholderAr,
    this.fieldOrder = 99,
  });

  /// للتوافق مع الكود القديم — يُعيد titleAr
  String get title => titleAr;

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    // ── options: يدعم JSON Array أو String مفصول بفاصلة (Legacy) ──
    final rawOptions = json['options'];
    List<FieldOption> options = [];

    if (rawOptions is List) {
      options = rawOptions.map((e) {
        if (e is Map<String, dynamic>) {
          return FieldOption.fromJson(e);
        } else {
          // Legacy: String فقط — نجعل label = value
          final str = e.toString();
          return FieldOption(label: str, value: str);
        }
      }).toList();
    } else if (rawOptions is String && rawOptions.isNotEmpty) {
      // Legacy: فاصلة مفصولة
      options = rawOptions.split(',').map((e) {
        final str = e.trim();
        return FieldOption(label: str, value: str);
      }).toList();
    }

    return FormFieldModel(
      id: json['id'] ?? '',
      entityType: json['entity_type'] ?? 'lead',
      fieldKey: json['field_key'] ?? '',
      // يدعم title_ar أو title (للتوافق مع البيانات الحالية)
      titleAr: json['title_ar']?.toString() ?? json['title']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      inputType: FormFieldInputType.fromString(json['input_type']),
      isSystem: json['is_system'] ?? false,
      isRequired: json['is_required'] ?? false,
      isEditableSales: json['is_editable_sales'] ?? json['is_editable'] ?? true,
      isEditableTeamLeader: json['is_editable_team_leader'] ?? json['is_editable'] ?? true,
      isEditableManager: json['is_editable_manager'] ?? json['is_editable'] ?? true,
      isActive: json['is_active'] ?? true,
      showInForm: json['show_in_form'] ?? true,
      showInCard: json['show_in_card'] ?? false,
      canFilter: json['can_filter'] ?? false,
      isExportable: json['is_exportable'] ?? true,
      isShowSales: json['is_show_sales'] ?? true,
      isShowManager: json['is_show_manager'] ?? true,
      isShowTeamLeader: json['is_show_team_leader'] ?? true,
      options: options,
      refTable: json['ref_table']?.toString(),
      placeholderAr: json['placeholder_ar']?.toString(),
      fieldOrder: json['field_order'] ?? 99,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'field_key': fieldKey,
        'title_ar': titleAr,
        'title_en': titleEn,
        'input_type': inputType.toDbString(),
        'is_system': isSystem,
        'is_required': isRequired,
        'is_editable_sales': isEditableSales,
        'is_editable_team_leader': isEditableTeamLeader,
        'is_editable_manager': isEditableManager,
        'is_active': isActive,
        'show_in_form': showInForm,
        'show_in_card': showInCard,
        'can_filter': canFilter,
        'is_exportable': isExportable,
        'is_show_sales': isShowSales,
        'is_show_manager': isShowManager,
        'is_show_team_leader': isShowTeamLeader,
        'options':
            options.isEmpty ? null : options.map((o) => o.toJson()).toList(),
        'ref_table': refTable,
        'placeholder_ar': placeholderAr,
        'field_order': fieldOrder,
      };

  FormFieldModel copyWith({
    String? titleAr,
    String? titleEn,
    bool? isRequired,
    bool? isEditableSales,
    bool? isEditableTeamLeader,
    bool? isEditableManager,
    bool? isActive,
    bool? showInForm,
    bool? showInCard,
    bool? canFilter,
    bool? isExportable,
    bool? isShowSales,
    bool? isShowManager,
    bool? isShowTeamLeader,
    List<FieldOption>? options,
    String? refTable,
    String? placeholderAr,
    int? fieldOrder,
  }) {
    return FormFieldModel(
      id: id,
      entityType: entityType,
      fieldKey: fieldKey,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      inputType: inputType,
      isSystem: isSystem,
      isRequired: isRequired ?? this.isRequired,
      isEditableSales: isEditableSales ?? this.isEditableSales,
      isEditableTeamLeader: isEditableTeamLeader ?? this.isEditableTeamLeader,
      isEditableManager: isEditableManager ?? this.isEditableManager,
      isActive: isActive ?? this.isActive,
      showInForm: showInForm ?? this.showInForm,
      showInCard: showInCard ?? this.showInCard,
      canFilter: canFilter ?? this.canFilter,
      isExportable: isExportable ?? this.isExportable,
      isShowSales: isShowSales ?? this.isShowSales,
      isShowManager: isShowManager ?? this.isShowManager,
      isShowTeamLeader: isShowTeamLeader ?? this.isShowTeamLeader,
      options: options ?? this.options,
      refTable: refTable ?? this.refTable,
      placeholderAr: placeholderAr ?? this.placeholderAr,
      fieldOrder: fieldOrder ?? this.fieldOrder,
    );
  }

  /// هل يظهر لهذا الدور بناءً على إعدادات الأدمن
  bool isVisibleForRole(String role) {
    switch (role.toLowerCase()) {
      case 'sales':
        return isShowSales;
      case 'leader':
      case 'team_leader':
        return isShowTeamLeader;
      case 'manager':
      case 'admin':
      case 'super_admin':
        return isShowManager;
      default:
        return true;
    }
  }

  /// هل يمكن لهذا الدور تعديله (بعد الإنشاء)
  bool isEditableForRole(String role) {
    bool editable;
    switch (role.toLowerCase()) {
      case 'sales':
        editable = isEditableSales;
        break;
      case 'leader':
      case 'team_leader':
        editable = isEditableTeamLeader;
        break;
      case 'manager':
      case 'admin':
      case 'super_admin':
        editable = isEditableManager;
        break;
      default:
        editable = true;
    }
    if (!editable) return false;
    return isVisibleForRole(role);
  }
}

// ─────────────────────────────────────────────────────────
/// أنواع حقول الإدخال المدعومة
// ─────────────────────────────────────────────────────────
enum FormFieldInputType {
  text,
  number,
  textarea,
  selectRef,    // dropdown مرتبط بجدول (ref_table)
  selectStatic, // dropdown قيم ثابتة (options)
  date,
  checkbox,
  action;

  static FormFieldInputType fromString(String? val) {
    switch (val) {
      case 'text':
        return FormFieldInputType.text;
      case 'number':
        return FormFieldInputType.number;
      case 'textarea':
        return FormFieldInputType.textarea;
      case 'select_ref':
        return FormFieldInputType.selectRef;
      case 'select':
      case 'select_static':
      case 'selectStatic':
        return FormFieldInputType.selectStatic;
      case 'date':
        return FormFieldInputType.date;
      case 'checkbox':
        return FormFieldInputType.checkbox;
      case 'action':
        return FormFieldInputType.action;
      default:
        return FormFieldInputType.text;
    }
  }

  String toDbString() {
    switch (this) {
      case FormFieldInputType.text:
        return 'text';
      case FormFieldInputType.number:
        return 'number';
      case FormFieldInputType.textarea:
        return 'textarea';
      case FormFieldInputType.selectRef:
        return 'select_ref';
      case FormFieldInputType.selectStatic:
        return 'select';
      case FormFieldInputType.date:
        return 'date';
      case FormFieldInputType.checkbox:
        return 'checkbox';
      case FormFieldInputType.action:
        return 'action';
    }
  }

  String get labelAr {
    switch (this) {
      case FormFieldInputType.text:
        return 'نص قصير';
      case FormFieldInputType.number:
        return 'رقم';
      case FormFieldInputType.textarea:
        return 'نص طويل';
      case FormFieldInputType.selectRef:
        return 'قائمة منسدلة (من جدول)';
      case FormFieldInputType.selectStatic:
        return 'قائمة منسدلة (ثابتة)';
      case FormFieldInputType.date:
        return 'تاريخ';
      case FormFieldInputType.checkbox:
        return 'نعم / لا';
      case FormFieldInputType.action:
        return 'صلاحية إجراء';
    }
  }
}

// ─────────────────────────────────────────────────────────
/// خريطة الجداول المسموح بالربط بها في حقل select_ref
/// key: اسم الجدول في الداتا بيز
/// value: الاسم الظاهري للأدمن في شاشة الإدارة
// ─────────────────────────────────────────────────────────
const Map<String, String> kAllowedRefTables = {
  'communication_channels': 'قنوات التواصل',
  'cities': 'المدن',
  'governorates': 'المحافظات',
  'property_types': 'أنواع العقارات',
  'listing_types': 'أنواع الإدراج',
  'lead_platforms': 'منصات العملاء',
  'lead_statuses': 'حالات العميل',
  'lead_exclusion_reasons': 'أسباب الاستبعاد',
  'profiles': 'الموظفون',
  'lead_rates': 'تقييمات العملاء',
  'property_sources': 'مصادر العقارات',
  'advertising_platforms': 'منصات الإعلانات',
  'property_approval_statuses': 'حالات موافقة العقار',
  'task_statuses': 'حالات المهام',
  'meeting_types': 'أنواع الاجتماعات',
  'meeting_purposes': 'أغراض الاجتماعات',
  'activity_types': 'أنواع النشاطات',
};
