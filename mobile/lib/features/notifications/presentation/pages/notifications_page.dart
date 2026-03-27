import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/notifications_remote_datasource.dart';
import 'package:go_router/go_router.dart';

// 🔥 ADDED: Imports required for the Coaching Hub routing
import '../../../trainer/data/trainer_remote_datasource.dart';
import '../../../trainer/presentation/pages/coaching_hub_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _ds = NotificationsRemoteDataSource(sl());
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // 🔥 UPDATED: Smart routing logic that safely checks the user role
  void _routeNotification(BuildContext context, Map<String, dynamic> n, dynamic user) async {
    final type = n['type']?.toString().trim() ?? '';
    final isTrainee = user.role.toString().toLowerCase().contains('trainee');

    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        context.go('/social');
        break;
      case 'new_message':
        context.go('/messages');
        break;
      case 'trainer_request':
      case 'trainer_rejected':
        if (!isTrainee) {
          context.go('/trainer/requests');
        }
        break;
      case 'trainer_accepted':
      case 'trainer_approved':
        if (isTrainee) {
          // Show a quick loader while we fetch their current trainer
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final trainerDs = sl<TrainerRemoteDataSource>();
            final trainer = await trainerDs.getMyTrainer();

            if (context.mounted) Navigator.pop(context); // Close loading dialog

            if (trainer != null) {
              // Check if notification is from current trainer (using fallback keys)
              final senderId = n['actor_id'] ?? n['sender_id'] ?? n['related_id'];

              if (senderId == null || trainer['id'] == senderId) {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CoachingHubPage(trainerInfo: trainer),
                  ));
                }
              } else {
                // It's from an old trainer -> Do nothing except notify them
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is an old notification for a past trainer.')),
                  );
                }
              }
            } else {
              // No active trainer -> Do nothing except notify them
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You do not have an active trainer right now.')),
                );
              }
            }
          } catch (_) {
            if (context.mounted) Navigator.pop(context); // Close dialog on error
          }
        } else {
          // If the user is a trainer, keep old functionality
          context.go('/trainer/requests');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _ds.getNotifications();
      setState(() {
        _notifications =
            (data['notifications'] as List?) ?? [];
        _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return Icons.people;
      case 'trainer_request':
      case 'trainer_accepted':
      case 'trainer_rejected':
      case 'trainer_approved':
        return Icons.fitness_center;
      case 'new_message':
        return Icons.message;
      case 'post_like':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return AppColors.primary;
      case 'trainer_approved':
      case 'trainer_accepted':
        return AppColors.success;
      case 'trainer_rejected':
        return AppColors.error;
      case 'post_like':
        return Colors.pink;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticatedState).user;

    return MainLayout(
      user: user,
      title: 'Notifications',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            if (_unreadCount > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('$_unreadCount unread',
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await _ds.markAllRead();
                        await _load();
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                  child: Text('No notifications',
                      style: TextStyle(
                          color: AppColors.textMuted)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _notifications.length,
                itemBuilder: (_, i) {
                  final n = _notifications[i]
                  as Map<String, dynamic>;
                  final isRead = n['is_read'] == true;
                  final type = n['type'] as String? ?? '';

                  return Dismissible(
                    key: Key(n['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: AppColors.error,
                      child: const Icon(Icons.delete,
                          color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await _ds.delete(n['id']);
                      setState(() =>
                          _notifications.removeAt(i));
                    },
                    child: InkWell(
                      onTap: () {
                        if (!isRead) _ds.markRead(n['id']).then((_) => _load());
                        // 🔥 UPDATED: Pass the user object so routing works safely
                        _routeNotification(context, n, user);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppColors.surface
                              : AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead
                                ? AppColors.border
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _colorFor(type).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(type), color: _colorFor(type), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n['title'] ?? '',
                                      style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(n['body'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}