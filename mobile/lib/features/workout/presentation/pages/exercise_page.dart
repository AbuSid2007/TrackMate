import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/workout_remote_datasource.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _ds = WorkoutRemoteDataSource(sl());

  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _history = await _ds.getSessionHistory();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;
    if (user == null) return const SizedBox.shrink();

    return MainLayout(
      user: user,
      title: 'Exercise',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Track your workouts',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _ExerciseTypeCard(
                            emoji: '💪',
                            title: 'Gym Session',
                            subtitle: 'Log sets, reps, and weight',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GymSessionPage(ds: _ds),
                              ),
                            ).then((_) => _load()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExerciseTypeCard(
                            emoji: '🏃',
                            title: 'Cardio',
                            subtitle: 'Log a cardio session',
                            onTap: () => _startQuickSession(context, 'Cardio'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Recent Sessions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No sessions yet',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    else
                      ..._history.map((s) {
                        final session = s as Map<String, dynamic>;
                        final sets = (session['sets'] as List?) ?? [];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center,
                                  color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session['name'] ?? 'Workout',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${sets.length} sets · ${session['calories_burned'] != null ? '${session['calories_burned']} kcal' : ''}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(session['started_at'] ?? ''),
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
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

  Future<void> _startQuickSession(BuildContext context, String name) async {
    try {
      final session = await _ds.startSession(name: name);
      final sessionId = session['session_id'] as String;
      await _ds.finishSession(sessionId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name session logged'),
          ),
        );
      }
    } catch (_) {}
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

class _ExerciseTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExerciseTypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class GymSessionPage extends StatefulWidget {
  final WorkoutRemoteDataSource ds;
  const GymSessionPage({super.key, required this.ds});

  @override
  State<GymSessionPage> createState() => _GymSessionPageState();
}

class _GymSessionPageState extends State<GymSessionPage> {
  String? _sessionId;
  final List<Map<String, dynamic>> _sets = [];
  List<dynamic> _exercises = [];
  Map<String, dynamic>? _selectedExercise;
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _starting = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _starting = true);
    try {
      final session = await widget.ds.startSession(name: 'Gym Session');
      setState(() => _sessionId = session['session_id'] as String);
      _exercises = await widget.ds.searchExercises();
      if (_exercises.isNotEmpty) {
        _selectedExercise = _exercises.first as Map<String, dynamic>;
      }
    } catch (_) {}
    setState(() => _starting = false);
  }

  Future<void> _logSet() async {
    if (_sessionId == null || _selectedExercise == null) return;
    final reps = int.tryParse(_repsCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    if (reps == null) return;

    try {
      await widget.ds.logSet(_sessionId!, {
        'exercise_id': _selectedExercise!['id'],
        'set_number': _sets.length + 1,
        'reps': reps,
        'weight_kg': weight,
      });
      setState(() {
        _sets.add({
          'exercise': _selectedExercise!['name'],
          'reps': reps,
          'weight': weight,
        });
        _repsCtrl.clear();
        _weightCtrl.clear();
      });
    } catch (_) {}
  }

  Future<void> _finish() async {
    if (_sessionId == null) return;
    setState(() => _finishing = true);
    try {
      await widget.ds.finishSession(_sessionId!);
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gym Session',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: _finishing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Finish',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _starting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_exercises.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Exercise',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedExercise,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: _exercises.map((e) {
                              final ex = e as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: ex,
                                child: Text(ex['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedExercise = v),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _repsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Reps'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _weightCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Weight (kg)'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logSet,
                              icon: const Icon(Icons.add),
                              label: const Text('Log Set'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_sets.isNotEmpty) ...[
                    const Text('Sets Logged',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._sets.asMap().entries.map((e) {
                      final s = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(s['exercise'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              '${s['reps']} reps${s['weight'] != null ? ' · ${s['weight']}kg' : ''}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}