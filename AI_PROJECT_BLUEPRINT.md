# AI_PROJECT_BLUEPRINT.md — Retaj CRM
> **Source of Truth** for any AI model implementing features in this project.
> **Rule #1:** Never deviate from these patterns. Every new feature must mirror this architecture exactly.

---

## 1. Project Tech Stack

| Category | Package | Version | Purpose |
|---|---|---|---|
| **Backend / DB** | `supabase_flutter` | ^2.12.0 | Authentication + Database (PostgreSQL via REST) |
| **State Management** | `flutter_bloc` + `bloc` | ^9.1.1 / ^9.1.0 | Cubit-based state management |
| **State Equality** | `equatable` | ^2.0.8 | Efficient state comparison in BLoC |
| **Responsive UI** | `flutter_screenutil` | ^5.9.3 | Responsive sizing for Desktop (1920×1080 design size) |
| **Fonts** | `google_fonts` (indirect) + Cairo font | — | Cairo font family used globally |
| **Icons** | `font_awesome_flutter` | ^10.7.0 | Icon library supplement |
| **Image Handling** | `image_picker` + `flutter_image_compress` | ^1.2.1 / ^2.4.0 | Pick & compress images before upload |
| **Image Display** | `cached_network_image` + `flutter_cache_manager` | ^3.4.1 | Network image caching |
| **Loading Skeleton** | `shimmer` | ^3.0.0 | Shimmer loading placeholders |
| **Localization** | `intl` | ^0.20.2 | Date/number formatting |
| **Responsive Grid** | `responsive_grid_list` | ^1.4.1 | Responsive grid layouts |

**No routing package** — uses `Navigator.push` with `MaterialPageRoute` directly.
**No dependency injection package** — dependencies are manually composed in `initState` or `main.dart`.

---

## 2. Architecture Pattern

**Custom Layered Architecture** (inspired by Clean Architecture but simplified):

```
Presentation Layer  →  features/[feature]/screens/  +  features/[feature]/widgets/
State Layer         →  features/[feature]/cubit/
Domain/Use-case     →  data/repositories/             (this IS the "use-case" layer)
Data Layer          →  data/services/  +  data/models/
Core / Shared       →  core/
```

> This is **NOT** strict Clean Architecture (no separate `domain/` folder with abstract repositories).
> The Repository class directly wraps the Service — it is the boundary between raw Supabase data and typed Dart models.

---

## 3. Folder Map

```
lib/
├── main.dart                       # App entry point: Supabase init, StaticDataManager init, root BlocProvider
│
├── core/                           # App-wide shared code (no business logic)
│   ├── constants/
│   │   ├── app_colors.dart         # AppColors class — all static const Color values
│   │   ├── app_constants.dart      # AppConstants — border radii, spacing, padding values
│   │   ├── app_strings.dart        # AppStrings — hardcoded string literals (Arabic)
│   │   └── app_text_styles.dart    # AppTextStyles class — all static TextStyle getters
│   ├── error/
│   │   └── app_exceptions.dart     # AppException, NetworkException, ServerException, AuthCustomException
│   ├── theme/
│   │   └── app_theme.dart          # AppTheme.lightTheme — MaterialApp ThemeData (Material3)
│   ├── utils/
│   │   ├── number_formatter.dart   # Utility: format numbers (e.g., prices) to Arabic-friendly strings
│   │   ├── property_cache_manager.dart  # Custom CacheManager for property images
│   │   ├── responsive_debouncer_wrapper.dart  # Widget: debounces rapid UI events
│   │   ├── role_helper.dart        # Utility: role-based permission checks
│   │   ├── static_data_manager.dart # Singleton: loads JSON assets (cities, property types, etc.) at startup
│   │   └── validators.dart         # Form field validators
│   └── widgets/                    # Reusable, generic UI components (no business logic)
│       ├── custom_button.dart
│       ├── custom_search_bar.dart
│       ├── custom_text_form_field.dart
│       └── form_toggle_tile.dart
│
├── data/                           # Data layer — Supabase interaction + models
│   ├── models/
│   │   ├── lead_model.dart         # LeadModel — fromJson, toJson, copyWith
│   │   ├── property_model.dart     # PropertyModel — fromJson, toJson, copyWith (most complex)
│   │   ├── profile_model.dart      # ProfileModel — user profile with role
│   │   ├── location_model.dart     # LocationModel
│   │   ├── property_image_model.dart
│   │   ├── property_filter_model.dart
│   │   ├── property_type_model.dart
│   │   └── design_model.dart
│   ├── services/                   # Raw Supabase queries — THROWS exceptions, no error handling here
│   │   ├── auth_service.dart
│   │   ├── lead_service.dart
│   │   ├── property_service.dart
│   │   ├── storage_service.dart    # Supabase Storage bucket operations (image upload/delete)
│   │   └── design_service.dart
│   └── repositories/               # Error handling + model mapping — wraps services
│       ├── auth_repository.dart
│       ├── lead_repository.dart
│       ├── property_repository.dart
│       └── design_repository.dart
│
├── features/                       # Feature modules — each is self-contained
│   ├── auth/
│   │   ├── cubit/                  # auth_cubit.dart + auth_states.dart
│   │   ├── screens/                # LoginWebScreen
│   │   └── widgets/
│   ├── layout/
│   │   └── screens/                # LayoutScreen — main shell with sidebar navigation
│   ├── dashboard/
│   │   ├── cubit/
│   │   ├── screens/
│   │   └── widgets/
│   ├── leads/
│   │   ├── cubit/                  # leads_cubit.dart + leads_state.dart
│   │   ├── screens/                # LeadsManagementScreen, LeadFormScreen, LeadDetailsScreen
│   │   └── widgets/                # LeadCard + sub-widget folders (list/, details/)
│   ├── properties/
│   │   ├── cubit/
│   │   ├── screens/
│   │   └── widgets/                # Organized into form_sections/ subfolder
│   └── designs/
│       ├── cubit/
│       ├── screens/
│       └── widgets/
```

