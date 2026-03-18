// lib/exercise_log_model.dart

// Model for a single set log entry
class ExerciseLogSet {
  final int setNumber;
  final int reps;
  final double weight;
  final String unit; // 'lbs' or 'kg'

  ExerciseLogSet({required this.setNumber, required this.reps, required this.weight, this.unit = 'lbs'});
}

// Model to hold summary volume data for the day
class ExerciseVolumeModel {
  int totalSets = 0;
  int totalReps = 0;
  double totalVolume = 0.0;
  String unit = 'lbs';

  void addSet(ExerciseLogSet set) {
    totalSets++;
    totalReps += set.reps;
    totalVolume += (set.reps * set.weight);
  }
}