import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/lod_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    try {
      final service = FirebaseService();
      if (service.currentUser == null) {
        await service.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Auth error: $e');
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
    return const HomeScreen();
  }
}
