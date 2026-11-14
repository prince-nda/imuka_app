import 'package:equatable/equatable.dart';

/// How the user prefers the owner to get back to them.
enum ContactChannel {
  call('Call'),
  whatsapp('WhatsApp'),
  inAppChat('In-app chat');

  const ContactChannel(this.label);
  final String label;
}

enum ViewingStatus { requested, confirmed, cancelled }

/// A request to visit a listing at a given time.
class ViewingRequest extends Equatable {
  const ViewingRequest({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.landlordId,
    required this.ownerName,
    required this.ownerReplyMinutes,
    required this.scheduledAt,
    required this.channel,
    required this.message,
    this.status = ViewingStatus.requested,
  });

  final String id;
  final String propertyId;
  final String propertyTitle;
  final String landlordId;
  final String ownerName;
  final int ownerReplyMinutes;
  final DateTime scheduledAt;
  final ContactChannel channel;
  final String message;
  final ViewingStatus status;

  ViewingRequest copyWith({String? id, ViewingStatus? status}) =>
      ViewingRequest(
        id: id ?? this.id,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        landlordId: landlordId,
        ownerName: ownerName,
        ownerReplyMinutes: ownerReplyMinutes,
        scheduledAt: scheduledAt,
        channel: channel,
        message: message,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [
    id,
    propertyId,
    propertyTitle,
    landlordId,
    ownerName,
    ownerReplyMinutes,
    scheduledAt,
    channel,
    message,
    status,
  ];
}
