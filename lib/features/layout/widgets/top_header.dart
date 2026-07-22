import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/models/profile_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/layout_cubit.dart';
import '../cubit/layout_state.dart';
import 'user_avatar.dart';

class TopHeader extends StatelessWidget {
  final ProfileModel user;
  final List<String> navTitles;
  final VoidCallback? onAddLead;
  final VoidCallback? onAddProperty;
  final VoidCallback? onAddTask;

  const TopHeader({
    super.key,
    required this.user,
    required this.navTitles,
    this.onAddLead,
    this.onAddProperty,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              // ─── عنوان الصفحة الحالية ───
              BlocBuilder<LayoutCubit, LayoutState>(
                builder: (context, state) {
                  int idx = 0;
                  if (state is LayoutNavigationChanged) {
                    idx = state.selectedIndex;
                  }
                  return Text(
                    idx < navTitles.length ? navTitles[idx] : '',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.brandPrimaryDark,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),

              const Spacer(),

              // ─── زر + جديد (Quick Add) ───
              _QuickAddButton(
                onAddLead: onAddLead,
                onAddProperty: onAddProperty,
                onAddTask: onAddTask,
              ),

              SizedBox(width: 16.w),

              // ─── اسم المستخدم + أفاتار ───
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        user.fullName,
                        style: AppTextStyles.tableCellMain.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.roleNameAr,
                        style: AppTextStyles.tableCellSub.copyWith(
                          color: AppColors.brandPrimary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  UserAvatar(user: user),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── زر الإضافة السريعة ───
class _QuickAddButton extends StatefulWidget {
  final VoidCallback? onAddLead;
  final VoidCallback? onAddProperty;
  final VoidCallback? onAddTask;

  const _QuickAddButton({
    this.onAddLead,
    this.onAddProperty,
    this.onAddTask,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // طبقة شفافة لإغلاق القائمة عند الضغط خارجها
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          // القائمة نفسها
          CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(-80.w, 8.h),
            child: Material(
              color: Colors.transparent,
              child: _DropdownMenu(
                onAddLead: widget.onAddLead != null
                    ? () {
                        _close();
                        widget.onAddLead!();
                      }
                    : null,
                onAddProperty: widget.onAddProperty != null
                    ? () {
                        _close();
                        widget.onAddProperty!();
                      }
                    : null,
                onAddTask: widget.onAddTask != null
                    ? () {
                        _close();
                        widget.onAddTask!();
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'إضافة سريعة',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _isOpen
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOpen ? Icons.close_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── القائمة المنسدلة ───
class _DropdownMenu extends StatelessWidget {
  final VoidCallback? onAddLead;
  final VoidCallback? onAddProperty;
  final VoidCallback? onAddTask;

  const _DropdownMenu({
    this.onAddLead,
    this.onAddProperty,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.person_add_alt_1_rounded,
            label: 'إضافة عميل',
            color: AppColors.brandPrimary,
            onTap: onAddLead,
          ),
          Divider(height: 1, color: AppColors.borderSubtle),
          _MenuItem(
            icon: Icons.home_work_rounded,
            label: 'إضافة عقار',
            color: const Color(0xFF059669),
            onTap: onAddProperty,
          ),
          Divider(height: 1, color: AppColors.borderSubtle),
          _MenuItem(
            icon: Icons.task_alt_rounded,
            label: 'إضافة مهمة',
            color: const Color(0xFFD97706),
            onTap: onAddTask,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _hover
                ? widget.color.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(widget.icon, color: widget.color, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}