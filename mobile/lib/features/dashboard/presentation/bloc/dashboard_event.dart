import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoad extends DashboardEvent {
  const DashboardLoad();
}

class DashboardLogWater extends DashboardEvent {
  final int amountMl;
  const DashboardLogWater(this.amountMl);
  @override
  List<Object?> get props => [amountMl];
}