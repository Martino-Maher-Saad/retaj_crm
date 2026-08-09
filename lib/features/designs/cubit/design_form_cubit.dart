import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/design_model.dart';
import '../../../data/repositories/design_repository.dart';

abstract class DesignFormState {}

class DesignFormInitial extends DesignFormState {}
class DesignFormLoading extends DesignFormState {}
class DesignFormSuccess extends DesignFormState {
  final DesignModel design;
  DesignFormSuccess(this.design);
}
class DesignFormError extends DesignFormState {
  final String message;
  DesignFormError(this.message);
}

class DesignFormCubit extends Cubit<DesignFormState> {
  final DesignRepository _repo;

  DesignFormCubit(this._repo) : super(DesignFormInitial());

  Future<void> submitDesign({
    DesignModel? existingDesign,
    required String descAr,
    required String roomTypeId,
    required String styleId,
    required List<DesignLinkModel> links,
    required List<Uint8List> newImages,
    List<String>? deletedImageIds,
  }) async {
    try {
      emit(DesignFormLoading());

      if (existingDesign == null) {
        if (newImages.isEmpty) {
          emit(DesignFormError('يجب اختيار صورة واحدة على الأقل'));
          return;
        }

        final model = DesignModel(
          id: '', // سيتم تعيينه من قاعدة البيانات
          descAr: descAr,
          roomTypeId: roomTypeId,
          styleId: styleId,
          links: links,
          createdAt: DateTime.now(),
          addedBy: '',
        );

        final newDesign = await _repo.createFullDesign(model, newImages);
        emit(DesignFormSuccess(newDesign));

      } else {
        final model = DesignModel(
          id: existingDesign.id,
          descAr: descAr,
          roomTypeId: roomTypeId,
          styleId: styleId,
          links: links,
          createdAt: existingDesign.createdAt,
          addedBy: existingDesign.addedBy,
          images: existingDesign.images, // الصور القديمة ستتحدث بعد الرد
        );

        final updatedDesign = await _repo.updateFullDesign(
          model,
          newImages: newImages,
          deletedImageIds: deletedImageIds,
        );
        emit(DesignFormSuccess(updatedDesign));
      }
    } catch (e) {
      emit(DesignFormError('حدث خطأ أثناء الحفظ: $e'));
    }
  }
}
