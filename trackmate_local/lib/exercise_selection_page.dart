// lib/exercise_selection_page.dart
import 'package:flutter/material.dart';
import 'main_layout.dart'; // We need to access MainLayout.checkLoginAndDo
import 'gym_session_page.dart';
import 'running_page.dart';
import 'yoga_page.dart';

class ExerciseSelectionPage extends StatelessWidget {
  const ExerciseSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Track your workouts', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),

          // Row of three exercise types
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Running Option
              _buildExerciseCard(
                context,
                icon: '🏃',
                title: 'Running',
                description: 'Track your cardio\nsession',
                onTap: () {
                  checkLoginAndDo(context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RunningPage()));
                  });
                },
              ),

              // 2. Gym Option - This triggers the login check!
              _buildExerciseCard(
                context,
                icon: '💪',
                title: 'Gym',
                description: 'Log sets, reps, and\nweight',
                onTap: () {
                  // HERE WE USE THE CONDITIONAL LOGIN!
                  // It will only execute the code in the callback (navigating to Gym Session)
                  // after verifying a local login exists or showing the popup.
                  checkLoginAndDo(context, () {
                    // This is the intended action after successful "login"
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GymSessionPage()),
                    );
                  });
                },
              ),

              // 3. Yoga Option
              _buildExerciseCard(
                context,
                icon: '🧘',
                title: 'Yoga',
                description: 'Track your practice\ntime',
                onTap: () {
                  checkLoginAndDo(context, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const YogaPage()));
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Private helper to build individual exercise tiles
  Widget _buildExerciseCard(BuildContext context, {required String icon, required String title, required String description, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // No border needed, white card on white background works
          ),
          child: Column(
            children: [
              // Circular background for the icon
              CircleAvatar(backgroundColor: Colors.grey.shade100, radius: 30, child: Text(icon, style: const TextStyle(fontSize: 24)),),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 4),
              Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12),),
            ],
          ),
        ),
      ),
    );
  }
}