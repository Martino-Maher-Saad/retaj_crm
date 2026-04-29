import 'package:get_it/get_it.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/design_repository.dart';
import '../../data/repositories/lead_repository.dart';
import '../../data/repositories/property_repository.dart';
import '../../data/repositories/dropdown_repository.dart';

import '../../data/services/admin_user_service.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/design_service.dart';
import '../../data/services/lead_service.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/property_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/dropdown_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/static_data_manager.dart';

import '../../features/admin_users/cubit/admin_users_cubit.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/designs/cubit/designs_cubit.dart';
import '../../features/layout/cubit/layout_cubit.dart';
import '../../features/leads/cubit/leads_cubit.dart';
import '../../features/profile/cubit/profile_cubit.dart';
import '../../features/properties/cubit/properties_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Cubits ───
  // ملاحظة: نستخدم registerFactory للـ Cubits إذا كنا نريد إنشاء نسخة جديدة كل مرة (مستحسن للـ Cubits)
  // أو registerLazySingleton إذا أردنا الاحتفاظ بنفس الـ State عبر التطبيق
  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerFactory(() => PropertiesCubit(sl()));
  sl.registerFactory(() => LeadCubit(sl()));
  sl.registerFactory(() => DesignsCubit(sl()));
  sl.registerFactory(() => AdminUsersCubit(sl()));
  sl.registerFactory(() => ProfileCubit(sl()));
  sl.registerFactory(() => LayoutCubit());

  // ─── Repositories ───
  sl.registerLazySingleton(() => AuthRepository(sl()));
  sl.registerLazySingleton(() => PropertyRepository(sl(), sl(), sl()));
  sl.registerLazySingleton(() => LeadRepository(sl()));
  sl.registerLazySingleton(() => DesignRepository(sl(), sl(), sl()));
  sl.registerLazySingleton(() => DropdownRepository(sl()));

  // ─── Services ───
  sl.registerLazySingleton(() => AuthService());
  sl.registerLazySingleton(() => PropertyService());
  sl.registerLazySingleton(() => StorageService(Supabase.instance.client));
  sl.registerLazySingleton(() => AiService());
  sl.registerLazySingleton(() => LeadService());
  sl.registerLazySingleton(() => DesignService());
  sl.registerLazySingleton(() => AdminUserService());
  sl.registerLazySingleton(() => ProfileService());
  sl.registerLazySingleton(() => DropdownService());
  sl.registerLazySingleton<StaticDataManager>(() => StaticDataManagerImpl(sl(), sl()));
}
