import 'package:flutter/foundation.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/features/support/models/support_topic_model.dart';
import 'package:vyzi/features/support/models/support_ticket_model.dart';
import 'package:vyzi/features/support/models/ticket_message_model.dart';

class SupportController extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── Topics ──
  bool isLoadingTopics = false;
  List<SupportTopicModel> topics = [];

  // ── Tickets ──
  bool isLoadingTickets = false;
  List<SupportTicketModel> tickets = [];

  // ── Current ticket detail ──
  bool isLoadingDetail = false;
  SupportTicketModel? currentTicket;
  List<TicketMessageModel> messages = [];

  // ── Submit state ──
  bool isSubmitting = false;
  bool isSendingMessage = false;
  String? error;

  // ─── Fetch active topics ─────────────────────────────────

  Future<void> fetchTopics() async {
    isLoadingTopics = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(ApiConstants.supportTopics);
      final data = response.data['data'];
      if (data is List) {
        topics = data
            .map((e) => SupportTopicModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = 'Failed to load topics';
      debugPrint('SupportController.fetchTopics error: $e');
    } finally {
      isLoadingTopics = false;
      notifyListeners();
    }
  }

  // ─── Fetch user's tickets ────────────────────────────────

  Future<void> fetchMyTickets({int page = 1}) async {
    isLoadingTickets = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(
        '${ApiConstants.supportTickets}?page=$page&limit=20',
      );
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        final list = data['data'] as List? ?? [];
        tickets = list
            .map((e) =>
                SupportTicketModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = 'Failed to load tickets';
      debugPrint('SupportController.fetchMyTickets error: $e');
    } finally {
      isLoadingTickets = false;
      notifyListeners();
    }
  }

  // ─── Create ticket ───────────────────────────────────────

  Future<bool> createTicket({
    required String topicId,
    required String subject,
    required String message,
    String? priority,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'topicId': topicId,
        'subject': subject,
        'message': message,
      };
      if (priority != null) body['priority'] = priority;

      await _api.post(ApiConstants.supportTickets, data: body);
      return true;
    } catch (e) {
      error = 'Failed to submit request';
      debugPrint('SupportController.createTicket error: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // ─── Fetch ticket detail ─────────────────────────────────

  Future<void> fetchTicketDetail(String ticketId) async {
    isLoadingDetail = true;
    error = null;
    notifyListeners();
    try {
      final response = await _api.get(
        ApiConstants.supportTicketDetail(ticketId),
      );
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        currentTicket = SupportTicketModel.fromJson(data);
        final msgList = data['messages'] as List? ?? [];
        messages = msgList
            .map((e) =>
                TicketMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      error = 'Failed to load ticket';
      debugPrint('SupportController.fetchTicketDetail error: $e');
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ─── Fetch messages ──────────────────────────────────────

  Future<void> fetchMessages(String ticketId) async {
    try {
      final response = await _api.get(
        ApiConstants.supportTicketMessages(ticketId),
      );
      final data = response.data['data'];
      if (data is List) {
        messages = data
            .map((e) =>
                TicketMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SupportController.fetchMessages error: $e');
    }
  }

  // ─── Send message ────────────────────────────────────────

  Future<bool> sendMessage(String ticketId, String message) async {
    isSendingMessage = true;
    notifyListeners();
    try {
      await _api.post(
        ApiConstants.supportTicketMessages(ticketId),
        data: {'message': message},
      );
      await fetchMessages(ticketId);
      return true;
    } catch (e) {
      debugPrint('SupportController.sendMessage error: $e');
      return false;
    } finally {
      isSendingMessage = false;
      notifyListeners();
    }
  }
}
