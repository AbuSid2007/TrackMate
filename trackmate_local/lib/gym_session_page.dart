// lib/gym_session_page.dart
import 'dart:async'; // Need this for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Need this for custom text input
import 'exercise_log_model.dart';
import 'main_layout.dart'; // We need to access MainLayout.checkLoginAndDo

class GymSessionPage extends StatefulWidget {
  const GymSessionPage({super.key});

  @override
  State<GymSessionPage> createState() => _GymSessionPageState();
}

class _GymSessionPageState extends State<GymSessionPage> {

  // ================= State Variables =================

  // 1. Timer State
  Duration _duration = const Duration();
  Timer? _timer;
  bool _isTimerPaused = false;

  // 2. Input State (Reps & Weight controllers and numpad management)
  final TextEditingController _repsController = TextEditingController(text: '0');
  final TextEditingController _weightController = TextEditingController(text: '0');

  // Custom focus to handle numpad input easily
  final FocusNode _repsFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  // 3. Logged Sets State
  final List<ExerciseLogSet> _todaySetsLog = [];
  final ExerciseVolumeModel _volumeSummary = ExerciseVolumeModel();

  // ================= Lifecycle Methods =================

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start timer immediately on enter
  }

  @override
  void dispose() {
    _timer?.cancel(); // Important to stop the timer when leaving!
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ================= Timer Logic =================

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerPaused) {
        setState(() {
          final seconds = _duration.inSeconds + 1;
          _duration = Duration(seconds: seconds);
        });
      }
    });
  }

  void _pauseResumeTimer() {
    setState(() {
      _isTimerPaused = !_isTimerPaused;
    });
  }

  void _endSession() {
    _timer?.cancel();
    // In real app, you would save final data to database
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session ended. Saving final data Online...")));
    Navigator.pop(context); // Go back to Exercise Selection
  }

  // Helper method to format Duration (HH:MM:SS)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // ================= Custom Numpad Input Logic =================

  // Private helper to inject numpad values into text fields
  void _inputNumber(TextEditingController controller, String value) {
    String currentText = controller.text;

    // Clear logic (special key "Clear")
    if (value == 'Clear') {
      controller.text = '0';
      return;
    }

    // Decimal point logic: only one decimal point allowed for weight
    if (value == '.') {
      if (currentText.contains('.')) {
        return; // Don't add a second decimal point
      }
    }

    // Prevent '00' or leading zeroes that make no sense
    if (currentText == '0' && value != '.') {
      controller.text = value; // Replace leading zero
    } else {
      controller.text = currentText + value; // Append
    }
  }

  // Private helper to handle deleting last digit (backspace - unused key in mockup but essential)
  void _backspace(TextEditingController controller) {
    String currentText = controller.text;
    if (currentText.length > 1) {
      controller.text = currentText.substring(0, currentText.length - 1);
    } else if (currentText.length == 1) {
      controller.text = '0';
    }
  }

  // ================= Logging Sets Logic =================

  void _addSet() {
    // HERE WE RE-ENFORCE THE LOGIN POPUP!
    // Even adding a new set must verify login.
    checkLoginAndDo(context, () {
      // The intended action: parse the inputs, log the set locally, clear inputs

      // Parse inputs (safely - default to 0 if parsing fails)
      int reps = int.tryParse(_repsController.text) ?? 0;
      double weight = double.tryParse(_weightController.text) ?? 0.0;

      // Basic validation
      if (reps <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reps must be greater than zero.")));
        return;
      }

      setState(() {
        // Create the new set
        final newSet = ExerciseLogSet(
          setNumber: _todaySetsLog.length + 1,
          reps: reps,
          weight: weight,
          // (real app would have a lbs/kg selector)
        );

        // Update state: add set to log, update volume summary
        _todaySetsLog.add(newSet);
        _volumeSummary.addSet(newSet);

        // Clear input fields
        _repsController.text = '0';
        _weightController.text = '0';

        // Shift focus back to reps for the next set
        _repsFocusNode.requestFocus();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Set Online logged! Data saved to Local DB & pushed to cloud.")));
    });
  }

  // ================= Main UI Builder =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Workout Session', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Blue Timer Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF427AFA), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Text('Gym Session', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 12),
                  // The live timer display
                  Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),),
                  const SizedBox(height: 24),
                  // Timer Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/Resume Button
                      ElevatedButton.icon(
                        onPressed: _pauseResumeTimer,
                        icon: Icon(_isTimerPaused ? Icons.play_arrow : Icons.pause_outlined),
                        label: Text(_isTimerPaused ? 'Resume' : 'Pause'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF427AFA),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // End Session Button
                      ElevatedButton.icon(
                        onPressed: _endSession,
                        icon: const Icon(Icons.stop_circle_outlined, color: Colors.white,),
                        label: const Text('End Session', style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Log New Set Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Log New Set', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 16),

                  // Row with Reps and Weight input fields
                  Row(
                    children: [
                      // Reps input field
                      _buildInputField(
                        label: 'Reps',
                        controller: _repsController,
                        focusNode: _repsFocusNode,
                        suffix: '',
                      ),
                      const SizedBox(width: 16),
                      // Weight input field
                      _buildInputField(
                        label: 'Weight',
                        controller: _weightController,
                        focusNode: _weightFocusNode,
                        suffix: '(lbs)',
                        isWeightInput: true, // This allows the decimal point key later
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row of two custom keypads
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reps numpad
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Reps Keypad', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(height: 8),
                            _buildCustomNumpad(controller: _repsController, onInput: (v) => _inputNumber(_repsController, v),),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Weight numpad (has decimal key)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Weight Keypad (lbs)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(height: 8),
                            _buildCustomNumpad(controller: _weightController, onInput: (v) => _inputNumber(_weightController, v), hasDecimal: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add Set Button - Uses login check before proceeding
                  ElevatedButton(
                    onPressed: _addSet,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AFA), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('+ Add Set', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Today's Sets Section
            if (_todaySetsLog.isNotEmpty) // Only show if sets are logged
              _buildLoggedSetsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ================= UI Helper Methods =================

  // Private helper to build the Reps/Weight read-only text input fields
  Widget _buildInputField({required String label, required TextEditingController controller, required FocusNode focusNode, required String suffix, bool isWeightInput = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: true, // VERY IMPORTANT: disables system keyboard
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                Text(suffix, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Private helper to build individual numpad keys
  // Private helper to build individual numpad keys
  Widget _buildKeypadButton(String value, VoidCallback onTap, {bool isActionButton = false}) {
    Color buttonColor = isActionButton ? Colors.grey.shade100 : Colors.white;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2), // tight alignment from mockup
        child: AspectRatio(
          aspectRatio: 1.5, // rectangular buttons
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                elevation: 1, // subtle border shadow effect from mockup
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: EdgeInsets.zero
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                // FIXED: Using an inline ternary operator for the color
                color: value == 'Clear' ? Colors.red.shade400 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Private helper to layout the grid of keys for the numpad
  Widget _buildCustomNumpad({required TextEditingController controller, required ValueChanged<String> onInput, bool hasDecimal = false}) {
    // Create list of lists representing rows of keys
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['Clear', '0', if (hasDecimal) '.' else '' ] // '.' only on weight keypad
    ];

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows.map((row) {
        return TableRow(
          children: row.map((keyVal) {
            if (keyVal.isEmpty) return Container(); // handle potential empty bottom key
            return _buildKeypadButton(
              keyVal,
                  () => onInput(keyVal),
              // special keys use gray bg
              isActionButton: keyVal == 'Clear' || keyVal == '.',
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // Private helper to build the list of completed sets with summary at bottom
  Widget _buildLoggedSetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Today's Sets", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),

          // --- SETS LIST HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: Center(child: Text('Set', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Reps', style: TextStyle(color: Colors.grey)))),
              Expanded(child: Center(child: Text('Weight (lbs)', style: TextStyle(color: Colors.grey)))),
            ],
          ),
          const SizedBox(height: 8),

          // --- THE LIST OF SETS ---
          // We use spread operator ... to insert a list of widgets
          ..._todaySetsLog.map((set) => _buildSetsRow(set)).toList(),

          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),

          // --- SUMMARY STATS ---
          _buildSummaryRow('Total Sets', '${_volumeSummary.totalSets}'),
          _buildSummaryRow('Total Reps', '${_volumeSummary.totalReps}'),
          // Total Volume - formatted with no trailing zeros
          _buildSummaryRow('Total Volume', '${_volumeSummary.totalVolume.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} lbs'),
        ],
      ),
    );
  }

  // Row for an individual logged set in the list
  Widget _buildSetsRow(ExerciseLogSet set) {
    // gray background from mockup for alternating row effect
    Color bgColor = set.setNumber.isOdd ? Colors.grey.shade50 : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Expanded(child: Center(child: Text('${set.setNumber}', style: const TextStyle(fontWeight: FontWeight.bold)))),
          Expanded(child: Center(child: Text('${set.reps}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))),
          Expanded(child: Center(child: Text('${set.weight} lbs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))),
        ],
      ),
    );
  }

  // Final summary stats row
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}