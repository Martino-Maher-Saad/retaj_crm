import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../cubit/properties_cubit.dart';

enum PlatformState { waiting, target, suspended }

class PlatformStatusDialog extends StatefulWidget {
  final PropertyModel property;
  final ValueChanged<PropertyModel> onSaved;
  final bool isAdsManagement;
  final bool canChangeState;
  final String? userPrefix;
  final String? currentUserId;

  /// لو true: الماركيتينج مش يقدر يضيف/يحذف منصات، بس يغير الحالة
  final bool isMarketingRole;

  const PlatformStatusDialog({
    Key? key,
    required this.property,
    required this.onSaved,
    this.isAdsManagement = false,
    this.canChangeState = true,
    this.userPrefix,
    this.currentUserId,
    this.isMarketingRole = false,
  }) : super(key: key);

  @override
  State<PlatformStatusDialog> createState() => _PlatformStatusDialogState();
}

class _PlatformStatusDialogState extends State<PlatformStatusDialog> {
  final Map<String, PlatformState> _platformStates = {};
  bool _isSaving = false;
  late TextEditingController _codeController;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    String currentCode = widget.property.propertyCode ?? '';
    if (widget.userPrefix != null &&
        widget.userPrefix!.isNotEmpty &&
        currentCode.startsWith('${widget.userPrefix}-')) {
      currentCode = currentCode.substring(widget.userPrefix!.length + 1);
    }
    _codeController = TextEditingController(text: currentCode);
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _codeError = null);

    String typedCode = _codeController.text.trim();
    if (!(widget.isAdsManagement && widget.isMarketingRole)) {
      if (typedCode.isEmpty) {
        setState(() => _codeError = 'مطلوب');
        return;
      }
    }

    bool isZeroCode = typedCode == '0' || typedCode.endsWith('-0');
    bool isWithoutAds = _platformStates.isEmpty;

    if (!(widget.isAdsManagement && widget.isMarketingRole)) {
      if (isWithoutAds) {
        if (!isZeroCode) {
          setState(() => _codeError = 'طالما العقار بدون إعلان، يجب تعديل كود العقار يدوياً ليكون 0');
          return;
        }
      } else {
        if (isZeroCode) {
          setState(() => _codeError = 'طالما تم اختيار منصات إعلانية، يجب تغيير الكود يدوياً من 0 إلى رقم صحيح');
          return;
        } else if (widget.userPrefix == null || widget.userPrefix!.isEmpty) {
          if (!RegExp(r'^[A-Z]+-[0-9]+$').hasMatch(typedCode)) {
            setState(() {
              _codeError = 'يجب أن يكون الكود بصيغة: حروف ثم شرطة ثم أرقام (مثال: APT-123)';
              _isSaving = false;
            });
            return;
          }
        }
      }
    }

    String finalCode = typedCode;
    if (widget.userPrefix != null && widget.userPrefix!.isNotEmpty) {
      finalCode = '${widget.userPrefix}-$typedCode';
    }

    setState(() => _isSaving = true);
    try {
      if (!isZeroCode && finalCode != widget.property.propertyCode) {
        final isCodeExist = await context.read<PropertiesCubit>().checkPropertyCodeExists(finalCode);
        if (isCodeExist) {
          setState(() {
            _codeError = 'كود العقار مستخدم مسبقاً';
            _isSaving = false;
          });
          return;
        }
      }

      final List<String> waiting = [];
      final List<String> target = [];
      final List<String> suspended = [];

      _platformStates.forEach((platform, state) {
        if (state == PlatformState.waiting) waiting.add(platform);
        else if (state == PlatformState.target) target.add(platform);
        else if (state == PlatformState.suspended) suspended.add(platform);
      });

      // تسجيل published_by و published_at لما تكون في target
      String? publishedBy = widget.property.publishedBy;
      DateTime? publishedAt = widget.property.publishedAt;
      if (target.isNotEmpty && widget.currentUserId != null) {
        publishedBy = widget.currentUserId;
        publishedAt = DateTime.now();
      }

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
      } else {
        newStatusName = 'بدون إعلان';
      }

      if (newStatusName != null) {
        newStatusId = dataManager.getIdByName('property_approval_statuses', newStatusName) ?? newStatusId;
      }

      final updatedModel = widget.property.copyWith(
        propertyCode: finalCode,
        waitingPlatforms: waiting,
        targetPlatforms: target,
        suspendedPlatforms: suspended,
        approvalStatusId: newStatusId,
        approvalStatusName: newStatusName,
        publishedBy: publishedBy,
        publishedAt: publishedAt,
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
                if (!(widget.isAdsManagement && widget.isMarketingRole))
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _codeController,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          if (widget.userPrefix != null &&
                              widget.userPrefix!.isNotEmpty &&
                              widget.property.propertyCode != null &&
                              widget.property.propertyCode!.startsWith('${widget.userPrefix}-'))
                            PrefixTextInputFormatter('${widget.userPrefix}-')
                          else ...[
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                            UpperCaseTextFormatter(),
                          ],
                        ],
                        decoration: InputDecoration(
                          labelText: 'كود العقار *',
                          errorText: _codeError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
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
                        // زر الحذف: مخفي للماركيتينج
                        if (!widget.isMarketingRole)
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
                // إضافة منصة جديدة: مخفية للماركيتينج
                if (availableToAdd.isNotEmpty && !widget.isMarketingRole)
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

class PrefixTextInputFormatter extends TextInputFormatter {
  final String prefix;
  PrefixTextInputFormatter(this.prefix);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.text.startsWith(prefix)) {
      if (newValue.text.isEmpty) {
        return TextEditingValue(
          text: prefix,
          selection: TextSelection.collapsed(offset: prefix.length),
        );
      }
      return oldValue;
    }
    final rest = newValue.text.substring(prefix.length);
    if (rest.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(rest)) {
      return oldValue;
    }
    return newValue;
  }
}
