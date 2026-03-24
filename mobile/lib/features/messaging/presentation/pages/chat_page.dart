import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/messaging_remote_datasource.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final MessagingRemoteDataSource ds;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.ds,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  bool _isOtherTyping = false;
  Timer? _typingTimer;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _init() async {
    // Load history
    try {
      final msgs = await widget.ds.getMessages(widget.conversationId);
      setState(() => _messages.addAll(msgs.cast<Map<String, dynamic>>()));
      await widget.ds.markRead(widget.conversationId);
    } catch (_) {}

    // Connect WebSocket via ticket
    try {
      final ticket = await widget.ds.getWsTicket();
      final wsBase = ApiConstants.baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsBase${ApiConstants.apiVersion}/messaging/ws?ticket=$ticket'),
      );
      setState(() => _connected = true);

      _channel!.stream.listen(
        (raw) {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'new_message') {
            final msg = data['message'] as Map<String, dynamic>;
            if (msg['conversation_id'] == widget.conversationId) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          } else if (type == 'typing') {
            if (data['user_id'] != widget.currentUserId) {
              setState(() => _isOtherTyping = true);
              _typingTimer?.cancel();
              _typingTimer = Timer(const Duration(seconds: 5), () {
                if (mounted) setState(() => _isOtherTyping = false);
              });
            }
          } else if (type == 'messages_read') {
            // Update message statuses
          }
        },
        onDone: () => setState(() => _connected = false),
        onError: (_) => setState(() => _connected = false),
      );
    } catch (_) {}

    _scrollToBottom();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'send_message',
      'conversation_id': widget.conversationId,
      'content': text,
    }));
    _inputCtrl.clear();
  }

  void _sendTyping() {
    _channel?.sink.add(jsonEncode({
      'type': 'typing',
      'conversation_id': widget.conversationId,
    }));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              radius: 16,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  _connected ? 'Online' : 'Connecting...',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          _connected ? AppColors.success : AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isOtherTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_isOtherTyping && i == _messages.length) {
                  return _TypingBubble(name: widget.otherUserName);
                }
                final m = _messages[i];
                final isMe = m['sender_id'] == widget.currentUserId;
                return _MessageBubble(
                  content: m['content'] ?? '',
                  isMe: isMe,
                  status: m['status'] as String? ?? 'sent',
                  time: m['created_at'] as String? ?? '',
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    onChanged: (_) => _sendTyping(),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String status;
  final String time;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: isMe
                  ? null
                  : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        status == 'read'
                            ? Icons.done_all
                            : status == 'delivered'
                                ? Icons.done_all
                                : Icons.done,
                        size: 12,
                        color: status == 'read'
                            ? Colors.lightBlueAccent
                            : Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _TypingBubble extends StatelessWidget {
  final String name;
  const _TypingBubble({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('$name is typing...',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ),
      ),
    );
  }
}