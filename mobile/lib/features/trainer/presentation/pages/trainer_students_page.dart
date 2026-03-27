import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/trainer_remote_datasource.dart';
import 'student_detail_page.dart';

// 🔥 HELPER: Centralized modern card decoration for aesthetics
BoxDecoration _modernCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
  );
}

class TrainerStudentsPage extends StatefulWidget {
  const TrainerStudentsPage({super.key});

  @override
  State<TrainerStudentsPage> createState() => _TrainerStudentsPageState();
}

class _TrainerStudentsPageState extends State<TrainerStudentsPage> {
  final _ds = TrainerRemoteDataSource(sl());
  List<dynamic> _students = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  // 🔥 NEW: Frontend-only search state
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _ds.getStudents(),
        _ds.getStats(),
      ]);
      setState(() {
        _students = results[0] as List<dynamic>;
        _stats = results[1] as Map<String, dynamic>;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🔥 NEW: Filter students locally based on the search bar
    final filteredStudents = _students.where((s) {
      final name = (s['full_name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return MainLayout(
      user: user,
      title: 'My Students',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔥 NEW: Aesthetic Header
              Text(
                'Your Roster',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Manage and track your students' progress.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  _StatCard(Icons.people_outline, 'Students', '${_stats['total_students'] ?? 0}'),
                  const SizedBox(width: 12),
                  _StatCard(Icons.trending_up, 'Adherence', '${_stats['avg_adherence'] ?? 0}%', color: AppColors.success),
                  const SizedBox(width: 12),
                  _StatCard(Icons.error_outline, 'Attention', '${_stats['needs_attention'] ?? 0}', color: AppColors.error),
                ],
              ),
              const SizedBox(height: 24),

              // 🔥 NEW: Beautiful Local Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student List Container
              Container(
                decoration: _modernCardDecoration(),
                child: filteredStudents.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No students found.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (context, i) {
                    final s = filteredStudents[i] as Map<String, dynamic>;
                    final adherence = (s['adherence'] as num).toInt();
                    final needsAttention = s['needs_attention'] == true;
                    final color = needsAttention
                        ? AppColors.error
                        : adherence >= 80
                        ? AppColors.success
                        : AppColors.primary;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (s['full_name'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      title: Text(s['full_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: adherence / 100,
                              backgroundColor: AppColors.border.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          needsAttention ? 'Attention' : '$adherence%',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentDetailPage(
                              studentId: s['id'] as String,
                              studentName: s['full_name'] as String? ?? '',
                              ds: _ds),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.icon, this.label, this.value,
      {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16), // Slightly larger padding
        decoration: _modernCardDecoration(), // 🔥 Upgraded to modern styling
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}