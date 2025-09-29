import 'package:flutter/material.dart';
import 'package:mobility_sense_new/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobility_sense_new/screens/common/login_screen.dart';
import 'package:mobility_sense_new/screens/common/onboarding_screen.dart';
import 'package:mobility_sense_new/screens/common/splash_screen.dart';
import 'package:mobility_sense_new/screens/user_app/user_shell_screen.dart';

// FIX: Added the missing imports for the NATPAC screens
import 'package:mobility_sense_new/screens/natpac_app/natpac_login_screen.dart';
import 'package:mobility_sense_new/screens/natpac_app/natpac_shell_screen.dart';

// Your Supabase credentials
const String supabaseUrl = 'https://wfwripzbcdlrgoocwhog.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indmd3JpcHpiY2Rscmdvb2N3aG9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxNjY1MjIsImV4cCI6MjA3Mzc0MjUyMn0.YnKmKaBg2u6xx6ybQHVYDH6xJTiDu2ZvNHKaXUmBBko';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MobilitySenseApp(),
    ),
  );
}

class MobilitySenseApp extends StatelessWidget {
  const MobilitySenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MobilitySense',
          // --- UPDATED LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            fontFamily: 'Roboto',
            cardTheme: CardThemeData(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87),
              bodyMedium: TextStyle(color: Colors.black54),
              titleLarge: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            listTileTheme: const ListTileThemeData(
              iconColor: Colors.deepPurple,
            ),
          ),
          // --- UPDATED DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Roboto',
            cardTheme: CardThemeData(
              elevation: 3,
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            listTileTheme: ListTileThemeData(
              iconColor: Colors.deepPurple.shade200,
            ),
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/user-dashboard': (context) => const UserShellScreen(),
            '/natpac-login': (context) => const NatpacLoginScreen(),
            '/natpac-dashboard': (context) => const NatpacShellScreen(),
          },
        );
      },
    );
  }
}
