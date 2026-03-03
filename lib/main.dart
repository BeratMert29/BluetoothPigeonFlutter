import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF09091A),
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
        scaffoldBackgroundColor: const Color(0xFF09091A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF5B7BFE),
          secondary: const Color(0xFF8B5CF6),
          surface: const Color(0xFF0F1020),
          error: const Color(0xFFF43F5E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1020),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}
