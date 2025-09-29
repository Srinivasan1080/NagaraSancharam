import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart';
import 'package:mobility_sense_new/screens/natpac_app/natpac_dashboard_tab.dart';
import 'package:mobility_sense_new/screens/natpac_app/natpac_map_view_screen.dart';
import 'package:mobility_sense_new/screens/natpac_app/natpac_trip_detector_tab.dart'; // Import the new tab

class NatpacShellScreen extends StatefulWidget {
  const NatpacShellScreen({super.key});

  @override
  State<NatpacShellScreen> createState() => _NatpacShellScreenState();
}

class _NatpacShellScreenState extends State<NatpacShellScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _widgetOptions = <Widget>[
    const NatpacDashboardTab(),
    const NatpacMapViewScreen(),
    const NatpacTripDetectorTab(), // Use the new Trip Detector tab here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? 'Dashboard'
              : _selectedIndex == 1
              ? 'Map View'
              : 'Trip Detector', // Dynamic title based on selection
          style: const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, color: AppColors.textLight),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: const Drawer(child: Center(child: Text("Navigation Menu"))),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.map),
            label: 'Map View',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              LucideIcons.bike,
            ), // Changed icon to represent the new tab
            label: 'Trip Detector', // Changed label for the new tab
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
