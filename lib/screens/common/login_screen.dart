import 'package:flutter/material.dart';
//import 'package:lucide_flutter/lucide_flutter.dart';//

// --- UPDATED: New AppColors to match your design ---
class AppColors {
  static const Color primary = Color(0xFF1193d4);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color textLight = Color(0xFF101c22);
  static const Color primaryTransparent =
      Color(0x331193d4); // Primary with ~20% opacity
}
// --- END UPDATE ---

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- NEW: Using your provided app logo ---
                // Note: Make sure you add 'assets/images/app_logo.png' to your pubspec.yaml
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 24),

                // --- CHANGED: Title updated to match design ---
                const Text(
                  'Nagara Sancharam',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Welcome! Please select your role to continue to the application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 60),

                // --- Buttons now use the new _RoleButton design ---
                _RoleButton(
                  text: 'User App',
                  isPrimary: true,
                  onPressed: () {
                    // This will take the user to the onboarding/login flow for users
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  },
                ),
                const SizedBox(height: 16),

                _RoleButton(
                  text: 'NATPAC Professional',
                  isPrimary: false,
                  onPressed: () {
                    Navigator.pushNamed(context, '/natpac-login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: Rebuilt button widget to perfectly match the new UI ---
class _RoleButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.text,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.primary : AppColors.primaryTransparent,
          foregroundColor: isPrimary ? Colors.white : AppColors.primary,
          elevation: isPrimary ? 5 : 0, // Add shadow only to primary button
          padding:
              const EdgeInsets.symmetric(vertical: 18), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // More rounded corners
          ),
          shadowColor: isPrimary
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
