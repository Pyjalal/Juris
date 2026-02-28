import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/lod_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/results_screen.dart';
import 'screens/scan_screen.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const JurisApp());
}

class JurisApp extends StatelessWidget {
  const JurisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juris',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>? ?? {};

    switch (settings.name) {
      case '/':
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/scan':
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case '/processing':
        return MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            docId: args['docId'] as String,
          ),
        );
      case '/results':
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(
            docId: args['docId'] as String,
            auditId: args['auditId'] as String,
          ),
        );
      case '/lod':
        return MaterialPageRoute(
          builder: (_) => LodScreen(
            auditId: args['auditId'] as String,
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initializing = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      final service = FirebaseService();
      if (service.currentUser == null) {
        await service.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
    if (mounted) {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }
    
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }
    
    return const HomeScreen();
  }
}
