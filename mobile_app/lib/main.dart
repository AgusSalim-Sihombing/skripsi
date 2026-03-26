import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/splash_page.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("Aplikasi dimulai...");
  await BackgroundZoneService.init();
  await NotificationService.init();
  await ThemeController.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SIGAP',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: SplashPage.routeName,
          routes: {
            SplashPage.routeName: (context) => const SplashPage(),
            LoginScreen.routeName: (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
