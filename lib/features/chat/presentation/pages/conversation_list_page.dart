import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import 'chat_detail_page.dart';

// ─────────────────────────────────────────────────────────────
// Static mock conversations
// ─────────────────────────────────────────────────────────────

class _MockConversation {
  final String id;
  final String name;
  final String specialization;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  const _MockConversation({
    required this.id,
    required this.name,
    required this.specialization,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

final List<_MockConversation> _mockConversations = [
  _MockConversation(
    id: '1',
    name: 'Dr. Sarah Kimani',
    specialization: 'General Practitioner',
    lastMessage: 'Your test results look good. Keep up the medication.',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
    unreadCount: 2,
    isOnline: true,
  ),
  _MockConversation(
    id: '2',
    name: 'Dr. James Odhiambo',
    specialization: 'Cardiologist',
    lastMessage: 'Please schedule a follow-up visit next week.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    unreadCount: 0,
    isOnline: true,
  ),
  _MockConversation(
    id: '3',
    name: 'Dr. Amina Hassan',
    specialization: 'Dermatologist',
    lastMessage: 'Apply the cream twice daily for two weeks.',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
    unreadCount: 1,
    isOnline: false,
  ),
  _MockConversation(
    id: '4',
    name: 'Dr. Peter Mwangi',
    specialization: 'Orthopedic Surgeon',
    lastMessage: 'The X-ray shows significant improvement.',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 0,
    isOnline: false,
  ),
  _MockConversation(
    id: '5',
    name: 'Dr. Lucy Wanjiku',
    specialization: 'Pediatrician',
    lastMessage: 'Make sure the child stays hydrated and rests well.',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
    unreadCount: 0,
    isOnline: false,
  ),
  _MockConversation(
    id: '6',
    name: 'Dr. David Otieno',
    specialization: 'ENT Specialist',
    lastMessage: "I've prescribed a new nasal spray for you.",
    lastMessageAt: DateTime.now().subtract(const Duration(days: 3)),
    unreadCount: 0,
    isOnline: true,
  ),
];

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({super.key});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  String _query = '';

  List<_MockConversation> get _filtered {
    if (_query.isEmpty) return _mockConversations;
    final q = _query.toLowerCase();
    return _mockConversations
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.specialization.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final online = _mockConversations.where((c) => c.isOnline).toList();

    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Search field
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search doctors…',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_query.isEmpty && online.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Online now',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: online.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _OnlineAvatar(conversation: online[index]),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              _query.isEmpty
                  ? 'Recent chats'
                  : '${list.length} result${list.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (list.isEmpty)
            const _EmptyChats()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < list.length; i++) ...[
                    _ConversationTile(conversation: list[i]),
                    if (i != list.length - 1)
                      const Divider(height: 1, indent: 78, endIndent: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineAvatar extends StatelessWidget {
  final _MockConversation conversation;
  const _OnlineAvatar({required this.conversation});

  String _firstName(String full) {
    final parts = full.split(' ');
    return parts.length > 1 ? parts[1] : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conversation.id,
            doctorName: conversation.name,
          ),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  conversation.name.split(' ').last[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mint, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              _firstName(conversation.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No conversations',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your messages with doctors will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _MockConversation conversation;
  const _ConversationTile({required this.conversation});

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final timeStr = _formatTime(conversation.lastMessageAt);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conversation.id,
            doctorName: conversation.name,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    conversation.name.split(' ').last[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.specialization,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
