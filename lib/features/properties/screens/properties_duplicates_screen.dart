import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/property_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/list/properties_table_view.dart';
import 'property_details_screen.dart';

class PropertiesDuplicatesScreen extends StatefulWidget {
  final String userId;
  final String role;

  const PropertiesDuplicatesScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<PropertiesDuplicatesScreen> createState() => _PropertiesDuplicatesScreenState();
}

class _PropertiesDuplicatesScreenState extends State<PropertiesDuplicatesScreen> {
  late PropertiesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<PropertiesCubit>();
    _fetchDuplicates();
  }

  Future<void> _fetchDuplicates() async {
    // For duplicates, we need to fetch a large chunk of properties to find duplicates locally
    // In a real production app, this should be a dedicated RPC call.
    await _cubit.applyAdvancedFilters(
      role: widget.role,
      currentUserId: widget.userId,
      searchAll: true,
    );
  }

  List<PropertyModel> _extractDuplicates(List<PropertyModel> allProperties) {
    final Map<String, List<PropertyModel>> phoneGroups = {};
    for (var prop in allProperties) {
      final phone = prop.ownerPhone;
      if (phone != null && phone.trim().isNotEmpty) {
        // Group by last 6 digits for safety against formats
        final suffix = phone.length >= 6 ? phone.substring(phone.length - 6) : phone;
        phoneGroups.putIfAbsent(suffix, () => []).add(prop);
      }
    }
    return phoneGroups.values
        .where((group) => group.length > 1)
        .expand((group) => group)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppRole.fromString(widget.role).isAtLeast(AppRole.manager)) {
      return const Scaffold(
        body: Center(child: Text("غير مصرح لك بالدخول لهذه الصفحة")),
      );
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('تكرارات العقارات', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, state) {
            if (state is PropertiesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PropertiesSuccess) {
              final duplicateProperties = _extractDuplicates(state.filteredProperties);

              if (duplicateProperties.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64.sp, color: Colors.green),
                      SizedBox(height: 16.h),
                      Text("لا توجد عقارات مكررة", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                        SizedBox(width: 8.w),
                        Text(
                          "تم العثور على ${duplicateProperties.length} عقار مكرر (بنفس رقم المالك)",
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PropertiesTableView(
                      properties: duplicateProperties,
                      role: widget.role,
                      isLoadingMore: false,
                      onTap: (property) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailsScreen(
                              property: property,
                              currentUserId: widget.userId,
                              role: widget.role,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text("حدث خطأ"));
          },
        ),
      ),
    );
  }
}
