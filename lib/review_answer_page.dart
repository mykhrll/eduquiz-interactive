import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';

class ReviewAnswerPage extends StatelessWidget {
  final String quizId;
  final String resultId;

  const ReviewAnswerPage({
    super.key,
    required this.quizId,
    required this.resultId,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, theme, _) {
        final isDark = theme == ThemeMode.dark;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Review Answers", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 16)),
          ),
          body: FutureBuilder(
            future: Future.wait([
              FirebaseFirestore.instance.collection('quizzes').doc(quizId).get(),
              FirebaseFirestore.instance.collection('results').doc(resultId).get(),
            ]),
            builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.any((doc) => !doc.exists)) {
                return const Center(child: Text("Data not found"));
              }

              final quizData = snapshot.data![0].data() as Map<String, dynamic>;
              final resultData = snapshot.data![1].data() as Map<String, dynamic>;

              final questions = (quizData['questions'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
              final pgQuestions = questions.where((q) => q['isEssay'] == false).toList();
              final essayQuestions = questions.where((q) => q['isEssay'] == true).toList();
              
              final studentAnswers = List<int>.from(resultData['answers'] ?? []);
              final studentEssayMap = Map<String, String>.from(resultData['essay'] ?? {});

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (pgQuestions.isNotEmpty) ...[
                    Text("Multiple Choice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    ...List.generate(pgQuestions.length, (index) {
                      final q = pgQuestions[index];
                      final correctAnswerIndex = q['correctIndex'] as int;
                      final studentAnswerIndex = index < studentAnswers.length ? studentAnswers[index] : -1;
                      final options = List<String>.from(q['options'] ?? []);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1}. ${q['question']}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(options.length, (optIndex) {
                              final isSelected = studentAnswerIndex == optIndex;
                              final isCorrect = correctAnswerIndex == optIndex;
                              
                              Color bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA);
                              Color borderColor = isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0);
                              Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

                              if (isSelected) {
                                if (isCorrect) {
                                  bgColor = const Color(0xFFDCFCE7);
                                  borderColor = const Color(0xFF22C55E);
                                  textColor = const Color(0xFF166534);
                                } else {
                                  bgColor = const Color(0xFFFEE2E2);
                                  borderColor = const Color(0xFFEF4444);
                                  textColor = const Color(0xFF991B1B);
                                }
                              } else if (isCorrect) {
                                bgColor = const Color(0xFFDCFCE7);
                                borderColor = const Color(0xFF22C55E);
                                textColor = const Color(0xFF166534);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(options[optIndex], style: TextStyle(color: textColor))),
                                    if (isSelected && isCorrect) const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                                    if (isSelected && !isCorrect) const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                                    if (!isSelected && isCorrect) const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (essayQuestions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text("Essay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    const SizedBox(height: 16),
                    ...List.generate(essayQuestions.length, (index) {
                      final q = essayQuestions[index];
                      final studentAnswer = studentEssayMap[index.toString()] ?? "No answer";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${index + 1}. ${q['question']}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(studentAnswer, style: TextStyle(color: isDark ? Colors.grey[300] : const Color(0xFF475569))),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              );
            },
          ),
        );
      },
    );
  }
}
