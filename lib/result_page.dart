import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'feedback_page.dart';
import 'translations.dart';
import 'review_answer_page.dart';
import 'rate_teacher_dialog.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final String essay;
  final String role;
  final String quizId;
  final String subjectName;
  final int totalQuestions;
  final String resultId;
  final int streak;

  const ResultPage({
    super.key,
    required this.score,
    required this.essay,
    required this.role,
    required this.quizId,
    required this.subjectName,
    required this.totalQuestions,
    required this.resultId,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    // totalQuestions hanya PG, jadi correct/incorrect hanya untuk PG
    int correct = score ~/ 10;
    int incorrect = totalQuestions - correct;
    if (incorrect < 0) incorrect = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate level from streak
    int level = (streak / 5).floor() + 1;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    "Outstanding Work!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Tr.get('completed_quiz').replaceAll('the Software Engineering Basics', subjectName).replaceAll('kuis Software Engineering Basics', 'kuis $subjectName'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Score Circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(color: const Color(0xFF86EFAC), width: 12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.toString(),
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        Text(
                          "OUT OF ${totalQuestions * 10}",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Correct / Incorrect Stats (hanya PG)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
                                  SizedBox(width: 4),
                                  Text("Correct", style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(correct.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF14532D))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel, color: Color(0xFFDC2626), size: 16),
                                  SizedBox(width: 4),
                                  Text("Incorrect", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(incorrect.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Streak Card — Dynamic from Firebase
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                          child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$streak Day Streak!", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              Text("+${score * 10} XP Earned", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Level $level", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.dashboard_customize_outlined, color: Colors.white),
                    label: const Text("Back to Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewAnswerPage(
                            quizId: quizId,
                            resultId: resultId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined, color: Color(0xFF0056A8)),
                    label: const Text("Review Answers", style: TextStyle(color: Color(0xFF0056A8), fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final quizDoc = await FirebaseFirestore.instance.collection('quizzes').doc(quizId).get();
                        if (quizDoc.exists) {
                          final teacherId = quizDoc.data()?['createdBy'];
                          if (teacherId != null && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => RateTeacherDialog(teacherId: teacherId),
                            );
                          }
                        }
                      } catch (e) {
                        // Ignore error
                      }
                    },
                    icon: const Icon(Icons.star_outline, color: Color(0xFFF59E0B)),
                    label: const Text("Rate Teacher", style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0))),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedbackPage(quizId: quizId, subjectName: subjectName, resultId: resultId),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feedback_outlined, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0056A8)),
              const SizedBox(width: 8),
              Text(
                Tr.get('student_feedback'),
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0056A8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
