import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// شريط البحث والفلترة السريعة في قائمة العقارات
/// يحتوي على: حقل بحث نصي + أيقونة الفلاتر المتقدمة
class PropertySearchBar extends StatefulWidget {
  /// يُستدعى عند الضغط على Enter أو أيقونة البحث
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;
  final bool isSearching;

  const PropertySearchBar({
    super.key, 
    required this.onSearch,
    required this.onFilterTap,
    required this.onClear,
    required this.isSearching,
  });

  @override
  State<PropertySearchBar> createState() => _PropertySearchBarState();
}

class _PropertySearchBarState extends State<PropertySearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        children: [
          // ─── حقل البحث النصي الرئيسي ───
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: widget.onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "بحث سريع...",
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isSearching)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _controller.clear();
                          widget.onClear();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search, color: AppColors.brandPrimary),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          widget.onSearch(_controller.text);
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
              ),
              child: const Icon(Icons.tune, color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
