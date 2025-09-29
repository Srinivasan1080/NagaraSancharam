// lib/utils/trip_detector.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TripState { idle, active, ended, initializing }

class TripDetector {
  OrtSession? _session;
  final _labels = ['walk', 'two-wheeler', 'bus'];
  TripState state = TripState.initializing;
  final _log = Logger('TripDetector');
  void Function(List<Map<String, dynamic>>)? onLogUpdate;
  void Function(TripState)? onStateChange;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<Position>? _posSub;
  final List<double> _accelX = [], _accelY = [], _accelZ = [];
  List<Map<String, dynamic>> tripLog = [];
  DateTime? startTime;
  Position? startLocation;
  double lastLat = 0.0, lastLon = 0.0;
  DateTime? _lastMovingTime;
  final List<double> _speedBuffer = [];

  // --- FIX #1: Increased buffer size to smooth out GPS noise ---
  final int _speedBufferSize = 5; // Changed from 3 to 5

  final int samplesPerWindow = 50;
  final double startSpeedThreshold = 1.0;
  final double endSpeedThreshold = 0.5;
  final Duration stopDurationRequired = const Duration(minutes: 2);

  Future<void> init() async {
    _log.info('TripDetector init - calling initModel()');
    await initModel();
    state = TripState.idle;
    onStateChange?.call(state);
  }

  Future<void> initModel() async {
    try {
      _log.info('Loading ONNX model...');
      final sessionOptions = OrtSessionOptions();
      final rawAssetFile = await rootBundle.load(
        'assets/trip_mode_classifier.onnx',
      );
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _log.info('✅ ONNX model loaded successfully.');
    } catch (e, st) {
      _log.severe('Failed to load ONNX model: $e\n$st');
    }
  }

