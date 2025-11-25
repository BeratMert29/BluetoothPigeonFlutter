import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const BleChat());
}

class BleChat extends StatelessWidget {
  const BleChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF),
          secondary: Color(0xFF00FF94),
          surface: Color(0xFF161B22),
          error: Color(0xFFFF453A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
