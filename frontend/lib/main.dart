import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
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
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // Skip onboarding for admin users
        if (!auth.isAdmin && !auth.isOnboardingComplete) {
          return const OnboardingScreen();
        }
        return const MainLayout();
      },
    );
  }
}
