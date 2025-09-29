// lib/screens/natpac_app/natpac_trip_detector_tab.dart
import 'package:flutter/material.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart'; // Assuming AppColors is here
import '../../utils/trip_detector.dart';
import 'package:geolocator/geolocator.dart';

class NatpacTripDetectorTab extends StatefulWidget {
  const NatpacTripDetectorTab({super.key});
  @override
  State<NatpacTripDetectorTab> createState() => _NatpacTripDetectorTabState();
}

class _NatpacTripDetectorTabState extends State<NatpacTripDetectorTab> {
  final TripDetector _tripDetector = TripDetector();
  List<Map<String, dynamic>> _tripLogs = [];
  String _currentState = 'Initializing...';
  String? _errorMessage;

  // v-- PASTE THE NEW FUNCTION HERE --v
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(
        () => _errorMessage =
            'Location services are disabled. Please enable them in your settings.',
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () => _errorMessage =
            'Location permissions are permanently denied, we cannot request permissions.',
      );
      return false;
    }

    // If we get here, permissions are granted
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initTripDetector();
  }

  @override
  void dispose() {
    _tripDetector.stopListening();
    super.dispose();
  }

  // v-- REPLACE your old _initTripDetector with this new one --v
  Future<void> _initTripDetector() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return; // Stop if permissions are not granted

      // This part remains the same
      await _tripDetector.init();
      _tripDetector.startListening(
        onLogUpdate: (log) {
          if (mounted) setState(() => _tripLogs = log.reversed.toList());
        },
        onStateChange: (state) {
          if (mounted) {
            setState(() => _currentState = state.toString().split('.').last);
          }
        },
      );
      if (mounted) {
        setState(
          () => _currentState = _tripDetector.state.toString().split('.').last,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method code goes here.
    // No changes are needed in the build method.
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Current State: $_currentState',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _tripLogs.isEmpty && _currentState != 'active'
                      ? const Center(
                          child: Text(
                            'Move to start a trip...',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tripLogs.length,
                          itemBuilder: (context, index) {
                            final log = _tripLogs[index];
                            return ListTile(
                              title: Text('Mode: ${log['mode']}'),
                              subtitle: Text(
                                'Time: ${log['time'].toString().substring(11, 19)} | Location: ${log['lat'].toStringAsFixed(4)}, ${log['lon'].toStringAsFixed(4)}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