---

## 4. Coding Style & Conventions

### 4.1 File & Class Naming
| Item | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `lead_service.dart`, `app_colors.dart` |
| Classes | `PascalCase` | `LeadService`, `AppColors`, `LeadCubit` |
| Variables / params | `camelCase` | `currentFilter`, `isLoadingMore` |
| Private members | `_camelCase` | `_repository`, `_supabase`, `_scrollController` |
| Constants | `camelCase` in a `static const` class | `AppColors.brandPrimary` |
| State classes | `[Feature]Initial`, `[Feature]Loading`, `[Feature]Loaded`, `[Feature]Error` | `LeadInitial`, `LeadLoaded` |
| Cubit classes | `[Feature]Cubit` | `LeadCubit`, `PropertiesCubit` |

### 4.2 Widget Preferences
- **`StatelessWidget`** for all pure display widgets (cards, sections, reusable components).
- **`StatefulWidget`** for screens that own a Cubit instance or have `ScrollController` / form state.
- Screens that own a Cubit use **`AutomaticKeepAliveClientMixin`** to preserve state across tab navigations. Must call `super.build(context)` and set `wantKeepAlive => true`.
- **Arabic-first UI**: All user-visible strings are in Arabic. Comments in code are also Arabic.
- Form screens are broken into **`form_sections/`** folder with one widget per logical section (e.g., `location_section.dart`, `status_section.dart`).

### 4.3 Responsive Sizing
- **ALWAYS** use `.w`, `.h`, `.sp`, `.r` from `flutter_screenutil`.
- Design reference size is **1920×1080** (desktop app).
- Example: `padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)`.
- Text size: use `.sp` — e.g., `fontSize: 14.sp` — handled centrally in `AppTextStyles`.

### 4.4 Styling — Always Use Core Constants
```dart
// ✅ CORRECT
backgroundColor: AppColors.bgSurface,
style: AppTextStyles.h2,
// ❌ NEVER
backgroundColor: Colors.white,
style: TextStyle(fontSize: 20, color: Color(0xFF1D1F5E)),
```

---

## 5. Error Handling Strategy (3-Layer)

```
Service    → Throws Supabase exceptions raw (PostgrestException). No try/catch.
Repository → Catches PostgrestException + generic Exception.
            Maps to Arabic user-friendly String messages or custom AppException.
            Uses _handlePostgrestError(e) helper to switch on e.code.
Cubit      → Catches String thrown by Repository.
            Emits LeadError(e.toString()).
            For mutations: emits LeadError then immediately re-emits currentState
            to restore the UI (optimistic roll-back pattern).
Screen     → BlocConsumer listener shows errors as SnackBar with AppColors.brandAccent background.
```

**Key rule for Repository error messages:** Always in **Arabic** so they can be shown directly to end users.

```dart
// Repository pattern
try {
  return await _service.someMethod();
} on PostgrestException catch (e) {
  throw _handlePostgrestError(e);  // returns Arabic string
} catch (e) {
  throw "فشل الاتصال بالسيرفر، تأكد من الإنترنت";
}

String _handlePostgrestError(PostgrestException e) {
  switch (e.code) {
    case '23505': return "هذا السجل موجود بالفعل";
    default: return "خطأ في السيرفر: ${e.message}";
  }
}
```

---

## 6. Data Flow Logic

