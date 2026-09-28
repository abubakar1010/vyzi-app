class TicketMessageModel {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final List<String>? attachments;
  final String createdAt;
  final SenderModel? sender;

  const TicketMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    this.attachments,
    required this.createdAt,
    this.sender,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      id: json['id'] as String? ?? '',
      ticketId: json['ticketId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      createdAt: json['createdAt'] as String? ?? '',
      sender: json['sender'] != null
          ? SenderModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SenderModel {
  final String id;
  final String firstName;
  final String lastName;

  const SenderModel({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory SenderModel.fromJson(Map<String, dynamic> json) {
    return SenderModel(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
