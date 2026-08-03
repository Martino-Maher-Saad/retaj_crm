import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/property_model.dart';

enum PlatformState { waiting, target, suspended }

class PlatformStatusDialog extends StatefulWidget {
  final PropertyModel property;
  final ValueChanged<PropertyModel> onSaved;
  final bool isAdsManagement;
  final bool canChangeState;

  const PlatformStatusDialog({
    Key? key,
    required this.property,
    required this.onSaved,
    this.isAdsManagement = false,
    this.canChangeState = true,
  }) : super(key: key);

  @override
  State<PlatformStatusDialog> createState() => _PlatformStatusDialogState();
}

class _PlatformStatusDialogState extends State<PlatformStatusDialog> {
  final Map<String, PlatformState> _platformStates = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final p in widget.property.waitingPlatforms) {
      _platformStates[p] = PlatformState.waiting;
    }
    for (final p in widget.property.targetPlatforms) {
      _platformStates[p] = PlatformState.target;
    }
    for (final p in widget.property.suspendedPlatforms) {
      _platformStates[p] = PlatformState.suspended;
    }
  }

  void _save() async {
    setState(() => _isSaving = true);
    try {
      final List<String> waiting = [];
      final List<String> target = [];
      final List<String> suspended = [];

      _platformStates.forEach((platform, state) {
        if (state == PlatformState.waiting) waiting.add(platform);
        else if (state == PlatformState.target) target.add(platform);
        else if (state == PlatformState.suspended) suspended.add(platform);
      });

      final dataManager = di.sl<StaticDataManager>();
      String? newStatusName = widget.property.approvalStatusName;
      String? newStatusId = widget.property.approvalStatusId;

      if (_platformStates.isNotEmpty) {
        if (waiting.isNotEmpty) {
          newStatusName = 'قيد المراجعة';
        } else if (target.length == _platformStates.length) {
          newStatusName = 'تم النشر';
        } else if (suspended.length == _platformStates.length) {
          newStatusName = 'مسودة'; 
        } else {
          newStatusName = 'تم النشر'; 
        }
      }

      if (newStatusName != null) {
        newStatusId = dataManager.getIdByName('property_approval_statuses', newStatusName) ?? newStatusId;
      }

      final updatedModel = widget.property.copyWith(
        waitingPlatforms: waiting,
        targetPlatforms: target,
        suspendedPlatforms: suspended,
        approvalStatusId: newStatusId,
        approvalStatusName: newStatusName,
      );

      widget.onSaved(updatedModel);
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = di.sl<StaticDataManager>();
    final allPlatforms = dataManager.getActiveOptions('advertising_platform');
    final availableToAdd = allPlatforms.where((p) => !_platformStates.containsKey(p)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('إدارة حالة المنصات', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
        contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        content: SizedBox(
          width: 600.w,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                ..._platformStates.entries.map((entry) {
                final platform = entry.key;
                final state = entry.value;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          platform,
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildOptionBtn(platform, PlatformState.waiting, state, Colors.amber, 'قيد الانتظار'),
                            _buildOptionBtn(platform, PlatformState.target, state, Colors.green, 'تم النشر'),
                            _buildOptionBtn(platform, PlatformState.suspended, state, Colors.red, 'مسودة'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _platformStates.remove(platform));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (availableToAdd.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'إضافة منصة جديدة',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('اختر منصة لإضافتها')),
                            ...availableToAdd.map((p) => DropdownMenuItem<String?>(value: p, child: Text(p))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _platformStates[val] = PlatformState.waiting);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ),
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600, fontSize: 20.sp)),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            ),
            child: _isSaving
                ? SizedBox(width: 24.w, height: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBtn(String platform, PlatformState targetState, PlatformState currentState, Color activeColor, String label) {
    final isSelected = targetState == currentState;
    return MouseRegion(
      cursor: widget.canChangeState ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.canChangeState
            ? () {
                setState(() {
                  _platformStates[platform] = targetState;
                });
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isSelected ? activeColor.withValues(alpha: 0.8) : Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
