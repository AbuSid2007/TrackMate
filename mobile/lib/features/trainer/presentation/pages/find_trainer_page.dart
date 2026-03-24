import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/trainer_remote_datasource.dart';

class FindTrainerPage extends StatefulWidget {
  const FindTrainerPage({super.key});

  @override
  State<FindTrainerPage> createState() => _FindTrainerPageState();
}

class _FindTrainerPageState extends State<FindTrainerPage> {
  final _ds = TrainerRemoteDataSource(sl());
  List<dynamic> _trainers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _trainers = await _ds.getAvailableTrainers();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _sendRequest(BuildContext context, String trainerId) {
    final goalCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send Request',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: goalCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What are your fitness goals?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (goalCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await _ds.sendTrainerRequest(
                        trainerId, goalCtrl.text.trim());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request sent!')),
                      );
                    }
                  } catch (_) {}
                },
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        (context.read<AuthBloc>().state as AuthAuthenticatedState).user;

    return MainLayout(
      user: user,
      title: 'Find a Trainer',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _trainers.isEmpty
                  ? const Center(
                      child: Text('No trainers available',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _trainers.length,
                      itemBuilder: (context, i) {
                        final t = _trainers[i] as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    radius: 24,
                                    child: Text(
                                      (t['full_name'] as String? ??
                                              'T')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t['full_name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        if (t['experience_years'] != null)
                                          Text(
                                              '${t['experience_years']} years experience',
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (t['hourly_rate'] != null)
                                    Text(
                                      '₹${t['hourly_rate']}/hr',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                    ),
                                ],
                              ),
                              if (t['bio'] != null) ...[
                                const SizedBox(height: 8),
                                Text(t['bio'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                              if (t['specializations'] != null) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children:
                                      (t['specializations'] as String)
                                          .split(',')
                                          .map((s) => Chip(
                                                label: Text(s.trim(),
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                backgroundColor: AppColors
                                                    .primary
                                                    .withOpacity(0.08),
                                                side: BorderSide(
                                                    color: AppColors.primary
                                                        .withOpacity(0.3)),
                                                padding: EdgeInsets.zero,
                                              ))
                                          .toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _sendRequest(
                                      context, t['id']),
                                  child: const Text('Request as My Trainer'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}