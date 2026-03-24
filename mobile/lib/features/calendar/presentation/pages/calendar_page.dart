import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../trainer/data/trainer_remote_datasource.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _ds = TrainerRemoteDataSource(sl());
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _ds.dio.get('/api/v1/trainer/my-sessions');
      _sessions = res.data as List<dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticatedState).user;

    return MainLayout(
      user: user,
      title: 'My Schedule',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sessions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No sessions scheduled.\nRequest a trainer to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      itemBuilder: (_, i) {
                        final s = _sessions[i] as Map<String, dynamic>;
                        final trainer =
                            s['trainer'] as Map<String, dynamic>? ?? {};
                        final dt =
                            DateTime.tryParse(s['scheduled_at'] ?? '')
                                ?.toLocal();
                        final isPast = dt != null &&
                            dt.isBefore(DateTime.now());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPast
                                  ? AppColors.border
                                  : AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? AppColors.border
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dt != null
                                          ? '${dt.day}'
                                          : '--',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isPast
                                              ? AppColors.textMuted
                                              : AppColors.primary),
                                    ),
                                    Text(
                                      dt != null
                                          ? _monthAbbr(dt.month)
                                          : '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isPast
                                              ? AppColors.textMuted
                                              : AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Session with ${trainer['full_name'] ?? ''}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dt != null
                                          ? '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} · ${s['duration_minutes']} min'
                                          : '',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    ),
                                    if (s['notes'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(s['notes'],
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isPast)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Upcoming',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }
}