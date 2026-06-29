import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class LeadSearchBar extends StatefulWidget {
  final void Function(String query, String type) onSearch;
  final VoidCallback onClear;
  final bool isSearching;

  const LeadSearchBar({
    super.key, 
    required this.onSearch,
    required this.onClear,
    required this.isSearching,
  });

  @override
  State<LeadSearchBar> createState() => _LeadSearchBarState();
}

class _LeadSearchBarState extends State<LeadSearchBar> {
  final Map<String, TextEditingController> _controllers = {
    'general': TextEditingController(),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        children: [
          // البحث الذكي في متطلبات العملاء (دلالي)
          _buildSearchField(
            hint: "البحث الذكي في متطلبات العملاء (سيمانتك)...",
            type: 'general',
            icon: Icons.auto_awesome,
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 10.h),
          // بحث برقم العميل
          _buildSearchField(
            hint: "بحث برقم هاتف العميل...",
            type: 'phone',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
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
