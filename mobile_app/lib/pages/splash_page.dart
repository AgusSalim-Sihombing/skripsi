// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mobile_app/pages/login_page.dart';

// class SplashPage extends StatefulWidget {
//   static const routeName = '/splash';

//   const SplashPage({super.key});

//   @override
//   State<SplashPage> createState() => _SplashPageState();
// }

// class _SplashPageState extends State<SplashPage> {
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _startSplashScreen();
//   }

//   void _startSplashScreen() {
//     _timer = Timer(const Duration(seconds: 3), () {
//       if (!mounted) return;
//       Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 255, 255, 255),
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset(
//                 "assets/logo.png",
//                 width: 200,
//                 height: 100,
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 "SIAGA APP",
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 0, 0, 0),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 30,
//                 ),
//               ),

//               const SizedBox(height: 18),

//               // ✅ Loading di bawah teks
//               // const SizedBox(
//               //   width: 28,
//               //   height: 28,
//               //   child: CircularProgressIndicator(
//               //     strokeWidth: 3,
//               //     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               //   ),
//               // ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 60),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: const LinearProgressIndicator(
//                     minHeight: 6,
//                     valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 0, 0, 0)),
//                     backgroundColor: Colors.white24,
//                   ),
//                 ),
//               ),

//               // opsional: teks kecil
//               const SizedBox(height: 12),
//               const Text(
//                 "Loading...",
//                 style: TextStyle(color: Color.fromARGB(179, 0, 0, 0), fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/landing_page.dart';
import 'package:mobile_app/pages/officer/officer_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/background_zone_service.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _boot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBackgroundProtection();
    });
  }

  Future<void> _initBackgroundProtection() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token != null && token.isNotEmpty) {
      await BackgroundZoneService.init();
      await BackgroundZoneService.syncDataFromApi(token);
      await BackgroundZoneService.restartHard();
    }
  }

  void _boot() {
    _timer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final username = prefs.getString('username') ?? '-';
      final role = prefs.getString('user_role') ?? 'masyarakat';
      final isOfficerApproved = prefs.getBool('is_officer_approved') ?? false;

      // base url buat socket
      final socketBaseUrl = ApiConfig.baseUrl.endsWith("/api")
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
          : ApiConfig.baseUrl;

      if (token == null || token.isEmpty) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        return;
      }

      // routing sesuai role kamu
      if (role == 'officer' && isOfficerApproved) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OfficerHomePage(
              username: username,
              token: token,
              baseUrl: socketBaseUrl,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LandingPage(
              username: username,
              token: token,
              baseUrl: socketBaseUrl,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/logo.png", width: 200, height: 100),
              const SizedBox(height: 24),
              const Text(
                "SIAGA APP",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    backgroundColor: Colors.black12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Loading...",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
