import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/bill_provider.dart';
import 'screens/assign_screen.dart';
import 'screens/pay_screen.dart';
import 'screens/people_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const BillSplitApp());
}

class BillSplitApp extends StatelessWidget {
  const BillSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BillProvider(),
      child: MaterialApp(
        title: 'BillSplit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD97706),
            primary: const Color(0xFFD97706),
            secondary: const Color(0xFF1E293B),
            surface: Colors.white,
            surfaceVariant: const Color(0xFFF1F5F9),
            background: const Color(0xFFFAFAFA),
          ),
          textTheme: GoogleFonts.dmSansTextTheme(Theme.of(context).textTheme).copyWith(
            displayMedium: GoogleFonts.syne(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
              letterSpacing: -1,
            ),
            headlineSmall: GoogleFonts.syne(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
            titleLarge: GoogleFonts.syne(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFF1E293B),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        initialRoute: ScanScreen.routeName,
        routes: {
          ScanScreen.routeName: (_) => const ScanScreen(),
          PeopleScreen.routeName: (_) => const PeopleScreen(),
          AssignScreen.routeName: (_) => const AssignScreen(),
          PayScreen.routeName: (_) => const PayScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),

        },
      ),
    );
  }
}
