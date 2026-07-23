import 'package:equatable/equatable.dart';

class EditableLeadRow extends Equatable {
  final String id; // Unique ID for the row in UI
  final String? name;
  final String? phone;
  final String? budgetFrom;
  final String? budgetTo;
  final String? notes;
  final String? propertyCode;
  final String? descLeadNeed;
  final DateTime? createdAt;
  
  // Dropdown IDs
  final int? cityId;
  final String? propertyTypeId;
  final String? listingTypeId;
  final String? platformId;
  final String? channelId;
  final String? statusId;
  final String? assignedTo;
  
  // Excel unmapped text (if typo)
  final String? unmappedCity;
  final String? unmappedPropertyType;
  final String? unmappedListingType;
  final String? unmappedPlatform;
  final String? unmappedChannel;
  final String? unmappedStatus;
  final String? unmappedAssignedTo;

  const EditableLeadRow({
    required this.id,
    this.name,
    this.phone,
    this.budgetFrom,
    this.budgetTo,
    this.notes,
    this.propertyCode,
    this.descLeadNeed,
    this.createdAt,
    this.cityId,
    this.propertyTypeId,
    this.listingTypeId,
    this.platformId,
    this.channelId,
    this.statusId,
    this.assignedTo,
    this.unmappedCity,
    this.unmappedPropertyType,
    this.unmappedListingType,
    this.unmappedPlatform,
    this.unmappedChannel,
    this.unmappedStatus,
    this.unmappedAssignedTo,
  });

  bool get isEmpty {
    return (name == null || name!.trim().isEmpty) &&
           (phone == null || phone!.trim().isEmpty) &&
           (propertyCode == null || propertyCode!.trim().isEmpty) &&
           (notes == null || notes!.trim().isEmpty) &&
           (descLeadNeed == null || descLeadNeed!.trim().isEmpty) &&
           (budgetFrom == null || budgetFrom!.trim().isEmpty) &&
           (budgetTo == null || budgetTo!.trim().isEmpty);
  }

  bool get isValid {
    final hasValidPhone = phone != null && phone!.trim().isNotEmpty && !phone!.contains(',') && !phone!.contains(' ');
    final hasRequiredDropdowns = cityId != null && 
                                 propertyTypeId != null && 
                                 listingTypeId != null && 
                                 platformId != null && 
                                 assignedTo != null;
    return hasValidPhone && hasRequiredDropdowns;
  }

  List<String> get errors {
    List<String> errs = [];
    if (phone == null || phone!.trim().isEmpty) {
      errs.add('رقم الهاتف مطلوب');
    } else if (phone!.contains(',') || phone!.contains('-') || phone!.contains(' ')) {
      errs.add('رقم هاتف واحد فقط بدون مسافات');
    }
    
    if (cityId == null) errs.add('المدينة مطلوبة');
    if (propertyTypeId == null) errs.add('نوع العقار مطلوب');
    if (listingTypeId == null) errs.add('نوع الإعلان مطلوب');
    if (platformId == null) errs.add('المنصة مطلوبة');
    if (assignedTo == null) errs.add('الموظف المسند مطلوب');
    return errs;
  }

