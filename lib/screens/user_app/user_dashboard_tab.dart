import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart'; // For AppColors

class UserDashboardTab extends StatelessWidget {
  // 1. ADD THIS VARIABLE TO HOLD THE FUNCTION
  final VoidCallback onViewRewards;

  // 2. UPDATE THE CONSTRUCTOR TO ACCEPT THE FUNCTION
  const UserDashboardTab({super.key, required this.onViewRewards});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPointsCard(),
        const SizedBox(height: 24),
        _buildRewardProgress(),
        const SizedBox(height: 24),
        _buildRecentTrips(),
        const SizedBox(height: 24),

        // 3. THIS BUTTON NOW WORKS CORRECTLY
        ElevatedButton(
          onPressed: onViewRewards,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Rewards Store',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Points', style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 4),
          Text(
            '1,250',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardProgress() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next Reward',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            Text(
              '1,500 points',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: LinearProgressIndicator(
            value: 0.75,
            minHeight: 10,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTrips() {
    final List<Map<String, String>> trips = [
      {'points': '120', 'route': 'Kochi to Ernakulam'},
      {'points': '150', 'route': 'Thrissur to Palakkad'},
      {'points': '180', 'route': 'Kozhikode to Kannur'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppColors.primary),
              ),
              title: Text(
                '${trips[index]['points']} Points',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(trips[index]['route']!),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
      ],
    );
  }
}
