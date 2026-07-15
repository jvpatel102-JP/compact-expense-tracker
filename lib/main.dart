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
            primaryColor: const Color(0xFF6366F1),
            scaffoldBackgroundColor: const Color(0xFF12141C),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.white, fontSize: 13),
                bodyMedium: const TextStyle(color: Colors.white70, fontSize: 12),
                titleMedium: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFF10B981),
              surface: Color(0xFF1E2230),
              background: const Color(0xFF12141C),
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
