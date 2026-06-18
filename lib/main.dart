import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔥 Tambah kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_strategy/url_strategy.dart'; // 🔥 SEO: hapus hash dari URL
import 'firebase_options.dart'; // 🔥 WAJIB
import 'splash_page.dart';
import 'app_state.dart';
import 'chatbot_overlay.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  setPathUrlStrategy(); // 🔥 SEO: hapus hash dari URL
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 🔥 INI YANG BENAR
  );

  // Enable persistence across tabs and sessions (Hanya untuk Web)
  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (_) {}
  }

  // Check 24-hour session
  final prefs = await SharedPreferences.getInstance();
  final loginTimestampStr = prefs.getString('login_timestamp');
  if (loginTimestampStr != null) {
    final loginTime = DateTime.parse(loginTimestampStr);
    if (DateTime.now().difference(loginTime).inHours >= 24) {
      await FirebaseAuth.instance.signOut();
      await prefs.remove('login_timestamp');
    }
  }

  await initAppState();

  runApp(const EduQuizApp());
}

class EduQuizApp extends StatelessWidget {
  const EduQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'EduQuiz Interactive',
              themeMode: themeMode,
              locale: locale,
              builder: (context, child) {
                return ChatbotOverlay(child: child!);
              },
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  ui.PointerDeviceKind.touch,
                  ui.PointerDeviceKind.stylus,
                  ui.PointerDeviceKind.trackpad,
                },
              ),
              theme: ThemeData(
                primaryColor: const Color(0xFF1565C0),
                scaffoldBackgroundColor: const Color(0xFFE3F2FD),
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                primaryColor: const Color(0xFF0D47A1),
                scaffoldBackgroundColor: const Color(0xFF121212),
                brightness: Brightness.dark,
                cardColor: const Color(0xFF1E1E1E),
                dividerColor: Colors.grey[800],
              ),
              home: const SplashPage(),
            );
          },
        );
      },
    );
  }
}