```
User Action (e.g., scroll, button tap)
    ↓
Screen calls Cubit method (e.g., _cubit.addLead(newLead))
    ↓
Cubit calls Repository (e.g., await _repository.addNewLead(lead))
    ↓
Repository calls Service (e.g., await _leadService.addLead(lead))
    ↓
Service executes Supabase query and returns raw Map or typed Model
    ↓
Repository maps result / handles errors → returns typed Model
    ↓
Cubit performs "Surgical Update":
  - Does NOT re-fetch the entire list
  - Mutates the in-memory list via map/where/spread
  - Calls emit(currentState.copyWith(updatedList))
    ↓
BlocBuilder/BlocConsumer rebuilds only affected widgets
```

### Pagination Pattern
- Page size: **15 items** (`from: 0, to: 14`; next page: `from: currentList.length, to: currentList.length + 14`)
- `ScrollController` adds listener; triggers `loadMoreLeads` when `pixels >= maxScrollExtent - 200`
- State has `isLoadingMore: bool` — list shows a trailing `CircularProgressIndicator` when true
- State has `totalCount: int` — guards against fetching beyond available records

---

## 7. Boilerplate Examples

### 7.1 Service Skeleton
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feature_model.dart';

class FeatureService {
  final _supabase = Supabase.instance.client;

  Future<List<FeatureModel>> fetchAll({required int from, required int to}) async {
    final response = await _supabase
        .from('features')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);
    return (response as List).map((e) => FeatureModel.fromJson(e)).toList();
  }

  Future<FeatureModel> insert(FeatureModel model) async {
    final response = await _supabase
        .from('features')
        .insert(model.toJson())
        .select()
        .single();
    return FeatureModel.fromJson(response);
  }

  Future<FeatureModel> update(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('features')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return FeatureModel.fromJson(response);
  }

  Future<void> delete(String id) async =>
      await _supabase.from('features').delete().eq('id', id);
}
```

### 7.2 Model Skeleton
```dart
class FeatureModel {
  final String id;
  final String nameAr;       // Arabic strings use _Ar suffix
  final String? description; // Optional fields are nullable
  final bool status;
  final DateTime? createdAt;

