import 'package:flutter/material.dart';
import 'main_layout.dart'; // Add this line!

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // State variables for user data
  String _gender = 'Male';
  double _height = 170;
  double _weight = 70;
  double _age = 25;
  String _selectedGoal = '';

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Final complete action
      // Final complete action
      if (_selectedGoal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a goal first!")));
        return;
      }

      // NEW: Navigate to the Main Layout!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainLayout()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Setup Complete! Ready to track.")));
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRACKMATE',
                      style: TextStyle(
                          color: Color(0xFF427AFA),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF427AFA)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Step ${_currentPage + 1} of 3',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Swipeable Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStepOne(),
                  _buildStepTwo(),
                  _buildStepThree(),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _currentPage == 0 ? null : _prevPage,
                    icon: const Icon(Icons.chevron_left, color: Colors.grey),
                    label: const Text('Back',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427AFA),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_currentPage == 2 ? 'Complete' : 'Next >',
                        style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- STEP 1: Body Metrics ---
  Widget _buildStepOne() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Let's get started",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Tell us about your body metrics",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          // Gender Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gender',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    isExpanded: true,
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) =>
                        setState(() => _gender = newValue!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Height Slider
          _buildSliderRow('Height (cm)', _height, 'cm', 100, 250, (val) {
            setState(() => _height = val);
          }),
          const SizedBox(height: 24),

          // Weight Slider
          _buildSliderRow('Weight (kg)', _weight, 'kg', 30, 150, (val) {
            setState(() => _weight = val);
          }),
        ],
      ),
    );
  }

  // --- STEP 2: Age ---
  Widget _buildStepTwo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("What's your age?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("This helps us personalize your plan",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          _buildSliderRow('Age', _age, 'years', 10, 100, (val) {
            setState(() => _age = val);
          }),
          const SizedBox(height: 32),

          // Large Age Display Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(_age.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold)),
                const Text('Years Old', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: Goals ---
  Widget _buildStepThree() {
    final goals = [
      {'title': 'Lose Weight', 'icon': '🔥'},
      {'title': 'Gain Muscle', 'icon': '💪'},
      {'title': 'Stay Fit', 'icon': '✨'},
      {'title': 'Build Endurance', 'icon': '🏃'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("What's your goal?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Choose your primary fitness objective",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),

          // Grid of Goals
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = _selectedGoal == goal['title'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedGoal = goal['title']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEDF2FE) : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF427AFA)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(goal['icon']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          goal['title']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF427AFA)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for rendering sliders with labels
  Widget _buildSliderRow(String label, double value, String unit, double min,
      double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${value.toInt()} $unit',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF427AFA),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: const Color(0xFF427AFA),
            overlayColor: const Color(0xFF427AFA).withOpacity(0.2),
            trackHeight: 6.0,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}