import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final String essay;
  final String role; // 🔥 untuk kembali ke dashboard

  const ResultPage({
    super.key,
    required this.score,
    required this.essay,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hasil")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Nilai: $score", style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Text("Essay: $essay", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Kembali ke dashboard sesuai role
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(role: role),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text("Kembali ke Menu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
