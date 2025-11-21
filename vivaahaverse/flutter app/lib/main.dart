import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vivaahaverse/services/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  runApp(VivaahaApp(startScreen: userId == null ? const AuthScreen() : const HomeScreen()));
}

class VivaahaApp extends StatelessWidget {
  final Widget startScreen;
  const VivaahaApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil with a standard design size (e.g., iPhone 11 Pro dimensions)
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'VivaahaVerse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B1120), // Ultra Deep Navy
            primaryColor: const Color(0xFFD946EF),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD946EF),    // Neon Fuchsia
              secondary: Color(0xFF8B5CF6),  // Cyber Purple
              surface: Color(0xFF1E293B),    // Slate
              onSurface: Colors.white,
            ),
            textTheme: GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme), // Sci-fi Font
            useMaterial3: true,
          ),
          home: startScreen,
        );
      },
    );
  }
}