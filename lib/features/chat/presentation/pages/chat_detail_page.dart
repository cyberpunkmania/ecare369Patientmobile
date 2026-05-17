import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';

// ─────────────────────────────────────────────────────────────
// Static mock messages (per conversation)
// ─────────────────────────────────────────────────────────────

class _MockMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;

  const _MockMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}

final Map<String, List<_MockMessage>> _mockMessages = {
  '1': [
    _MockMessage(
      text: 'Good morning Dr. Kimani, I wanted to check on my test results.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    _MockMessage(
      text:
          'Good morning! I have reviewed your results and everything looks normal.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    _MockMessage(
      text: 'That is great news! Should I continue with the medication?',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      isRead: true,
    ),
    _MockMessage(
      text:
          'Yes, please continue for another 2 weeks. Take it after breakfast as usual.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
    ),
    _MockMessage(
      text: 'Understood, thank you doctor!',
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: true,
    ),
    _MockMessage(
      text: 'Your test results look good. Keep up the medication.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ],
  '2': [
    _MockMessage(
      text: 'Hello Doctor, I have been experiencing some chest pains.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    _MockMessage(
      text:
          'I see. Can you describe the pain? Is it sharp or dull? How often does it occur?',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
    ),
    _MockMessage(
      text:
          'It is a dull ache, happens mostly in the evening after work. Maybe 3-4 times a week.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
      isRead: true,
    ),
    _MockMessage(
      text:
          'Please schedule a follow-up visit next week. I would like to run an ECG.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  '3': [
    _MockMessage(
      text: 'Dr. Hassan, the rash on my arm seems to be spreading.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: true,
    ),
    _MockMessage(
      text:
          'Can you send me a photo? Also, did you start any new products recently?',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
    ),
    _MockMessage(
      text: 'No new products. I will take a photo shortly.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    _MockMessage(
      text: 'Apply the cream twice daily for two weeks.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ],
};

List<_MockMessage> _messagesFor(String id) =>
    _mockMessages[id] ??
    [
      _MockMessage(
        text: 'Hello! How can I help you today?',
        isMe: false,
        time: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

// ─────────────────────────────────────────────────────────────
// WhatsApp-style chat detail
// ─────────────────────────────────────────────────────────────

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String doctorName;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.doctorName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late List<_MockMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.of(_messagesFor(widget.conversationId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_MockMessage(text: text, isMe: true, time: DateTime.now()));
    });
    _controller.clear();
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Group messages by date for date headers
  Map<String, List<_MockMessage>> _groupByDate() {
    final grouped = <String, List<_MockMessage>>{};
    for (final m in _messages) {
      final key = _dateLabel(m.time);
      (grouped[key] ??= []).add(m);
    }
    return grouped;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupByDate();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                widget.doctorName.split(' ').last[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.doctorName, style: const TextStyle(fontSize: 16)),
                  const Text(
                    'online',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFECE5DD),
        ),
        child: Column(
          children: [
            // ── Messages ──
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                children: [
                  for (final entry in grouped.entries) ...[
                    _DateChip(label: entry.key),
                    for (final msg in entry.value)
                      _MessageBubble(message: msg, isDark: isDark),
                  ],
                ],
              ),
            ),
            // ── Input bar ──
            _InputBar(controller: _controller, onSend: _send, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Date chip separator (like WhatsApp)
// ─────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message bubble with tail + read receipts
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _MockMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final timeStr = DateFormat('h:mm a').format(message.time);

    // WhatsApp-style colours
    final Color bubbleColor = isMe
        ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6))
        : (isDark ? AppColors.darkCard : Colors.white);

    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color metaColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 56 : 0,
          right: isMe ? 0 : 56,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: TextStyle(fontSize: 11, color: metaColor)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.isRead ? AppColors.info : metaColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input bar – WhatsApp style
// ─────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Row(
          children: [
            // Main text field row
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send / mic button
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
