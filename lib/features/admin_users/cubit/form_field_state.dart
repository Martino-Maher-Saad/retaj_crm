import 'package:equatable/equatable.dart';
import '../../../data/models/form_field_model.dart';

abstract class FormFieldState extends Equatable {
  const FormFieldState();

  @override
  List<Object?> get props => [];
}

class FormFieldInitial extends FormFieldState {}

class FormFieldLoading extends FormFieldState {}

class FormFieldLoaded extends FormFieldState {
  final List<FormFieldModel> fields;
  final String entityType;

  const FormFieldLoaded({required this.fields, required this.entityType});

  @override
  List<Object?> get props => [fields, entityType];
}

class FormFieldActionLoading extends FormFieldState {}

class FormFieldActionSuccess extends FormFieldState {
  final String message;

  const FormFieldActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FormFieldError extends FormFieldState {
  final String message;

  const FormFieldError(this.message);

  @override
  List<Object?> get props => [message];
}
