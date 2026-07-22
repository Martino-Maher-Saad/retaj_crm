import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/repositories/lead_repository.dart';
import '../../../core/widgets/custom_button.dart';

class DuplicatesScreen extends StatefulWidget {
  final ProfileModel user;

  const DuplicatesScreen({super.key, required this.user});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  final _leadRepository = di.sl<LeadRepository>();
  
  bool _isLoading = true;
  List<List<LeadModel>> _duplicateGroups = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
  }

  Future<void> _loadDuplicates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final duplicates = await _leadRepository.findDuplicateLeads(
        role: widget.user.role,
        userId: widget.user.id,
      );
      setState(() {
        _duplicateGroups = duplicates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showMergeDialog(List<LeadModel> group) {
    showDialog(
      context: context,
      builder: (ctx) => _MergeDialog(
        group: group,
        onMergeComplete: () {
          _loadDuplicates();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text('سجل التكرارات والدمج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.brandPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDuplicates,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('حدث خطأ', style: TextStyle(color: Colors.red, fontSize: 18.sp)),
            SizedBox(height: 8.h),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _loadDuplicates, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_duplicateGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80.sp, color: Colors.green),
            SizedBox(height: 16.h),
            Text('لا توجد تكرارات في قاعدة البيانات!', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _duplicateGroups.length,
      itemBuilder: (context, index) {
        final group = _duplicateGroups[index];
        final phone = group.first.phones.isNotEmpty ? group.first.phones.first.phoneNumber : 'بدون رقم';
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('رقم الهاتف: $phone', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                    CustomButton(
                      title: 'دمج (${group.length})',
                      onTap: () => _showMergeDialog(group),
                      buttonWidth: 120.w,
                      buttonHeight: 40.h,
                      isCenter: true,
                    ),
                  ],
                ),
                Divider(),
                ...group.map((lead) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16.sp, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(lead.clientName, style: TextStyle(fontSize: 14.sp))),
                      Text(DateFormat('yyyy/MM/dd').format(lead.createdAt ?? DateTime.now()), style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MergeDialog extends StatefulWidget {
  final List<LeadModel> group;
  final VoidCallback onMergeComplete;

  const _MergeDialog({required this.group, required this.onMergeComplete});

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  late LeadModel _primaryLead;
  bool _isMerging = false;
  List<ProfileModel> _employees = [];
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    // Default to the oldest created lead as primary
    widget.group.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
    _primaryLead = widget.group.first;
    _selectedEmployeeId = _primaryLead.assignedTo;
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await di.sl<LeadRepository>().getAllEmployees();
      if (mounted) setState(() => _employees = emps);
    } catch (_) {}
  }

  Future<void> _merge() async {
    setState(() => _isMerging = true);
    try {
      final repository = di.sl<LeadRepository>();
      final secondaryIds = widget.group.where((l) => l.id != _primaryLead.id).map((l) => l.id ?? '').toList();
      
      await repository.mergeLeads(_primaryLead.id ?? '', secondaryIds, assignedToId: _selectedEmployeeId);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم دمج العملاء بنجاح ونقل الملاحظات والمهام')));
        widget.onMergeComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isMerging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تأكيد عملية الدمج', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر العميل الأساسي الذي سيتم الاحتفاظ ببياناته (اسمه، حالته، مسؤوله).', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Text('العملاء الآخرين سيتم حذفهم مع نقل مهامهم وملاحظاتهم إلى العميل الأساسي.', style: TextStyle(fontSize: 14.sp, color: Colors.red)),
            SizedBox(height: 16.h),
            ...widget.group.map((lead) {
              return RadioListTile<LeadModel>(
                title: Text(lead.clientName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('أُضيف بواسطة: ${lead.createdByName}\nتاريخ الإضافة: ${DateFormat('yyyy/MM/dd').format(lead.createdAt ?? DateTime.now())}'),
                value: lead,
                groupValue: _primaryLead,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _primaryLead = v;
                      _selectedEmployeeId = v.assignedTo;
                    });
                  }
                },
                activeColor: AppColors.brandPrimary,
              );
            }).toList(),
            SizedBox(height: 16.h),
            Text('الموظف المسؤول للعميل المدمج:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            if (_employees.isEmpty)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _selectedEmployeeId,
                items: _employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isMerging ? null : () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isMerging ? null : _merge,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
          child: _isMerging 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('دمج نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
