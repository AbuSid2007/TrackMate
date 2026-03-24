import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _saving = false;
  final _dio = sl<Dio>();

  // Fields
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _stepGoalCtrl = TextEditingController(text: '10000');
  final _calorieGoalCtrl = TextEditingController(text: '2000');
  String? _gender;
  String? _activityLevel;
  DateTime? _dob;

  final _genders = ['male', 'female', 'other', 'prefer_not_to_say'];
  final _activityLevels = [
    'sedentary', 'lightly_active', 'moderately_active',
    'very_active', 'extra_active'
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [_heightCtrl, _weightCtrl, _stepGoalCtrl, _calorieGoalCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await _dio.put(ApiConstants.profile, data: {
        'gender': _gender,
        'date_of_birth': _dob?.toIso8601String(),
        'height_cm': double.tryParse(_heightCtrl.text),
        'weight_kg': double.tryParse(_weightCtrl.text),
        'daily_step_goal': int.tryParse(_stepGoalCtrl.text) ?? 10000,
        'daily_calorie_goal': int.tryParse(_calorieGoalCtrl.text),
        'activity_level': _activityLevel,
      });
    } catch (_) {}
    setState(() => _saving = false);
    widget.onComplete();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _page ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _BasicInfoPage(
                    gender: _gender,
                    dob: _dob,
                    genders: _genders,
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onDobChanged: (v) => setState(() => _dob = v),
                  ),
                  _BiometricsPage(
                    heightCtrl: _heightCtrl,
                    weightCtrl: _weightCtrl,
                  ),
                  _GoalsPage(
                    stepGoalCtrl: _stepGoalCtrl,
                    calorieGoalCtrl: _calorieGoalCtrl,
                    activityLevel: _activityLevel,
                    activityLevels: _activityLevels,
                    onActivityChanged: (v) => setState(() => _activityLevel = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _pageCtrl.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving ? null : _next,
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_page == 2 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicInfoPage extends StatelessWidget {
  final String? gender;
  final DateTime? dob;
  final List<String> genders;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<DateTime?> onDobChanged;

  const _BasicInfoPage({
    required this.gender, required this.dob,
    required this.genders, required this.onGenderChanged,
    required this.onDobChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us about yourself',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This helps us personalize your experience.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: genders.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g.replaceAll('_', ' ')),
            )).toList(),
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              dob != null
                  ? 'Date of Birth: ${dob!.day}/${dob!.month}/${dob!.year}'
                  : 'Select Date of Birth',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            trailing: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textMuted),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dob ?? DateTime(1995),
                firstDate: DateTime(1940),
                lastDate: DateTime.now()
                    .subtract(const Duration(days: 365 * 10)),
              );
              if (picked != null) onDobChanged(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _BiometricsPage extends StatelessWidget {
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;

  const _BiometricsPage(
      {required this.heightCtrl, required this.weightCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your measurements',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Used to calculate your calorie needs.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Height (cm)', hintText: 'e.g. 175'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Weight (kg)', hintText: 'e.g. 70'),
          ),
        ],
      ),
    );
  }
}

class _GoalsPage extends StatelessWidget {
  final TextEditingController stepGoalCtrl;
  final TextEditingController calorieGoalCtrl;
  final String? activityLevel;
  final List<String> activityLevels;
  final ValueChanged<String?> onActivityChanged;

  const _GoalsPage({
    required this.stepGoalCtrl, required this.calorieGoalCtrl,
    required this.activityLevel, required this.activityLevels,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set your goals',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("We'll track your progress towards these.",
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: stepGoalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Daily Step Goal', hintText: '10000'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: calorieGoalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Daily Calorie Goal', hintText: '2000'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: activityLevel,
            decoration: const InputDecoration(labelText: 'Activity Level'),
            items: activityLevels.map((a) => DropdownMenuItem(
              value: a,
              child: Text(a.replaceAll('_', ' ')),
            )).toList(),
            onChanged: onActivityChanged,
          ),
        ],
      ),
    );
  }
}