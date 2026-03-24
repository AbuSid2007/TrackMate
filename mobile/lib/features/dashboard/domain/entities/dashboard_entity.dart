class DashboardData {
  final int steps;
  final int stepGoal;
  final double stepPercentage;
  final int stepsRemaining;
  final double caloriesEaten;
  final double caloriesBurned;
  final double waterLitres;
  final double waterGoalLitres;
  final double waterPercentage;
  final int streakDays;
  final int workoutsThisWeek;

  const DashboardData({
    required this.steps,
    required this.stepGoal,
    required this.stepPercentage,
    required this.stepsRemaining,
    required this.caloriesEaten,
    required this.caloriesBurned,
    required this.waterLitres,
    required this.waterGoalLitres,
    required this.waterPercentage,
    required this.streakDays,
    required this.workoutsThisWeek,
  });

  factory DashboardData.empty() => const DashboardData(
        steps: 0,
        stepGoal: 10000,
        stepPercentage: 0,
        stepsRemaining: 10000,
        caloriesEaten: 0,
        caloriesBurned: 0,
        waterLitres: 0,
        waterGoalLitres: 2.5,
        waterPercentage: 0,
        streakDays: 0,
        workoutsThisWeek: 0,
      );
}