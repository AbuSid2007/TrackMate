import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../../core/di/injection.dart';

class PedometerService {
  final _controller = StreamController<int>.broadcast();
  StreamSubscription<StepCount>? _subscription;
  Timer? _syncTimer;

  int _initialHardwareSteps = -1;
  int _stepsAlreadySavedOnBackend = 0;
  int _currentLiveTotal = 0;

  Stream<int> get steps => _controller.stream;

  Future<void> start() async {
    if (kIsWeb) return;

    var status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      // 1. Fetch what the backend already has saved for today
      try {
        final res = await sl<Dio>().get('/api/v1/fitness/steps/summary');
        _stepsAlreadySavedOnBackend = (res.data['steps'] as num?)?.toInt() ?? 0;
        _currentLiveTotal = _stepsAlreadySavedOnBackend;
        _controller.add(_currentLiveTotal); // Immediately broadcast the saved steps
      } catch (e) {
        debugPrint("Failed to fetch initial steps: $e");
      }

      // 2. Start listening to hardware pedometer
      _subscription = Pedometer.stepCountStream.listen(
            (StepCount event) {
          if (_initialHardwareSteps == -1) {
            _initialHardwareSteps = event.steps; // Set baseline
          }

          // Calculate steps taken *during this active app session*
          int sessionSteps = event.steps - _initialHardwareSteps;

          // Add them to the backend total
          _currentLiveTotal = _stepsAlreadySavedOnBackend + sessionSteps;
          _controller.add(_currentLiveTotal);
        },
      );

      // 3. SILENT SYNC: Send the grand total to backend every 30 seconds
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (_currentLiveTotal > _stepsAlreadySavedOnBackend) {
          try {
            await sl<Dio>().post('/api/v1/fitness/steps', data: {'steps': _currentLiveTotal});
            debugPrint("Silently synced $_currentLiveTotal steps");
          } catch (_) {}
        }
      });

    }
  }

  void dispose() {
    _subscription?.cancel();
    _syncTimer?.cancel();
    _controller.close();
  }
}