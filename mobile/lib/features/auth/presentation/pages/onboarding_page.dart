import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/api_constants.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isSaving = false;
  final Dio _dio = sl<Dio>();

  // Default values to prevent validation blocks during testing
  String _gender = 'male';
  DateTime? _dob = DateTime(1995, 1, 1);
  String _activityLevel = 'moderately_active';

  // Form Controllers
  final TextEditingController _heightCtrl = TextEditingController(text: '170');
  final TextEditingController _weightCtrl = TextEditingController(text: '70');
  final TextEditingController _stepGoalCtrl = TextEditingController(text: '10000');
  final TextEditingController _calorieGoalCtrl = TextEditingController(text: '2000');

  final Map<String, String> _genderOptions = {
    'Male': 'male',
    'Female': 'female',
    'Other': 'other',
    'Prefer not to say': 'prefer_not_to_say'
  };

  final Map<String, String> _activityOptions = {
    'Sedentary (Little/No Exercise)': 'sedentary',
    'Lightly Active (1-3 days/week)': 'lightly_active',
    'Moderately Active (3-5 days/week)': 'moderately_active',
    'Very Active (6-7 days/week)': 'very_active',
    'Extra Active (Physical Job)': 'extra_active',
  };

  @override
  void dispose() {
    _pageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _stepGoalCtrl.dispose();
    _calorieGoalCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    // 🔥 FRONTEND VALIDATION - Page 1 (Biometrics)
    if (_currentPage == 1) {
      final height = double.tryParse(_heightCtrl.text) ?? 0;
      final weight = double.tryParse(_weightCtrl.text) ?? 0;

      if (height < 50 || height > 300) {
        _showError('Height must be between 50 and 300 cm');
        return;
      }
      if (weight < 20 || weight > 500) {
        _showError('Weight must be between 20 and 500 kg');
        return;
      }
    }

    // 🔥 FRONTEND VALIDATION - Page 2 (Goals)
    if (_currentPage == 2) {
      final steps = int.tryParse(_stepGoalCtrl.text) ?? 0;
      final cals = int.tryParse(_calorieGoalCtrl.text) ?? 0;

      if (steps < 1000 || steps > 100000) {
        _showError('Step goal must be between 1000 and 100,000');
        return;
      }
      if (cals < 500 || cals > 10000) {
        _showError('Calorie goal must be between 500 and 10,000');
        return;
      }

      // If validation passes on the last page, submit!
      _submitData();
      return;
    }

    // Proceed to the next page if not on the last page
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        )
    );
  }

  Future<void> _submitData() async {
    setState(() => _isSaving = true);

    try {
      // Sending data to your FastAPI backend
      await _dio.put(
          ApiConstants.profile,
          data: {
            'gender': _gender,
            'date_of_birth': _dob?.toIso8601String(),
            'height_cm': double.tryParse(_heightCtrl.text),
            'weight_kg': double.tryParse(_weightCtrl.text),
            'daily_step_goal': int.tryParse(_stepGoalCtrl.text),
            'daily_calorie_goal': int.tryParse(_calorieGoalCtrl.text),
            'activity_level': _activityLevel,
          }
      ).timeout(const Duration(seconds: 10)); // Prevents infinite hanging

      // ✅ SUCCESS! Tell the AuthBloc we are done.
      // The router will catch this and instantly push you to the Dashboard.
      if (mounted) {
        widget.onComplete();
      }

    } on DioException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('API Error 🚨'),
            content: Text('Status: ${e.response?.statusCode}\n\nData: ${e.response?.data}'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('App Error 🚨'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleBack() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Web-safe constraint
            child: Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildBasicInfoStep(),
                      _buildBiometricsStep(),
                      _buildGoalsStep(),
                    ],
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRACKMATE',
              style: TextStyle(color: Color(0xFF427AFA), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage ? const Color(0xFF427AFA) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? TextButton.icon(
            onPressed: _isSaving ? null : _handleBack,
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            label: const Text('Back', style: TextStyle(color: Colors.grey, fontSize: 16)),
          )
              : const SizedBox(width: 80),

          SizedBox(
            width: 140, // Strict bounds so it doesn't infinite-width crash on web
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF427AFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              )
                  : Text(_currentPage == 2 ? 'Complete' : 'Next >', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Let's get started", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tell us about yourself.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 40),
        const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gender,
              isExpanded: true,
              items: _genderOptions.entries.map((entry) => DropdownMenuItem<String>(value: entry.value, child: Text(entry.key))).toList(),
              onChanged: (val) => setState(() => _gender = val!),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Date of Birth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(1995),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
            );
            if (picked != null) setState(() => _dob = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select Date', style: const TextStyle(fontSize: 16)),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricsStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Your measurements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Used to accurately calculate your calorie needs.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 40),
        const Text('Height (cm)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _heightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            hintText: 'e.g. 175',
          ),
        ),
        const SizedBox(height: 24),
        const Text('Weight (kg)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            hintText: 'e.g. 70',
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Set your goals', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("We'll track your daily progress towards these metrics.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 40),
        const Text('Activity Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activityLevel,
              isExpanded: true,
              items: _activityOptions.entries.map((entry) => DropdownMenuItem<String>(value: entry.value, child: Text(entry.key))).toList(),
              onChanged: (val) => setState(() => _activityLevel = val!),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Daily Step Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _stepGoalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Daily Calorie Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _calorieGoalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}