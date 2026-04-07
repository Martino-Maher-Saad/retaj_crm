// Removed dart:io as it is unsupported on Web

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neon_text_field.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class UserProfileScreen extends StatefulWidget {
  final ProfileModel currentUser;

  const UserProfileScreen({super.key, required this.currentUser});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.currentUser.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.currentUser.lastName,
    );
    _phoneController = TextEditingController(text: widget.currentUser.phone);
    context.read<ProfileCubit>().setProfile(widget.currentUser);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last;
      if (!mounted) return;
      context.read<ProfileCubit>().updateProfileImageBytes(
        widget.currentUser.id,
        bytes,
        ext,
      );
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateProfileData(widget.currentUser.id, {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text('الملف الشخصي', style: AppTextStyles.h2),
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.brandAccent,
              ),
            );
          } else if (state is ProfileLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("تم التحديث بنجاح!"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final profile =
              state is ProfileLoaded ? state.profile : widget.currentUser;
          final isLoading = state is ProfileLoading;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.p24),
              child: Column(
                children: [
                  // ─── الصورة الشخصية ───
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55.r,
                          backgroundColor: AppColors.borderSubtle,
                          backgroundImage:
                              profile.imageUrl != null &&
                                  profile.imageUrl!.isNotEmpty
                              ? NetworkImage(profile.imageUrl!)
                              : null,
                          child: (profile.imageUrl == null ||
                                  profile.imageUrl!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 55.r,
                                  color: AppColors.textDisabled,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: isLoading ? null : _pickAndUploadImage,
                            borderRadius: BorderRadius.circular(20.r),
                            child: CircleAvatar(
                              radius: 18.r,
                              backgroundColor: AppColors.brandPrimary,
                              child: isLoading
                                  ? SizedBox(
                                      width: 14.w,
                                      height: 14.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      size: 18.r,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                        if (profile.imageUrl != null &&
                            profile.imageUrl!.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: InkWell(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      context
                                          .read<ProfileCubit>()
                                          .removeProfileImage(
                                              widget.currentUser.id);
                                    },
                              borderRadius: BorderRadius.circular(20.r),
                              child: CircleAvatar(
                                radius: 18.r,
                                backgroundColor: AppColors.brandAccent,
                                child: Icon(Icons.delete_outline,
                                    size: 18.r, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppConstants.p32),

                  // ─── حقول غير قابلة للتعديل ───
                  NeonTextField(
                    initialValue: profile.email,
                    readOnly: true,
                    label: 'البريد الإلكتروني',
                    prefixIcon: Icons.email_outlined,
                  ),
                  SizedBox(height: AppConstants.p16),

                  NeonTextField(
                    initialValue: profile.role,
                    readOnly: true,
                    label: 'الصلاحية (الرتبة)',
                    prefixIcon: Icons.security_outlined,
                  ),
                  SizedBox(height: AppConstants.p16),

                  // ─── حقول قابلة للتعديل ───
                  NeonTextField(
                    controller: _firstNameController,
                    label: 'الاسم الأول',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  SizedBox(height: AppConstants.p16),

                  NeonTextField(
                    controller: _lastNameController,
                    label: 'الاسم الأخير',
                    prefixIcon: Icons.person_pin_outlined,
                    validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  SizedBox(height: AppConstants.p16),

                  NeonTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: AppConstants.p32),

                  // ─── زر الحفظ ───
                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.r8),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'حفظ التعديلات',
                              style: AppTextStyles.buttonLarge,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
