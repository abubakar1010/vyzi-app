import 'package:get/get.dart';
import 'support_topic_model.dart';

class SupportTicketModel {
  final String id;
  final String topicId;
  final String subject;
  final String priority;
  final String status;
  final String? resolvedAt;
  final String? closedAt;
  final String createdAt;
  final String updatedAt;
  final SupportTopicModel? topic;

  const SupportTicketModel({
    required this.id,
    required this.topicId,
    required this.subject,
    required this.priority,
    required this.status,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.topic,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      resolvedAt: json['resolvedAt'] as String?,
      closedAt: json['closedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      topic: json['topic'] != null
          ? SupportTopicModel.fromJson(json['topic'] as Map<String, dynamic>)
          : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'open':
        return 'support.tickets.status.open'.tr;
      case 'in_progress':
        return 'support.tickets.status.in_progress'.tr;
      case 'resolved':
        return 'support.tickets.status.resolved'.tr;
      case 'closed':
        return 'support.tickets.status.closed'.tr;
      default:
        return status;
    }
  }
}
