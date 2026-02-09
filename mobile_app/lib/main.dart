// import 'package:flutter/material.dart';
// import 'package:mobile_app/pages/login_page.dart';
// import 'package:mobile_app/pages/splash_page.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'SIAGA',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       initialRoute: SplashPage.routeName,
//       routes: {
//         SplashPage.routeName: (context) => const SplashPage(),
//         LoginScreen.routeName: (context) => const LoginScreen(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/splash_page.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'package:mobile_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("Aplikasi dimulai...");
  await BackgroundZoneService.init();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIAGA',
      initialRoute: SplashPage.routeName,
      routes: {
        SplashPage.routeName: (context) => const SplashPage(),
        LoginScreen.routeName: (context) => const LoginScreen(),
      },
    );
  }
}
