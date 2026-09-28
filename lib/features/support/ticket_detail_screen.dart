import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/support/controller/support_controller.dart';
import 'package:vyzi/features/support/models/ticket_message_model.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportController _controller = SupportController();
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.fetchTicketDetail(widget.ticketId).then((_) {
      _scrollToBottom();
    });
    _loadCurrentUserId();
  }

  void _loadCurrentUserId() {
    try {
      final storage = Get.find<StorageService>();
      final userId = storage.getString(StorageKeys.userId);
      if (mounted && userId != null) {
        setState(() => _currentUserId = userId);
      }
    } catch (_) {
      debugPrint('StorageService not found, cannot determine current user');
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessages() async {
    await _controller.fetchTicketDetail(widget.ticketId);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();
    final success = await _controller.sendMessage(widget.ticketId, text);
    if (success) {
      _scrollToBottom();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool _isSameDay(String date1, String date2) {
    try {
      final d1 = DateTime.parse(date1);
      final d2 = DateTime.parse(date2);
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) {
      return false;
    }
  }

  String _dateSeparatorLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(date.year, date.month, date.day);

      if (msgDate == today) return 'support.ticket_detail.today'.tr;
      if (msgDate == yesterday) return 'support.ticket_detail.yesterday'.tr;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _controller.currentTicket;
    final isClosed =
        ticket?.status == 'closed' || ticket?.status == 'resolved';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A2E), size: 28),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket?.subject ?? 'support.ticket_detail.title'.tr,
              style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 15,
                  fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket != null)
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor(ticket.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.statusDisplay,
                    style: TextStyle(
                      color: _statusColor(ticket.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: _controller.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMessages,
                    child: _controller.messages.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height *
                                          0.25),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 48,
                                        color: const Color(0xFFCBD5E1)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'support.ticket_detail.send_hint'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: _controller.messages.length,
                            itemBuilder: (context, index) {
                              final msg = _controller.messages[index];
                              final isMe =
                                  msg.senderId == _currentUserId;

                              // Date separator
                              final showDate = index == 0 ||
                                  !_isSameDay(
                                    msg.createdAt,
                                    _controller.messages[index - 1]
                                        .createdAt,
                                  );

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showDate)
                                    _DateSeparator(
                                      label: _dateSeparatorLabel(
                                          msg.createdAt),
                                    ),
                                  _MessageBubble(
                                    message: msg,
                                    isMe: isMe,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),

                // Input bar
                if (!isClosed)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? 12
                          : 48,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                            color: Color(0xFFE8E8E8), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText:
                                  'support.ticket_detail.send_hint'.tr,
                              hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF3F3F5),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _controller.isSendingMessage
                              ? null
                              : _sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: _controller.isSendingMessage
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                            color: Color(0xFFE8E8E8), width: 1),
                      ),
                    ),
                    child: Text(
                      'support.ticket_detail.closed_notice'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/* ── Date Separator ────────────────────────────────────────── */

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFFE8E8E8), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: Color(0xFFE8E8E8), height: 1)),
        ],
      ),
    );
  }
}

/* ── Message Bubble ────────────────────────────────────────── */

class _MessageBubble extends StatelessWidget {
  final TicketMessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF8b85f6),
              child: Text(
                message.sender?.firstName.isNotEmpty == true
                    ? message.sender!.firstName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: const Color(0xFFE8E8E8), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.sender != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender!.fullName,
                        style: const TextStyle(
                          color: Color(0xFF8b85f6),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : const Color(0xFF1A1A2E),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white38
                          : const Color(0xFFB0B8C4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
