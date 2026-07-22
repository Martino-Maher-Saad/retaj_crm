// تعريف أنواع الحسابات وصلاحيات كل حساب في النظام
// هذا الملف هو المرجع الوحيد لكل صلاحيات النظام

// ─── Enum الأدوار ───
enum AppRole {
  sales,
  leader,
  manager,
  admin,
  superAdmin;

  /// تحويل من String (قاعدة البيانات) إلى AppRole
  static AppRole fromString(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'sales':
        return AppRole.sales;
      case 'leader':
        return AppRole.leader;
      case 'manager':
        return AppRole.manager;
      case 'admin':
        return AppRole.admin;
      case 'super_admin':
        return AppRole.superAdmin;
      default:
        return AppRole.sales; // افتراضي
    }
  }

  /// تحويل إلى String لقاعدة البيانات
  String toDbString() {
    switch (this) {
      case AppRole.sales:
        return 'sales';
      case AppRole.leader:
        return 'leader';
      case AppRole.manager:
        return 'manager';
      case AppRole.admin:
        return 'admin';
      case AppRole.superAdmin:
        return 'super_admin';
    }
  }

  /// الاسم العربي للعرض
  String get nameAr {
    switch (this) {
      case AppRole.sales:
        return 'موظف مبيعات';
      case AppRole.leader:
        return 'قائد فريق';
      case AppRole.manager:
        return 'مدير';
      case AppRole.admin:
        return 'مسؤول النظام';
      case AppRole.superAdmin:
        return 'مسؤول أعلى';
    }
  }

  /// هل هذا الدور أعلى من أو يساوي دوراً معيناً؟
  bool isAtLeast(AppRole minimum) {
    const order = [
      AppRole.sales,
      AppRole.leader,
      AppRole.manager,
      AppRole.admin,
      AppRole.superAdmin,
    ];
    return order.indexOf(this) >= order.indexOf(minimum);
  }
}

// ─── صلاحيات النظام ───
class AppPermissions {
  const AppPermissions._();

  // ══════════════════════════════════════════
  // صلاحيات العملاء (Leads)
  // ══════════════════════════════════════════

  /// هل يرى كل عملاء النظام (مش بس عملاءه)
  static bool canSeeAllLeads(AppRole role) =>
      role.isAtLeast(AppRole.leader);

  /// هل يرى عملاء الموظفين (نطاق صلاحياته)
  static bool canSeeTeamLeads(AppRole role) =>
      role == AppRole.leader;

  /// هل يضيف عميل جديد
  static bool canAddLead(AppRole role) => true; // الكل

  /// هل يعدّل بيانات العميل
  static bool canEditLead(AppRole role) => true; // الكل

  /// هل يضيف أكشن على العميل
  static bool canAddAction(AppRole role) => true; // الكل

  /// هل يحذف (ينقل للـ trash)
  static bool canTrashLead(AppRole role) => true; // الكل

  /// هل يحذف نهائياً من الـ Trash
  static bool canDeletePermanently(AppRole role) =>
      role.isAtLeast(AppRole.admin);

  /// هل يستعيد من الـ Trash
  static bool canRestoreFromTrash(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// هل يحوّل عميل (transfer)
  static bool canTransferLead(AppRole role) =>
      role.isAtLeast(AppRole.leader);

  /// هل يحوّل لأي موظف (مش بس تيمه)
  static bool canTransferToAny(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// هل يرى صفحة التكرارات
  static bool canSeeDuplicates(AppRole role) =>
      role.isAtLeast(AppRole.leader);

  /// هل يدمج التكرارات
  static bool canMergeDuplicates(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// هل يصدّر بيانات العملاء (Export)
  static bool canExportLeads(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// هل يرى صفحة "التحويلات" كاملة (مش بس محوّلون إليه)
  static bool canSeeAllTransfers(AppRole role) =>
      role.isAtLeast(AppRole.leader);

  // ══════════════════════════════════════════
  // صلاحيات العقارات (Properties)
  // ══════════════════════════════════════════

  /// هل يضيف عقار
  static bool canAddProperty(AppRole role) => true; // الكل

  /// هل يعدّل عقار
  static bool canEditProperty(AppRole role) => true; // الكل

  /// هل يحذف عقار نهائياً
  static bool canDeleteProperty(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// هل يصدّر بيانات العقارات
  static bool canExportProperties(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  // ══════════════════════════════════════════
  // صلاحيات الحسابات (Accounts)
  // ══════════════════════════════════════════

  /// هل يرى صفحة إدارة الحسابات
  static bool canSeeAccounts(AppRole role) =>
      role.isAtLeast(AppRole.manager);

  /// الأدوار التي يمكن لهذا الدور إنشاء حسابات بها
  static List<AppRole> creatableRoles(AppRole role) {
    switch (role) {
      case AppRole.manager:
        return [AppRole.sales, AppRole.leader];
      case AppRole.admin:
        return [AppRole.sales, AppRole.leader, AppRole.manager];
      case AppRole.superAdmin:
        return [
          AppRole.sales,
          AppRole.leader,
          AppRole.manager,
          AppRole.admin
        ];
      default:
        return [];
    }
  }

  /// هل يرى حسابات الـ super_admin
  static bool canSeeSuperAdminAccounts(AppRole role) =>
      role == AppRole.superAdmin;

  // ══════════════════════════════════════════
  // صلاحيات الإعدادات (Settings - Admin Only)
  // ══════════════════════════════════════════

  /// هل يرى ويعدّل الـ Stages (حالات العملاء)
  static bool canManageStages(AppRole role) =>
      role.isAtLeast(AppRole.admin);

  /// هل يرى ويعدّل حقول العملاء (Lead Inputs)
  static bool canManageLeadInputs(AppRole role) =>
      role.isAtLeast(AppRole.admin);

  /// هل يرى ويعدّل القوائم (Dropdowns)
  static bool canManageDropdowns(AppRole role) =>
      role.isAtLeast(AppRole.admin);

  // ══════════════════════════════════════════
  // صلاحيات التيم (Teams)
  // ══════════════════════════════════════════

  /// هل يرى صفحة التيم بتاعه
  static bool canSeeTeamPage(AppRole role) =>
      role == AppRole.leader;

  /// هل يعيّن موظفين لتيم
  static bool canAssignTeamMembers(AppRole role) =>
      role.isAtLeast(AppRole.admin);
}
