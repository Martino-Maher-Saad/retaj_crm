import 'profile_model.dart';
import 'property_model.dart';

class PropertyShareModel {
  final String id;
  final String propertyId;
  final String senderId;
  final String receiverId;
  final String? notes;
  final DateTime createdAt;
  final bool senderDeleted;
  final bool receiverDeleted;

  final PropertyModel? property;
  final ProfileModel? sender;
  final ProfileModel? receiver;

  PropertyShareModel({
    required this.id,
    required this.propertyId,
    required this.senderId,
    required this.receiverId,
    this.notes,
    required this.createdAt,
    this.senderDeleted = false,
    this.receiverDeleted = false,
    this.property,
    this.sender,
    this.receiver,
  });

  factory PropertyShareModel.fromJson(Map<String, dynamic> json) {
    return PropertyShareModel(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      senderDeleted: json['sender_deleted'] == true,
      receiverDeleted: json['receiver_deleted'] == true,
      property: json['properties'] != null ? PropertyModel.fromJson(json['properties']) : null,
      sender: json['sender'] != null ? ProfileModel.fromJson(json['sender']) : null,
      receiver: json['receiver'] != null ? ProfileModel.fromJson(json['receiver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'sender_deleted': senderDeleted,
      'receiver_deleted': receiverDeleted,
    };
  }
}
