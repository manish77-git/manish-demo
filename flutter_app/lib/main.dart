import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Config
import 'config/theme.dart';

// Services
import 'services/audio_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/drawing_provider.dart';
import 'providers/socket_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/progression_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/game/lobby_screen.dart';
import 'screens/game/drawing_screen.dart';
import 'screens/game/results_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioService().init();

  runApp(const DrawBattleApp());
}

/// DrawBattle — Cross-platform AI Drawing Challenge App.
class DrawBattleApp extends StatelessWidget {
  const DrawBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgressionProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => DrawingProvider()),
        ChangeNotifierProvider(create: (_) {
          final sp = SocketProvider();
          sp.connect();
          return sp;
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DrawBattle',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.sdkThemeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/lobby': (context) => const LobbyScreen(),
              '/drawing': (context) => const DrawingScreen(),
              '/results': (context) => const ResultsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
