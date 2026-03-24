import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/admin_remote_datasource.dart';
import '../../../../core/di/injection.dart';

class AdminTrainersPage extends StatefulWidget {
  const AdminTrainersPage({super.key});

  @override
  State<AdminTrainersPage> createState() => _AdminTrainersPageState();
}

class _AdminTrainersPageState extends State<AdminTrainersPage> {
  final _ds = AdminRemoteDataSource(sl());
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _ds.getTrainerApplications();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _respond(String userId, bool approve) async {
    try {
      await _ds.approveTrainer(userId, approve);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Trainer approved' : 'Application rejected'),
          backgroundColor: approve ? AppColors.success : AppColors.error,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final summary = _data['summary'] as Map<String, dynamic>? ?? {};
    final apps = _data['applications'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trainer Applications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SummaryChip('Total', '${summary['total'] ?? 0}',
                            AppColors.primary),
                        const SizedBox(width: 8),
                        _SummaryChip('Pending',
                            '${summary['pending'] ?? 0}', Colors.orange),
                        const SizedBox(width: 8),
                        _SummaryChip('Approved',
                            '${summary['approved'] ?? 0}', AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...apps.map((a) {
                      final app = a as Map<String, dynamic>;
                      final isPending = app['status'] == 'pending';
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
                                  child: Text(
                                    (app['full_name'] as String? ??
                                            'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(app['full_name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(app['email'] ?? '',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.orange.withOpacity(0.1)
                                        : AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    app['status'] ?? '',
                                    style: TextStyle(
                                      color: isPending
                                          ? Colors.orange
                                          : AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (app['about'] != null) ...[
                              const SizedBox(height: 8),
                              Text(app['about'],
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                            if (app['specializations'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Specializations: ${app['specializations']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary),
                              ),
                            ],
                            if (app['experience_years'] != null)
                              Text(
                                  '${app['experience_years']} years experience',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            if (isPending) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(
                                          app['user_id'], true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.success),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respond(
                                          app['user_id'], false),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppColors.error),
                                      ),
                                      child: const Text('Reject',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}