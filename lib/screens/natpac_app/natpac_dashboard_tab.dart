import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart'; // For AppColors

enum TripType { busTrip, mobileTrip, footfallTrip }

class NatpacDashboardTab extends StatefulWidget {
  const NatpacDashboardTab({super.key});

  @override
  State<NatpacDashboardTab> createState() => _NatpacDashboardTabState();
}

class _NatpacDashboardTabState extends State<NatpacDashboardTab> {
  List<String> _displayHeaders = [];
  List<List<dynamic>> _displayRows = [];
  bool _isLoading = true;
  String? _errorMessage;

  TripType _currentTripType = TripType.busTrip;

  @override
  void initState() {
    super.initState();
    _loadData(_currentTripType);
  }

  // Generic method to load data based on the selected type
  Future<void> _loadData(TripType type) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data;

      switch (type) {
        case TripType.busTrip:
          data = await supabase
              .from('bus_ridership')
              .select('bus_id, route, passenger_count');
          _updateTableData(data, ['Bus ID', 'Route', 'Passenger Count']);
          break;
        case TripType.mobileTrip:
          data = await supabase
              .from('mobile_trips')
              .select('id, activity_type, timestamp');
          _updateTableData(data, ['ID', 'Activity Type', 'Timestamp']);
          break;
        case TripType.footfallTrip:
          data = await supabase
              .from('footfall_reports')
              .select('location_id, location_name, footfall_count');
          _updateTableData(data, [
            'Location ID',
            'Location Name',
            'Footfall Count',
          ]);
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
        });
      }
      debugPrint('Error fetching data from Supabase: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateTableData(List<dynamic> data, List<String> headers) {
    _displayHeaders = headers;

    _displayRows = data.map<List<dynamic>>((row) {
      return row.values.toList();
    }).toList();
  }

  // New method to get the dynamic dashboard title
  String _getDashboardTitle() {
    switch (_currentTripType) {
      case TripType.busTrip:
        return 'Bus Ridership Dashboard';
      case TripType.mobileTrip:
        return 'Mobile Trips Dashboard';
      case TripType.footfallTrip:
        return 'Footfall Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderAndDropdown(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.primary,
                        ),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        columns: _displayHeaders
                            .map((header) => DataColumn(label: Text(header)))
                            .toList(),
                        rows: _displayRows.map((row) {
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((
                              Set<WidgetState> states,
                            ) {
                              if (_displayRows.indexOf(row) % 2 == 0) {
                                return Colors.grey.withOpacity(0.1);
                              }
                              return null;
                            }),
                            cells: row
                                .map(
                                  (cell) => DataCell(
                                    Text(
                                      cell.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderAndDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _getDashboardTitle(), // Now uses the dynamic title getter
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        DropdownButton<TripType>(
          value: _currentTripType,
          items: const [
            DropdownMenuItem(value: TripType.busTrip, child: Text('Bus Trips')),
            DropdownMenuItem(
              value: TripType.mobileTrip,
              child: Text('Mobile Trips'),
            ),
            DropdownMenuItem(
              value: TripType.footfallTrip,
              child: Text('Footfall'),
            ),
          ],
          onChanged: (TripType? newValue) {
            if (newValue != null && newValue != _currentTripType) {
              setState(() {
                _currentTripType = newValue;
              });
              _loadData(newValue);
            }
          },
        ),
      ],
    );
  }
}
