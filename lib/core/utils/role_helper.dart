enum UserRole { admin, manager, sales }

class RoleHelper {
  static UserRole getRoleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return UserRole.admin;
      case 'manager': return UserRole.manager;
      default: return UserRole.sales;
    }
  }

  static bool canManageEmployees(UserRole role) => role == UserRole.admin || role == UserRole.manager;
  static bool canEditGlobalProperties(UserRole role) => role == UserRole.manager;
}