import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/messaging_remote_datasource.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _ds = MessagingRemoteDataSource(sl());
  List<dynamic> _convos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _convos = await _ds.getConversations();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticatedState).user;

    return MainLayout(
      user: user,
      title: 'Messages',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _convos.isEmpty
                  ? const Center(
                      child: Text('No conversations yet',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _convos.length,
                      itemBuilder: (context, i) {
                        final c = _convos[i] as Map<String, dynamic>;
                        final other =
                            c['other_user'] as Map<String, dynamic>? ?? {};
                        final last =
                            c['last_message'] as Map<String, dynamic>?;
                        final unread = (c['unread_count'] as num?)?.toInt() ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (other['full_name'] as String? ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(other['full_name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: last != null
                                ? Text(
                                    last['content'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  )
                                : null,
                            trailing: unread > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  )
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  conversationId:
                                      c['conversation_id'] as String,
                                  otherUserId:
                                      other['id'] as String? ?? '',
                                  otherUserName:
                                      other['full_name'] as String? ?? '',
                                  ds: _ds,
                                  currentUserId: user.id,
                                ),
                              ),
                            ).then((_) => _load()),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}