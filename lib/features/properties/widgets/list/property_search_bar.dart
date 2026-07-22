import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

/// شريط البحث والفلترة السريعة في قائمة العقارات
/// يحتوي على: حقل بحث نصي + اختيار نوع البحث + أيقونة الفلاتر المتقدمة
class PropertySearchBar extends StatefulWidget {
  /// يُستدعى عند الضغط على Enter أو أيقونة البحث
  final void Function(String query, String type) onSearch;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;
  final bool isSearching;
  final bool showToggle;
  final bool searchAll;
  final ValueChanged<bool>? onToggleSearchAll;

  const PropertySearchBar({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
    required this.onClear,
    required this.isSearching,
    this.showToggle = false,
    this.searchAll = false,
    this.onToggleSearchAll,
  });

  @override
  State<PropertySearchBar> createState() => _PropertySearchBarState();
}

class _PropertySearchBarState extends State<PropertySearchBar> {
  final Map<String, TextEditingController> _controllers = {
    'general': TextEditingController(),
    'code': TextEditingController(),
    'phone': TextEditingController(),
  };

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        children: [
          // الصف الأول: بحث بالكود وبحث برقم المالك
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildSearchField(
                  hint: "بحث بكود العقار...",
                  type: 'code',
                  icon: Icons.numbers,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 1,
                child: _buildSearchField(
                  hint: "بحث برقم المالك...",
                  type: 'phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // الصف الثاني: البحث الذكي والفلاتر
          Row(
            children: [
              Expanded(
                child: _buildSearchField(
                  hint: "بحث عام / بالذكاء الاصطناعي...",
                  type: 'general',
                  icon: Icons.auto_awesome,
                ),
              ),
              SizedBox(width: 10.w),
              // ─── زر الفلاتر المتقدمة ───
              GestureDetector(
                onTap: widget.onFilterTap,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.brandPrimary),
                ),
              ),
              if (widget.showToggle) ...[
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: widget.searchAll
                        ? AppColors.brandPrimary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: widget.searchAll
                          ? AppColors.brandPrimary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "الكل",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.searchAll
                              ? AppColors.brandPrimary
                              : Colors.grey,
                        ),
                      ),
                      Switch(
                        value: widget.searchAll,
                        onChanged: widget.onToggleSearchAll,
                        activeColor: AppColors.brandPrimary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required String hint,
    required String type,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // استخدم controllers مختلفة لكل نوع للسهولة،
    // ولكن لتجنب تكرار الكود حالياً سنعتمد على controller واحد ويتم تفريغه،
    // أو نضع controller خاص بكل حقل. سنستخدم map.
    return TextField(
      controller: _controllers[type],
      keyboardType: keyboardType,
      textInputAction: TextInputAction.search,
      onSubmitted: (val) {
        if (val.isNotEmpty) {
          widget.onSearch(val, type);
        } else {
          widget.onClear();
        }
      },
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        hintStyle: TextStyle(fontSize: 13.sp),
        prefixIcon: Icon(icon, color: AppColors.brandPrimary, size: 20.sp),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controllers[type]!,
              builder: (context, value, child) {
                if (value.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      for (var c in _controllers.values) {
                        c.clear();
                      }
                      widget.onClear();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: Icon(icon, color: AppColors.brandPrimary),
              onPressed: () {
                if (_controllers[type]!.text.isNotEmpty) {
                  widget.onSearch(_controllers[type]!.text, type);
                } else {
                  widget.onClear();
                }
              },
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
