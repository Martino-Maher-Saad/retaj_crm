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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                // 1. بحث عام (الذكاء الاصطناعي)
                _buildSearchField(
                  hint: "بحث عام / بالذكاء الاصطناعي...",
                  type: 'general',
                  icon: Icons.auto_awesome,
                ),
                SizedBox(height: 10.h),
                // 2. بحث بكود العقار
                _buildSearchField(
                  hint: "بحث بكود العقار...",
                  type: 'code',
                  icon: Icons.numbers,
                ),
                SizedBox(height: 10.h),
                // 3. بحث برقم المالك
                _buildSearchField(
                  hint: "بحث برقم المالك...",
                  type: 'phone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // ─── زر الفلاتر المتقدمة ───
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onFilterTap,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: const Icon(Icons.tune, color: AppColors.brandPrimary),
                ),
              ),
              if (widget.showToggle) ...[
                SizedBox(height: 15.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: widget.searchAll ? AppColors.brandPrimary.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: widget.searchAll ? AppColors.brandPrimary : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "الكل",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.searchAll ? AppColors.brandPrimary : Colors.grey,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }
}
