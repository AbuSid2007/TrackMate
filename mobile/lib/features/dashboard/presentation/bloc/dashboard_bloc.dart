import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRemoteDataSource dataSource;
  final Dio dio;

  DashboardBloc({required this.dataSource, required this.dio})
      : super(const DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<DashboardLogWater>(_onLogWater);
  }

  Future<void> _onLoad(
    DashboardLoad event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final results = await Future.wait([
        dataSource.getStepsSummary(),
        dataSource.getNutritionSummary(),
        dataSource.getHydrationSummary(),
        dataSource.getWeeklyStats(),
        dataSource.getStreak(),
      ]);

      final steps = results[0] as Map<String, dynamic>;
      final nutrition = results[1] as Map<String, dynamic>;
      final hydration = results[2] as Map<String, dynamic>;
      final weekly = results[3] as Map<String, dynamic>;
      final streak = results[4] as int;

      emit(DashboardLoaded(DashboardData(
        steps: (steps['steps'] as num).toInt(),
        stepGoal: (steps['goal'] as num).toInt(),
        stepPercentage: (steps['percentage'] as num).toDouble(),
        stepsRemaining: (steps['remaining'] as num).toInt(),
        caloriesEaten: (nutrition['total_calories'] as num).toDouble(),
        caloriesBurned: ((weekly['calories_burned'] ?? 0) as num).toDouble(),
        waterLitres: (hydration['total_l'] as num).toDouble(),
        waterGoalLitres: ((hydration['goal_ml'] as num) / 1000).toDouble(),
        waterPercentage: (hydration['percentage'] as num).toDouble(),
        streakDays: streak,
        workoutsThisWeek: (weekly['workouts_completed'] as num).toInt(),
      )));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onLogWater(
    DashboardLogWater event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await dio.post(ApiConstants.hydration, data: {'amount_ml': event.amountMl});
      add(const DashboardLoad());
    } catch (_) {}
  }
}