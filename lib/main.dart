import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketReceiptApp());
}

class PocketReceiptApp extends StatelessWidget {
  const PocketReceiptApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PocketReceipt',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F7F2),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF246B52),
        primary: const Color(0xFF246B52),
        surface: const Color(0xFFF6F7F2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F7F2),
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE5DD)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF193B2F)),
        bodyLarge: TextStyle(color: Color(0xFF193B2F)),
      ),
    ),
    home: const HomeScreen(),
  );
}
