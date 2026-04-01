import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/services/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _profileService;
  
  ProfileCubit(this._profileService) : super(ProfileInitial());

  // تعيين البروفايل المحلي (عند تسجيل الدخول أو التنقل)
  void setProfile(ProfileModel profile) {
    emit(ProfileLoaded(profile));
  }

  // تحديث البيانات النصية
  Future<void> updateProfileData(String userId, Map<String, dynamic> updates) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileLoading());
      try {
        final updatedProfile = await _profileService.updateProfile(userId, updates);
        emit(ProfileLoaded(updatedProfile));
      } catch (e) {
        emit(ProfileError(e.toString()));
        emit(currentState); // Return to previous state after showing error
      }
    }
  }

  // رفع الصورة ثم تحديث البروفايل (دعم الويب)
  Future<void> updateProfileImageBytes(String userId, Uint8List imageBytes, String fileExt) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileLoading());
      try {
        final imageUrl = await _profileService.uploadProfileImageBytes(userId, imageBytes, fileExt);
        final updatedProfile = await _profileService.updateProfile(userId, {'image_url': imageUrl});
        emit(ProfileLoaded(updatedProfile));
      } catch (e, s) {
        print('=== ERROR IN CUBIT (IMAGE UPLOAD) ===');
        print(e.toString());
        print(s.toString());
        emit(ProfileError(e.toString()));
        emit(currentState);
      }
    }
  }

  // حذف الصورة الشخصية
  Future<void> removeProfileImage(String userId) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(ProfileLoading());
      try {
        final updatedProfile = await _profileService.updateProfile(userId, {'image_url': null});
        emit(ProfileLoaded(updatedProfile));
      } catch (e, s) {
        print('=== ERROR IN CUBIT (IMAGE REMOVE) ===');
        print(e.toString());
        print(s.toString());
        emit(ProfileError(e.toString()));
        emit(currentState);
      }
    }
  }
}
