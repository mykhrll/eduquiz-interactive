import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  TextEditingController controller = TextEditingController();

  Future<void> sendFeedback() async {
    if (controller.text.trim().isEmpty) return;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    // 🔥 Ambil nama siswa
    String userName = 'anonymous';
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        userName = userDoc.data()!['name'] as String;
      }
    } catch (_) {
      userName = userId;
    }

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': userId,
      'userName': userName, // ✅
      'feedback': controller.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Feedback terkirim")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Tulis feedback..."),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: sendFeedback, child: const Text("Kirim")),
          ],
        ),
      ),
    );
  }
}