  Future<void> startListening({
    required void Function(List<Map<String, dynamic>>) onLogUpdate,
    required void Function(TripState) onStateChange,
  }) async {
    this.onLogUpdate = onLogUpdate;
    this.onStateChange = onStateChange;
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );
    _posSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          (pos) => _processGPS(pos),
          onError: (e) => _log.warning('GPS stream error: $e'),
        );

    _accelSub = accelerometerEventStream().listen(
      (evt) => _processAccel(evt.x, evt.y, evt.z),
      onError: (e) => _log.warning('Accelerometer stream error: $e'),
    );

    _log.info('Started sensors listening');
  }

  Future<void> stopListening() async {
    await _accelSub?.cancel();
    await _posSub?.cancel();
  }

  void _processAccel(double x, double y, double z) {
    _accelX.add(x);
    _accelY.add(y);
    _accelZ.add(z);
    if (_accelX.length >= samplesPerWindow) {
      final mean = _mean(_accelX, _accelY, _accelZ);
      final variance = _variance(_accelX, _accelY, _accelZ);
      final rms = _rms(_accelX, _accelY, _accelZ);
      _accelX.clear();
      _accelY.clear();
      _accelZ.clear();
      _runModelPredictionAndLog(mean, variance, rms);
    }
  }

  void _runModelPredictionAndLog(double mean, double variance, double rms) {
    if (_session == null) return;
    try {
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        [
          [mean, variance, rms],
        ],
        [1, 3],
      );
      final outputs = _session!.run(OrtRunOptions(), {'input': inputOrt});
      final probabilities = (outputs[0]?.value as List<List<double>>)[0];
      int maxIndex = 0;
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[maxIndex]) maxIndex = i;
      }
      final String label = _labels[maxIndex];

      if (state == TripState.active) {
        final entry = {
          'time': DateTime.now().toIso8601String(),
          'lat': lastLat,
          'lon': lastLon,
          'mode': label,
        };
        tripLog.add(entry);
        onLogUpdate?.call(tripLog);
        unawaited(_saveRealtimeLog(entry));
      }
      _log.info('ONNX Prediction: $label');
    } catch (e, st) {
      _log.severe('ONNX model prediction failed: $e\n$st');
    }
  }

  void _processGPS(Position pos) {
    // --- FIX #2: Ignore inaccurate GPS updates to prevent false starts ---
    if (pos.accuracy > 20) {
      _log.warning(
        'Ignoring inaccurate GPS reading. Accuracy: ${pos.accuracy}',
      );
      return;
    }

    final speed = pos.speed;
    _log.info(
      'GPS Update: Speed=${speed.toStringAsFixed(2)} m/s, Buffer=$_speedBuffer',
    );

    lastLat = pos.latitude;
    lastLon = pos.longitude;
    final now = DateTime.now();

    _speedBuffer.add(speed);
    if (_speedBuffer.length > _speedBufferSize) {
      _speedBuffer.removeAt(0);
    }

    if (state == TripState.idle) {
      if (_speedBuffer.length == _speedBufferSize) {
        final double averageSpeed =
            _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;
        _log.info(
          'Checking average speed: ${averageSpeed.toStringAsFixed(2)} m/s',
        );
        if (averageSpeed >= startSpeedThreshold) {
          state = TripState.active;
          startTime = now;
          startLocation = pos;
          tripLog = [];
          _lastMovingTime = now;
          onStateChange?.call(state);
          _log.info('🚀 Trip started (average speed threshold met)');
        }
      }
    } else if (state == TripState.active) {
      if (speed >= endSpeedThreshold) {
        _lastMovingTime = now;
      } else if (_lastMovingTime != null &&
          now.difference(_lastMovingTime!) >= stopDurationRequired) {
        state = TripState.ended;
        onStateChange?.call(state);
        _log.info('🛑 Trip ended (stopped for 2 minutes)');
        unawaited(_saveTrip(pos));
      }
    } else if (state == TripState.ended) {
      state = TripState.idle;
      _speedBuffer.clear();
      onStateChange?.call(state);
    }
  }

  double _mean(List<double> x, List<double> y, List<double> z) {
    if (x.isEmpty) return 0.0;
    final List<double> mags = [];
    for (int i = 0; i < x.length; i++) {
      mags.add(sqrt(pow(x[i], 2) + pow(y[i], 2) + pow(z[i], 2)));
    }
    return mags.reduce((a, b) => a + b) / mags.length;
  }

  double _variance(List<double> x, List<double> y, List<double> z) {
    if (x.isEmpty) return 0.0;
    final List<double> mags = [];
    for (int i = 0; i < x.length; i++) {
      mags.add(sqrt(pow(x[i], 2) + pow(y[i], 2) + pow(z[i], 2)));
    }
    final mean = mags.reduce((a, b) => a + b) / mags.length;
    final sumOfSquares = mags
        .map((m) => pow(m - mean, 2))
        .reduce((a, b) => a + b);
    return sumOfSquares / mags.length;
  }

  double _rms(List<double> x, List<double> y, List<double> z) {
    if (x.isEmpty) return 0.0;
    final List<double> mags = [];
    for (int i = 0; i < x.length; i++) {
      mags.add(sqrt(pow(x[i], 2) + pow(y[i], 2) + pow(z[i], 2)));
    }
    final sumOfSquares = mags.map((m) => pow(m, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / mags.length);
  }

  Future<void> _saveTrip(Position endPos) async {
    final user = Supabase.instance.client.auth.currentUser;
    // --- FIX #3: Added loud failure if user is not logged in ---
    if (user == null) {
      _log.severe('Cannot save trip. User is not logged in.');
      return;
    }

    try {
      await Supabase.instance.client.from('trips').insert([
        {
          'user_id': user.id,
          'start_time': startTime!.toIso8601String(),
          'end_time': DateTime.now().toIso8601String(),
          'start_lat': startLocation!.latitude,
          'start_lon': startLocation!.longitude,
          'end_lat': endPos.latitude,
          'end_lon': endPos.longitude,
          'path': tripLog,
        },
      ]);
      _log.info('✅ Trip saved to Supabase');
    } catch (e) {
      _log.severe('Failed to save trip: $e');
    } finally {
      startTime = null;
      startLocation = null;
      state = TripState.idle;
      onStateChange?.call(state);
    }
  }

  Future<void> _saveRealtimeLog(Map<String, dynamic> log) async {
    final user = Supabase.instance.client.auth.currentUser;
    // --- FIX #3: Added loud failure if user is not logged in ---
    if (user == null) {
      _log.severe('Cannot save log. User is not logged in.');
      return;
    }

    final logWithUser = Map<String, dynamic>.from(log)..['user_id'] = user.id;

    try {
      await Supabase.instance.client.from('trip_logs').insert([logWithUser]);
    } catch (e) {
      _log.warning('Failed realtime log save: $e');
    }
  }
}

void unawaited(Future<void> f) {}
