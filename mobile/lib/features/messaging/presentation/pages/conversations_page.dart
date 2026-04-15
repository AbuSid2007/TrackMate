import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/messaging_remote_datasource.dart';
import '../../../social/data/social_remote_datasource.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _ds = sl<MessagingRemoteDataSource>();
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final convos = await _ds.getConversations();
      if (mounted) setState(() => _conversations = convos);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showNewChatSheet(String currentUserId) {
    // 🔥 FIX: Extract all the IDs of users we ALREADY have an active chat with
    final existingUserIds = _conversations
        .map((c) => c['other_user']?['id']?.toString())
        .whereType<String>()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewChatSheet(
        currentUserId: currentUserId,
        existingChatUserIds: existingUserIds, // Pass the active chat IDs to the sheet
        onChatStarted: () => _load(), 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticatedState).user;

    return MainLayout(
      user: user,
      title: 'Messages',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showNewChatSheet(user.id),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? const Center(
                    child: Text('No messages yet. Tap the button to start chatting!',
                        style: TextStyle(color: AppColors.textMuted)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = _conversations[i];
                        final otherUser = c['other_user'] ?? {};
                        final lastMsg = c['last_message'];
                        final unread = c['unread_count'] as int? ?? 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            radius: 24,
                            child: Text(
                              (otherUser['full_name']?[0] ?? 'U').toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            otherUser['full_name'] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: lastMsg != null
                              ? Text(
                                  lastMsg['content'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread > 0 ? AppColors.textPrimary : AppColors.textMuted,
                                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                )
                              : const Text('No messages yet', style: TextStyle(fontStyle: FontStyle.italic)),
                          trailing: unread > 0
                              ? CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppColors.primary,
                                  child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId: c['conversation_id'],
                                  otherUserId: otherUser['id'],
                                  otherUserName: otherUser['full_name'],
                                  ds: _ds,
                                  currentUserId: user.id,
                                ),
                              ),
                            ).then((_) => _load());
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  final String currentUserId;
  final List<String> existingChatUserIds;
  final VoidCallback onChatStarted;
  
  const _NewChatSheet({
    required this.currentUserId, 
    required this.existingChatUserIds, 
    required this.onChatStarted
  });

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _socialDs = SocialRemoteDataSource(sl());
  final _msgDs = sl<MessagingRemoteDataSource>();
  
  bool _loading = true;
  List<dynamic> _friends = [];
  List<dynamic> _searchResults = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _socialDs.getFriends();
      
      // 🔥 FIX: Filter out friends you already have a conversation with
      final filteredFriends = friends.where((f) {
        final id = (f as Map)['id']?.toString();
        return id != null && !widget.existingChatUserIds.contains(id);
      }).toList();

      if (mounted) {
        setState(() {
          _friends = filteredFriends;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final res = await _socialDs.searchUsers(q); 
      
      // 🔥 FIX: Filter out yourself AND anyone you already have a chat with
      final filteredRes = res.where((u) {
        final id = (u as Map)['id']?.toString();
        return id != null && 
               id != widget.currentUserId && 
               !widget.existingChatUserIds.contains(id);
      }).toList();

      if (mounted) setState(() => _searchResults = filteredRes);
    } catch (_) {}
  }

  void _startChat(Map<String, dynamic> otherUser) async {
     try {
        showDialog(
          context: context, 
          barrierDismissible: false, 
          builder: (_) => const Center(child: CircularProgressIndicator())
        );
        
        final conv = await _msgDs.startConversation(otherUser['id']);
        
        if (!mounted) return;
        Navigator.pop(context); 
        Navigator.pop(context); 
        
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
           conversationId: conv['conversation_id'],
           otherUserId: otherUser['id'],
           otherUserName: otherUser['full_name'] ?? 'User',
           ds: _msgDs,
           currentUserId: widget.currentUserId,
        )));
        
        widget.onChatStarted(); 
     } catch(e) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start conversation'))
          );
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _searchCtrl.text.trim().isNotEmpty ? _searchResults : _friends;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('New Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search for friends or trainers...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                    ? Center(child: Text(_searchCtrl.text.isEmpty ? 'All friends have active chats.' : 'No new users found.', style: const TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        controller: controller,
                        itemCount: displayList.length,
                        itemBuilder: (context, i) {
                          final user = displayList[i] as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text((user['full_name'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                            ),
                            title: Text(user['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(user['role'] ?? 'User'),
                            trailing: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                            onTap: () => _startChat(user),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}