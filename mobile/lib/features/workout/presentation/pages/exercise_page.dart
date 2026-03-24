import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../data/workout_remote_datasource.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _ds = WorkoutRemoteDataSource(sl());

  List<dynamic> _history = [];
  bool _loading = true;

  final _weightCtrl = TextEditingController();
  late PedometerService _pedometer;
  int _liveSteps = 0;
  List<dynamic> _stepsHistory = [];

  @override
  void initState() {
    super.initState();
    _pedometer = PedometerService();
    if (!kIsWeb) {
      _pedometer.start();
      _pedometer.steps.listen((s) {
        if (mounted) setState(() => _liveSteps = s);
      });
    }
    _load();
  }

  @override
  void dispose() {
    _pedometer.dispose();
    super.dispose();
    _weightCtrl.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _history = await _ds.getSessionHistory();
    } catch (_) {}
    setState(() => _loading = false);
    try {
      final res = await sl<Dio>().get(ApiConstants.stepsHistory,
          queryParameters: {'days': 7});
      _stepsHistory = res.data as List<dynamic>;
    } catch (_) {}

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
                child: 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Add before 'Track your workouts' text:
                    if (!kIsWeb) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Steps Today (Live)',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text('$_liveSteps',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await sl<WorkoutRemoteDataSource>().startSession();
                                // Use fitness endpoint to log steps
                                await sl<Dio>().post(ApiConstants.steps, data: {
                                  'steps': _liveSteps,
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Steps logged')),
                                  );
                                }
                              },
                              child: const Text('Log Steps'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

const SizedBox(height: 24),
const Text('Log Weight',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  ),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              hintText: 'Weight in kg', labelText: 'Today\'s Weight'),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () async {
          final w = double.tryParse(_weightCtrl.text);
          if (w == null) return;
          try {
            await sl<Dio>().post(ApiConstants.weight, data: {'weight_kg': w});
            _weightCtrl.clear();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Weight logged')));
            }
          } catch (_) {}
        },
        child: const Text('Log'),
      ),
    ],
  ),
),
                  
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
          SnackBar(content: Text('$name session logged')));
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
      if (_exercises.isNotEmpty && _selectedExercise == null) {
        setState(() => _selectedExercise = _exercises.first as Map<String, dynamic>);
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

                    const SizedBox(height: 24),
                    const Text('Steps This Week',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _stepsHistory.isEmpty
                          ? const Text('No step data yet',
                              style: TextStyle(color: AppColors.textMuted))
                          : Column(
                              children: _stepsHistory.map((s) {
                                final entry = s as Map<String, dynamic>;
                                final steps = (entry['steps'] as num).toInt();
                                final date = entry['date'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(date.substring(5),
                                          style: const TextStyle(
                                              color: AppColors.textSecondary)),
                                      Row(children: [
                                        Text('$steps steps',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 100,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: (steps / 10000).clamp(0.0, 1.0),
                                              backgroundColor: AppColors.border,
                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ],
              ),
            ),
        
    );
  }
}