import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'services/local_notification_service.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefsService = await PreferencesService.create();
  themeNotifier.value = prefsService.getThemeMode();

  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const GotNewsApp(),
    ),
  );
}

class GotNewsApp extends StatelessWidget {
  const GotNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'GotNews',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF2E65F3),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E65F3),
              secondary: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primaryColor: const Color(0xFF2E65F3),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2E65F3),
              secondary: Colors.grey,
            ),
          ),
          themeMode: themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _onboardingComplete = false;
  String? _lastCheckedUserId;

  Future<void> _checkOnboarding(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final complete = prefs.getBool('onboarding_complete_$userId') ?? false;
    if (mounted) {
      setState(() {
        _onboardingComplete = complete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final userId = auth.currentUser?.id ?? '';
        
        // Reset state when user changes (login/logout)
        if (_lastCheckedUserId != userId) {
          _lastCheckedUserId = userId;
          _onboardingComplete = false;
          _checkOnboarding(userId);
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Skip onboarding for admin users
        if (!auth.isAdmin && !_onboardingComplete) {
          return const OnboardingScreen();
        }
        return const MainLayout();
      },
    );
  }
}
