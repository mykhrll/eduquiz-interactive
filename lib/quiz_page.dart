import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final String role; // 🔥 untuk diteruskan ke ResultPage
  const QuizPage({super.key, required this.role});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<int> answers = [];
  final Map<int, TextEditingController> _essayControllers = {};
  bool isLoading = false;

  @override
  void dispose() {
    for (var c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('questions')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada soal"));
          }

          final docs = snapshot.data!.docs;
          final pg = docs.where((d) => d['isEssay'] == false).toList();
          final essay = docs.where((d) => d['isEssay'] == true).toList();

          // Inisialisasi jawaban PG
          if (answers.length != pg.length) {
            answers = List.filled(pg.length, -1);
          }

          // Sinkronkan controllers essay
          _syncEssayControllers(essay.length);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (pg.isNotEmpty) ...[
                const Text(
                  "Pilihan Ganda",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < pg.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${i + 1}. ${pg[i]['question']}"),
                          const SizedBox(height: 8),
                          for (
                            int j = 0;
                            j < (pg[i]['options'] as List).length;
                            j++
                          )
                            RadioListTile<int>(
                              title: Text((pg[i]['options'] as List)[j]),
                              value: j,
                              groupValue: i < answers.length ? answers[i] : -1,
                              onChanged: (v) {
                                setState(() {
                                  answers[i] = v!;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              if (essay.isNotEmpty) ...[
                const Text(
                  "Essay",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < essay.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${i + 1}. ${essay[i]['question']}"),
                          TextField(
                            controller: _essayControllers[i],
                            decoration: const InputDecoration(
                              hintText: "Jawaban essay...",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: isLoading ? null : () => _submit(pg),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncEssayControllers(int essayCount) {
    var keysToRemove = <int>[];
    _essayControllers.forEach((key, value) {
      if (key >= essayCount) {
        value.dispose();
        keysToRemove.add(key);
      }
    });
    for (var key in keysToRemove) {
      _essayControllers.remove(key);
    }

    for (int i = 0; i < essayCount; i++) {
      if (!_essayControllers.containsKey(i)) {
        _essayControllers[i] = TextEditingController(text: '');
      }
    }
  }

  Future<void> _submit(List<QueryDocumentSnapshot> pg) async {
    setState(() => isLoading = true);
    int score = 0;

    for (int i = 0; i < pg.length; i++) {
      if (i < answers.length && answers[i] == pg[i]['correctIndex']) {
        score += 10;
      }
    }

    Map<String, String> essayMap = {};
    _essayControllers.forEach((key, controller) {
      essayMap[key.toString()] = controller.text.trim();
    });

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    // 🔥 Ambil nama siswa dari Firestore
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
      // fallback to userId
      userName = userId;
    }

    try {
      await FirebaseFirestore.instance.collection('results').add({
        'userId': userId,
        'userName': userName, // ✅ disimpan
        'score': score,
        'essay': essayMap,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              score: score,
              essay: essayMap.toString(),
              role: widget.role, // 🔥 teruskan role
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint("ERROR SUBMIT: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan hasil: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