  FeatureModel({
    required this.id,
    required this.nameAr,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    return FeatureModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? '',
      description: json['description'],
      status: json['status'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_ar': nameAr,
      'description': description,
      'status': status,
    };
    // NOTE: Never include 'id' or 'created_at' in toJson — DB generates these
  }

  FeatureModel copyWith({
    String? id,
    String? nameAr,
    String? description,
    bool? status,
    DateTime? createdAt,
  }) {
    return FeatureModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Private helper for safe int casting from DB (smallint may arrive as String)
  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
```

### 7.3 Repository Skeleton
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feature_model.dart';
import '../services/feature_service.dart';

class FeatureRepository {
  final FeatureService _service;
  FeatureRepository(this._service);

  Future<List<FeatureModel>> getAll({required int from, required int to}) async {
    try {
      return await _service.fetchAll(from: from, to: to);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "حدث خطأ غير متوقع أثناء جلب البيانات";
    }
  }

  Future<FeatureModel> add(FeatureModel model) async {
    try {
      return await _service.insert(model);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "فشل الاتصال بالسيرفر، تأكد من الإنترنت";
    }
  }

  Future<FeatureModel> update(String id, Map<String, dynamic> updates) async {
    try {
      updates.remove('id'); // CRITICAL: always remove id before update
      return await _service.update(id, updates);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "فشل تحديث البيانات، حاول مرة أخرى";
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.delete(id);
    } on PostgrestException catch (e) {
      throw _handlePostgrestError(e);
    } catch (e) {
      throw "لم يتم الحذف، حدث خطأ تقني";
    }
  }

  String _handlePostgrestError(PostgrestException e) {
    switch (e.code) {
      case '23505': return "هذا السجل موجود بالفعل";
      case '42P01': return "خطأ في الوصول لجدول البيانات";
      default: return "خطأ في السيرفر: ${e.message}";
    }
  }
}
```

### 7.4 State Skeleton
```dart
import 'package:equatable/equatable.dart';
import '../../../data/models/feature_model.dart';

abstract class FeatureState extends Equatable {
  const FeatureState();
  @override
  List<Object?> get props => [];
}

class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}

class FeatureLoaded extends FeatureState {
  final List<FeatureModel> items;
  final int totalCount;
  final bool isLoadingMore;

  const FeatureLoaded({
    required this.items,
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  FeatureLoaded copyWith({
    List<FeatureModel>? items,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return FeatureLoaded(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, isLoadingMore];
}

class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);
  @override
  List<Object?> get props => [message];
}
```

### 7.5 Cubit Skeleton
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/feature_model.dart';
import '../../../data/repositories/feature_repository.dart';
import 'feature_state.dart';

class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository _repository;
  FeatureCubit(this._repository) : super(FeatureInitial());

  Future<void> loadItems({bool isRefresh = false}) async {
    if (isRefresh) emit(FeatureLoading());

    try {
      final count = await _repository.getCount(); // implement as needed
      final items = await _repository.getAll(from: 0, to: 14);
      emit(FeatureLoaded(items: items, totalCount: count));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is! FeatureLoaded) return;
    final current = state as FeatureLoaded;
    if (current.isLoadingMore || current.items.length >= current.totalCount) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.getAll(
        from: current.items.length,
        to: current.items.length + 14,
      );
      emit(current.copyWith(
        items: [...current.items, ...next],
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  // Surgical add — prepend to list, NO full refetch
  Future<void> addItem(FeatureModel newItem) async {
    if (state is! FeatureLoaded) return;
    final current = state as FeatureLoaded;
    try {
      final added = await _repository.add(newItem);
      emit(current.copyWith(
        items: [added, ...current.items],
        totalCount: current.totalCount + 1,
      ));
    } catch (e) {
      emit(FeatureError(e.toString()));
      emit(current); // Roll back to previous state
    }
  }

  // Surgical update — replace item in list by id, NO full refetch
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    if (state is! FeatureLoaded) return;
    final current = state as FeatureLoaded;
    try {
      final updated = await _repository.update(id, data);
      emit(current.copyWith(
        items: current.items.map((i) => i.id == id ? updated : i).toList(),
      ));
    } catch (e) {
      emit(FeatureError(e.toString()));
      emit(current); // Roll back
    }
  }

  // Surgical delete — filter out item by id, NO full refetch
  Future<void> deleteItem(String id) async {
    if (state is! FeatureLoaded) return;
    final current = state as FeatureLoaded;
    try {
      await _repository.delete(id);
      emit(current.copyWith(
        items: current.items.where((i) => i.id != id).toList(),
        totalCount: current.totalCount - 1,
      ));
    } catch (e) {
      emit(FeatureError(e.toString()));
      emit(current); // Roll back
    }
  }
}
```

### 7.6 Screen Skeleton
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/feature_repository.dart';
import '../../../data/services/feature_service.dart';
import '../cubit/feature_cubit.dart';
import '../cubit/feature_state.dart';

class FeatureScreen extends StatefulWidget {
  // Pass ProfileModel (user) if role-based logic is needed
  const FeatureScreen({super.key});

  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen>
    with AutomaticKeepAliveClientMixin {
  late FeatureCubit _cubit;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Manual DI — compose dependencies here
    _cubit = FeatureCubit(FeatureRepository(FeatureService()))..loadItems();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('اسم الشاشة', style: AppTextStyles.h2),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
        ),
        body: BlocConsumer<FeatureCubit, FeatureState>(
          listener: (context, state) {
            if (state is FeatureError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.brandAccent,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is FeatureLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              );
            }

            if (state is FeatureLoaded) {
              return RefreshIndicator(
                onRefresh: () => _cubit.loadItems(isRefresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final item = state.items[index];
                    return Text(item.nameAr); // Replace with your card widget
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

---

## 8. Critical Rules — DO NOT VIOLATE

1. **No `context.read<Cubit>()` inside `initState`** — use `late Cubit _cubit` + manual DI.
2. **BlocProvider.value** when navigating to sub-screens that share the parent's Cubit.
3. **Never use `setState`** for data fetching — only Cubit/emit drives state changes.
4. **Every mutation is "surgical"** — modify the in-memory list, never re-fetch the full list.
5. **After `emit(FeatureError(...))` in a mutation**, always immediately `emit(currentState)` to roll back.
6. **Remove 'id' from `updates` map** in Repository before calling Supabase update.
7. **`toJson()` must never include `id` or `created_at`** — these are DB-managed.
8. **Use `.sp` for font sizes, `.w`/`.h` for dimensions** — never hardcode pixel values.
9. **Color palette and text styles are defined centrally** — never create inline `TextStyle` or `Color` in widgets.
10. **All error messages shown to the user must be in Arabic.**

---

## 9. Navigation Pattern

No routing package. Uses plain `Navigator.push` with `MaterialPageRoute`.

```dart
// Navigate to a sub-screen sharing the parent Cubit
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BlocProvider.value(
      value: _cubit,          // share Cubit instance
      child: SubFeatureScreen(item: item),
    ),
  ),
);
```

---

## 10. Assets

- `assets/data/` — JSON files loaded at startup by `StaticDataManager` (cities, property types, etc.)
- `assets/images/` — Static images (logos, illustrations)
- Font family: **Cairo** (declared in `AppTextStyles._baseStyle`)
