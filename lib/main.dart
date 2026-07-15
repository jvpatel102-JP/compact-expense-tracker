import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/google_sheets_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the state provider
  final provider = GoogleSheetsProvider();

  runApp(ExpenseTrackerApp(provider: provider));
}

class ExpenseTrackerApp extends StatelessWidget {
  final GoogleSheetsProvider provider;

  const ExpenseTrackerApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Compact Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF3B82F6), // Ivy Wallet Blue
            scaffoldBackgroundColor: const Color(0xFF000000), // Pitch Black
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.white, fontSize: 13),
                bodyMedium: const TextStyle(color: Colors.white70, fontSize: 12),
                titleMedium: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            cardTheme: const CardTheme(
              color: Color(0xFF121212),
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              secondary: Color(0xFF10B981),
              surface: Color(0xFF121212),
              background: Color(0xFF000000),
              error: Color(0xFFEF4444),
            ),
            useMaterial3: true,
          ),
          home: DashboardScreen(provider: provider),
        );
      },
    );
  }
}
