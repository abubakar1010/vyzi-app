import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/support/controller/support_controller.dart';
import 'package:vyzi/features/support/ticket_detail_screen.dart';

class TicketInfoScreen extends StatefulWidget {
  final String ticketId;
  const TicketInfoScreen({super.key, required this.ticketId});

  @override
  State<TicketInfoScreen> createState() => _TicketInfoScreenState();
}

class _TicketInfoScreenState extends State<TicketInfoScreen> {
  final SupportController _controller = SupportController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _controller.fetchTicketDetail(widget.ticketId);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
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

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'low':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'urgent':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _priorityDisplay(String priority) {
    switch (priority) {
      case 'low':
        return 'support.ticket_info.priority.low'.tr;
      case 'medium':
        return 'support.ticket_info.priority.medium'.tr;
      case 'high':
        return 'support.ticket_info.priority.high'.tr;
      case 'urgent':
        return 'support.ticket_info.priority.urgent'.tr;
      default:
        return priority;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left,
                color: Color(0xFF1A1A2E), size: 28),
          ),
        ),
        title: Text(
          'support.ticket_info.title'.tr,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _controller.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      Text(
                        'support.ticket_info.not_found'.tr,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      _controller.fetchTicketDetail(widget.ticketId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Closed banner
                        if (isClosed)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'support.ticket_info.closed_banner'.tr,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Status + Priority badges
                        Row(
                          children: [
                            _buildBadge(
                              ticket.statusDisplay,
                              _statusColor(ticket.status),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              _priorityDisplay(ticket.priority),
                              _priorityColor(ticket.priority),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Subject card
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'support.ticket_info.subject'.tr,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ticket.subject,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Details card
                        _buildCard(
                          child: Column(
                            children: [
                              _buildDetailRow(
                                'support.ticket_info.topic'.tr,
                                ticket.topic?.name ?? '-',
                              ),
                              _buildDetailRow(
                                'support.ticket_info.priority'.tr,
                                _priorityDisplay(ticket.priority),
                              ),
                              _buildDetailRow(
                                'support.ticket_info.created'.tr,
                                _formatDate(ticket.createdAt),
                              ),
                              _buildDetailRow(
                                'support.ticket_info.updated'.tr,
                                _formatDate(ticket.updatedAt),
                              ),
                              if (ticket.resolvedAt != null)
                                _buildDetailRow(
                                  'support.ticket_info.resolved'.tr,
                                  _formatDate(ticket.resolvedAt!),
                                ),
                              if (ticket.closedAt != null)
                                _buildDetailRow(
                                  'support.ticket_info.closed'.tr,
                                  _formatDate(ticket.closedAt!),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Original message
                        if (_controller.messages.isNotEmpty)
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'support.ticket_info.original_message'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _controller.messages.first.message,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 13,
                                      height: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_controller.messages.isNotEmpty)
                          const SizedBox(height: 12),

                        // Conversation tile
                        _buildConversationTile(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.22),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticketId: widget.ticketId),
          ),
        ).then((_) {
          // Refresh to update message count after returning from conversation
          _controller.fetchTicketDetail(widget.ticketId);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1.22),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF5A1ABE), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'support.ticket_info.conversation'.tr,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_controller.messages.length} ${'support.ticket_info.messages'.tr}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.messages.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A1ABE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_controller.messages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }
}
