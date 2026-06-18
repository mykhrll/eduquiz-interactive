import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_page.dart';
import 'dashboard_page.dart';
import 'app_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Periksa apakah lebih dari 24 jam (khusus Web)
      if (kIsWeb && user.metadata.lastSignInTime != null) {
        final diff = DateTime.now().difference(user.metadata.lastSignInTime!);
        if (diff.inHours >= 24) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            showChatbot.value = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthPage()),
            );
          }
          return;
        }
      }

      // Ambil role dan arahkan ke Dashboard
      String role = 'siswa';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!['role'] != null) {
          role = doc.data()!['role'];
        }
      } catch (_) {}

      if (mounted) {
        showChatbot.value = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
        );
      }
    } else {
      if (mounted) {
        showChatbot.value = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FC), // Soft light blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  "assets/icon.png",
                  width: 90,
                  errorBuilder: (_, _, _) => const Text(
                    "EQ",
                    style: TextStyle(
                      color: Color(0xFF0066CC),
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              "EduQuiz",
              style: TextStyle(
                color: Color(0xFF0056A8),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "INTERACTIVE LEARNING",
              style: TextStyle(
                color: Color(0xFF4A657A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(),
                const SizedBox(width: 8),
                _buildDot(),
                const SizedBox(width: 8),
                _buildDot(),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF0056A8),
        shape: BoxShape.circle,
      ),
    );
  }
}
