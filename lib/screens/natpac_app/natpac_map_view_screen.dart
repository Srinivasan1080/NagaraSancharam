import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum HeatmapType { busRidership, mobileTrips, footfall }

class NatpacMapViewScreen extends StatefulWidget {
  const NatpacMapViewScreen({super.key});

  @override
  State<NatpacMapViewScreen> createState() => _NatpacMapViewScreenState();
}

class _NatpacMapViewScreenState extends State<NatpacMapViewScreen> {
  GoogleMapController? _mapController;
  final String _googleApiKey = const String.fromEnvironment(
    'GOOGLE_API_KEY',
    defaultValue: "AIzaSyBvuG4VG81PlHg3hckeCM1u58k1TXYtxVs",
  );

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  places.Prediction? _origin;
  places.Prediction? _destination;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.8505, 76.2711),
    zoom: 7.5,
  );

  final Set<Heatmap> _busRidershipHeatmaps = {};
  final Set<Heatmap> _mobileTripsHeatmaps = {};
  final Set<Heatmap> _footfallHeatmaps = {};
  bool _isLoading = true;

  bool _heatmapVisible = true;
  MapType _currentMapType = MapType.normal;
  HeatmapType _currentHeatmapType = HeatmapType.busRidership;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _createBusRidershipHeatmapFromSupabase(),
      _createMobileTripsHeatmapFromSupabase(),
      _createFootfallHeatmapFromSupabase(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- DATA LOADING & HEATMAP CREATION (UNCHANGED) ---
  Future<void> _createBusRidershipHeatmapFromSupabase() async {
    final heatmapData = await _loadBusRidershipDataFromSupabase();
    if (mounted && heatmapData.isNotEmpty) {
      setState(() {
        _busRidershipHeatmaps.add(
          Heatmap(
            heatmapId: const HeatmapId('bus_ridership_heatmap'),
            data: heatmapData,
            radius: const HeatmapRadius.fromPixels(30),
            opacity: 0.8,
            gradient: const HeatmapGradient([
              HeatmapGradientColor(Colors.green, 0.2),
              HeatmapGradientColor(Colors.yellow, 0.5),
              HeatmapGradientColor(Colors.red, 1.0),
            ]),
          ),
        );
      });
    }
  }

  Future<List<WeightedLatLng>> _loadBusRidershipDataFromSupabase() async {
    final List<WeightedLatLng> points = [];
    try {
      final response = await supabase
          .from('bus_ridership')
          .select('latitude, longitude, passenger_count');

      for (final row in response) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        final count = row['passenger_count'];

        if (lat != null && lng != null && count != null) {
          points.add(
            WeightedLatLng(
              LatLng((lat as num).toDouble(), (lng as num).toDouble()),
              weight: (count as num).toDouble(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching bus ridership data from Supabase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load bus ridership data.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return points;
  }

  Future<void> _createMobileTripsHeatmapFromSupabase() async {
    final heatmapData = await _loadMobileTripsDataFromSupabase();
    if (mounted && heatmapData.isNotEmpty) {
      setState(() {
        _mobileTripsHeatmaps.add(
          Heatmap(
            heatmapId: const HeatmapId('mobile_trips_heatmap'),
            data: heatmapData,
            radius: const HeatmapRadius.fromPixels(25),
            opacity: 0.7,
            gradient: const HeatmapGradient([
              HeatmapGradientColor(Colors.blue, 0.2),
              HeatmapGradientColor(Colors.cyan, 0.5),
              HeatmapGradientColor(Colors.purple, 1.0),
            ]),
          ),
        );
      });
    }
  }

  Future<List<WeightedLatLng>> _loadMobileTripsDataFromSupabase() async {
    final List<WeightedLatLng> points = [];
    try {
      final response = await supabase
          .from('mobile_trips')
          .select('latitude, longitude');
      for (final row in response) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        if (lat != null && lng != null) {
          points.add(
            WeightedLatLng(
              LatLng((lat as num).toDouble(), (lng as num).toDouble()),
              weight: 1.0,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching mobile trips data from Supabase: $e');
    }
    return points;
  }

  Future<void> _createFootfallHeatmapFromSupabase() async {
    final heatmapData = await _loadFootfallDataFromSupabase();
    if (mounted && heatmapData.isNotEmpty) {
      setState(() {
        _footfallHeatmaps.add(
          Heatmap(
            heatmapId: const HeatmapId('footfall_heatmap'),
            data: heatmapData,
            radius: const HeatmapRadius.fromPixels(40),
            opacity: 0.8,
            maxIntensity: 1500.0,
            gradient: const HeatmapGradient([
              HeatmapGradientColor(Colors.lightBlue, 0.2),
              HeatmapGradientColor(Colors.orange, 0.6),
              HeatmapGradientColor(Colors.deepOrange, 1.0),
            ]),
          ),
        );
      });
    }
  }

  Future<List<WeightedLatLng>> _loadFootfallDataFromSupabase() async {
    final List<WeightedLatLng> points = [];
    try {
      final response = await supabase
          .from('footfall_reports')
          .select('latitude, longitude, footfall_count');

      for (final row in response) {
        final lat = row['latitude'];
        final lng = row['longitude'];
        final count = row['footfall_count'];
        if (lat != null && lng != null && count != null) {
          points.add(
            WeightedLatLng(
              LatLng((lat as num).toDouble(), (lng as num).toDouble()),
              weight: (count as num).toDouble(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching footfall data from Supabase: $e');
    }
    return points;
  }

  Set<Heatmap> _getActiveHeatmap() {
    switch (_currentHeatmapType) {
      case HeatmapType.busRidership:
        return _busRidershipHeatmaps;
      case HeatmapType.mobileTrips:
        return _mobileTripsHeatmaps;
      case HeatmapType.footfall:
        return _footfallHeatmaps;
    }
  }

  // --- MAIN BUILD METHOD (UNCHANGED) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            heatmaps: _heatmapVisible ? _getActiveHeatmap() : {},
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          _buildSearchBar(),
          _buildMapControls(),
          _buildLayersButton(),
          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Loading Map Data..."),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI WIDGETS ---
  Widget _buildSearchBar() {
    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: TextEditingController(),
              googleAPIKey: _googleApiKey,
              inputDecoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search),
                hintText: _origin == null
                    ? 'Search starting location'
                    : 'Search for a destination',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              debounceTime: 400,
              countries: const ["in"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                // **FIXED HERE**: Create a new Prediction object instead of modifying a final one.
                final p = places.Prediction(
                  description: prediction.description,
                  placeId: prediction.placeId,
                );

                if (_origin == null) {
                  setState(() => _origin = p);
                } else {
                  setState(() => _destination = p);
                  _getDirections();
                }
              },
              itemClick: (prediction) {},
            ),
          ),
          if (_origin != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Card(
                elevation: 2,
                child: ListTile(
                  title: Text("From: ${_origin!.description!}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _origin = null;
                      _destination = null;
                      _markers.clear();
                      _polylines.clear();
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: _origin == null ? 120 : 200,
      right: 16,
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                IconButton(
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  icon: const Icon(LucideIcons.plus),
                ),
                const Divider(height: 1),
                IconButton(
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  icon: const Icon(LucideIcons.minus),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: "locate_btn",
            onPressed: () {},
            elevation: 4,
            backgroundColor: Colors.white,
            child: const Icon(LucideIcons.locateFixed, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersButton() {
    return Positioned(
      bottom: 24,
      right: 16,
      child: FloatingActionButton.extended(
        heroTag: "layers_btn",
        onPressed: _showLayersBottomSheet,
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(LucideIcons.layers, color: Colors.white),
        label: const Text(
          'Layers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _showLayersBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Layers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Heatmap Layer'),
                  value: _heatmapVisible,
                  onChanged: (bool value) {
                    setState(() => _heatmapVisible = value);
                    setSheetState(() {});
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    'Heatmap Data Source',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<HeatmapType>(
                  title: const Text('Bus Ridership (Supabase)'),
                  value: HeatmapType.busRidership,
                  groupValue: _currentHeatmapType,
                  onChanged: (v) => setState(() {
                    _currentHeatmapType = v!;
                    setSheetState(() {});
                  }),
                ),
                RadioListTile<HeatmapType>(
                  title: const Text('Population Movement (Supabase)'),
                  value: HeatmapType.mobileTrips,
                  groupValue: _currentHeatmapType,
                  onChanged: (v) => setState(() {
                    _currentHeatmapType = v!;
                    setSheetState(() {});
                  }),
                ),
                RadioListTile<HeatmapType>(
                  title: const Text('Footfall Density (Supabase)'),
                  value: HeatmapType.footfall,
                  groupValue: _currentHeatmapType,
                  onChanged: (v) => setState(() {
                    _currentHeatmapType = v!;
                    setSheetState(() {});
                  }),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    'Map Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected: _currentMapType == MapType.normal,
                        onSelected: (s) {
                          if (s) {
                            setState(() => _currentMapType = MapType.normal);
                          }
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Satellite'),
                        selected: _currentMapType == MapType.satellite,
                        onSelected: (s) {
                          if (s) {
                            setState(() => _currentMapType = MapType.satellite);
                          }
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Terrain'),
                        selected: _currentMapType == MapType.terrain,
                        onSelected: (s) {
                          if (s) {
                            setState(() => _currentMapType = MapType.terrain);
                          }
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- LOGIC & HANDLERS ---
  Future<void> _getDirections() async {
    if (_googleApiKey.isEmpty ||
        _googleApiKey == "YOUR_GOOGLE_MAPS_API_KEY_HERE") {
      _showApiKeyMissingDialog();
      return;
    }

    if (_origin == null || _destination == null) return;

    final directionsApi = directions.GoogleMapsDirections(
      apiKey: _googleApiKey,
    );
    directions.DirectionsResponse res = await directionsApi.directions(
      "place_id:${_origin!.placeId!}",
      "place_id:${_destination!.placeId!}",
      travelMode: directions.TravelMode.driving,
    );

    if (res.isOkay && res.routes.isNotEmpty) {
      final route = res.routes.first;
      final leg = route.legs.first;
      final points = PolylinePoints().decodePolyline(
        route.overviewPolyline.points,
      );
      final polylineCoordinates = points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('origin'),
              position: LatLng(leg.startLocation.lat, leg.startLocation.lng),
              infoWindow: InfoWindow(title: leg.startAddress),
            ),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(leg.endLocation.lat, leg.endLocation.lng),
              infoWindow: InfoWindow(title: leg.endAddress),
            ),
          );
          // **FIXED HERE**: Corrected the syntax by removing the extra parenthesis.
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: Theme.of(context).primaryColor,
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                route.bounds.southwest.lat,
                route.bounds.southwest.lng,
              ),
              northeast: LatLng(
                route.bounds.northeast.lat,
                route.bounds.northeast.lng,
              ),
            ),
            50.0,
          ),
        );
      }
    }
  }

  void _showApiKeyMissingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Missing or Invalid'),
        content: const Text(
          'Please add your full, valid Google API key to the code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