  EditableLeadRow copyWith({
    String? name,
    String? phone,
    String? budgetFrom,
    String? budgetTo,
    String? notes,
    String? propertyCode,
    String? descLeadNeed,
    DateTime? createdAt,
    int? cityId,
    String? propertyTypeId,
    String? listingTypeId,
    String? platformId,
    String? channelId,
    String? statusId,
    String? assignedTo,
    String? unmappedCity,
    String? unmappedPropertyType,
    String? unmappedListingType,
    String? unmappedPlatform,
    String? unmappedChannel,
    String? unmappedStatus,
    String? unmappedAssignedTo,
  }) {
    return EditableLeadRow(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      budgetFrom: budgetFrom ?? this.budgetFrom,
      budgetTo: budgetTo ?? this.budgetTo,
      notes: notes ?? this.notes,
      propertyCode: propertyCode ?? this.propertyCode,
      descLeadNeed: descLeadNeed ?? this.descLeadNeed,
      createdAt: createdAt ?? this.createdAt,
      cityId: cityId != null ? (cityId == -1 ? null : cityId) : this.cityId,
      propertyTypeId: propertyTypeId != null ? (propertyTypeId.isEmpty ? null : propertyTypeId) : this.propertyTypeId,
      listingTypeId: listingTypeId != null ? (listingTypeId.isEmpty ? null : listingTypeId) : this.listingTypeId,
      platformId: platformId != null ? (platformId.isEmpty ? null : platformId) : this.platformId,
      channelId: channelId != null ? (channelId.isEmpty ? null : channelId) : this.channelId,
      statusId: statusId != null ? (statusId.isEmpty ? null : statusId) : this.statusId,
      assignedTo: assignedTo != null ? (assignedTo.isEmpty ? null : assignedTo) : this.assignedTo,
      unmappedCity: unmappedCity ?? this.unmappedCity,
      unmappedPropertyType: unmappedPropertyType ?? this.unmappedPropertyType,
      unmappedListingType: unmappedListingType ?? this.unmappedListingType,
      unmappedPlatform: unmappedPlatform ?? this.unmappedPlatform,
      unmappedChannel: unmappedChannel ?? this.unmappedChannel,
      unmappedStatus: unmappedStatus ?? this.unmappedStatus,
      unmappedAssignedTo: unmappedAssignedTo ?? this.unmappedAssignedTo,
    );
  }

  @override
  List<Object?> get props => [
        id, name, phone, budgetFrom, budgetTo, notes, propertyCode, descLeadNeed, createdAt,
        cityId, propertyTypeId, listingTypeId, platformId, channelId, statusId, assignedTo,
        unmappedCity, unmappedPropertyType, unmappedListingType, unmappedPlatform, unmappedChannel, unmappedStatus, unmappedAssignedTo
      ];
}

abstract class BulkAddLeadsState extends Equatable {
  const BulkAddLeadsState();

  @override
  List<Object?> get props => [];
}

class BulkAddLeadsInitial extends BulkAddLeadsState {}

class BulkAddLeadsLoading extends BulkAddLeadsState {
  final String message;
  const BulkAddLeadsLoading(this.message);
  @override
  List<Object?> get props => [message];
}

class BulkAddLeadsLoaded extends BulkAddLeadsState {
  final List<EditableLeadRow> rows;
  final List<String> columnOrder;
  final Map<String, dynamic> pinnedValues;

  const BulkAddLeadsLoaded(
    this.rows, {
    this.columnOrder = const [
      'name', 'phone', 'cityId', 'propertyTypeId', 'listingTypeId', 'platformId',
      'channelId', 'statusId', 'assignedTo', 'propertyCode', 'createdAt',
      'descLeadNeed', 'budgetFrom', 'budgetTo', 'notes'
    ],
    this.pinnedValues = const {},
  });

  BulkAddLeadsLoaded copyWith({
    List<EditableLeadRow>? rows,
    List<String>? columnOrder,
    Map<String, dynamic>? pinnedValues,
  }) {
    return BulkAddLeadsLoaded(
      rows ?? this.rows,
      columnOrder: columnOrder ?? this.columnOrder,
      pinnedValues: pinnedValues ?? this.pinnedValues,
    );
  }

  @override
  List<Object?> get props => [rows, columnOrder, pinnedValues];
}

class BulkAddLeadsProgress extends BulkAddLeadsState {
  final int processed;
  final int total;
  const BulkAddLeadsProgress(this.processed, this.total);
  @override
  List<Object?> get props => [processed, total];
}

class BulkAddLeadsSuccess extends BulkAddLeadsState {}

class BulkAddLeadsError extends BulkAddLeadsState {
  final String error;
  const BulkAddLeadsError(this.error);
  @override
  List<Object?> get props => [error];
}
