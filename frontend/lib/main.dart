import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_gate_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseInitError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseInitError = e.toString();
  }
  runApp(CropDiagnosisApp(firebaseInitError: firebaseInitError));
}

class CropDiagnosisApp extends StatelessWidget {
  const CropDiagnosisApp({super.key, this.firebaseInitError});

  final String? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Crop Disease Diagnosis',
      scaffoldMessengerKey: rootMessengerKey,
      theme: base.copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B5E20),
          secondary: Color(0xFF3F8F55),
          tertiary: Color(0xFFB66A1E),
          surface: Color(0xFFFFFDF8),
          error: Color(0xFFB3261E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F4EC),
        textTheme: base.textTheme.copyWith(
          headlineMedium: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17331D),
            letterSpacing: -0.8,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17331D),
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF23422A),
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF314A37),
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF4B6650),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFF6F4EC),
          foregroundColor: Color(0xFF17331D),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17331D),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFFFFCF7),
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE3E7DA)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFCF7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDDE4D5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFDDE4D5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF58705D),
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF1F6B2B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF235C2B),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF203726),
          contentTextStyle: base.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: firebaseInitError == null
          ? AuthGateScreen(messengerKey: rootMessengerKey)
          : FirebaseSetupScreen(error: firebaseInitError!),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Setup Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App could not initialize Firebase.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Complete Firebase setup for the app platform:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Android:\n'
                  '1. Create/select Firebase project\n'
                  '2. Add Android app with package: com.example.crop_disease_detector\n'
                  '3. Download google-services.json\n'
                  '4. Place file at android/app/google-services.json\n\n'
                  'iPhone / iOS:\n'
                  '1. Add an iOS app in the same Firebase project\n'
                  '2. Use your Xcode bundle identifier from Runner\n'
                  '3. Download GoogleService-Info.plist\n'
                  '4. Place file at ios/Runner/GoogleService-Info.plist\n'
                  '5. Open ios/Runner.xcworkspace in Xcode, set Signing Team, then rebuild',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Initialization error:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
