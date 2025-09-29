import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart';
import 'package:mobility_sense_new/screens/user_app/rewards_screen.dart';
import 'package:mobility_sense_new/screens/user_app/user_dashboard_tab.dart';
import 'package:mobility_sense_new/screens/user_app/user_profile_screen.dart';

class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      UserDashboardTab(onViewRewards: () => _onItemTapped(1)),
      const RewardsScreen(),
      const UserSettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              // --- NEW: ADDED THE BACK BUTTON HERE ---
              leading: IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.textLight,
                ),
                onPressed: () {
                  // This will navigate to the role selection screen and clear all other screens from history.
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
              // --- END NEW ---
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.settings,
                    color: AppColors.textLight,
                  ),
                  onPressed: () => _onItemTapped(2),
                ),
              ],
            )
          : null,
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.gift),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.cog),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
