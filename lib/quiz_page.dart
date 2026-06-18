import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_page.dart';
import 'app_state.dart';
class QuizPage extends StatefulWidget {
  final String role;
  final String quizId;
  final int timeLimit;
  final String subjectName;
  final List<dynamic> questions;

  const QuizPage({
    super.key,
    required this.role,
    required this.quizId,
    required this.timeLimit,
    required this.subjectName,
    required this.questions,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<int> answers = [];
  final Map<int, TextEditingController> _essayControllers = {};
  bool isLoading = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late int _remainingSeconds;
  bool _isTimeUp = false;
  @override
  void initState() {
    super.initState();
    showChatbot.value = false;
    _remainingSeconds = widget.timeLimit * 60;
    _startTimer();
    // Blokir screenshot & screen recording saat quiz
    _setSecureMode(true);
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _isTimeUp) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _startTimer();
        } else {
          _isTimeUp = true;
          _submit(); // force submit when time is up
        }
      });
    });
  }

  @override
  void dispose() {
    showChatbot.value = true;
    _setSecureMode(false); // Aktifkan kembali setelah keluar quiz
    _pageController.dispose();
    for (var c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _setSecureMode(bool secure) async {
    // Pakai screen_protector untuk mencegah screenshot
    try {
      if (secure) {
        await ScreenProtector.preventScreenshotOn();
      } else {
        await ScreenProtector.preventScreenshotOff();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // SelectionArea dinonaktifkan → tidak bisa copy text di quiz
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Keluar Quiz?'),
              content: const Text('Jawaban yang sudah diisi akan hilang. Yakin keluar?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                  child: const Text('Ya, Keluar'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final docs = widget.questions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
              final pg = docs.where((d) => d['isEssay'] == false).toList();
              final essay = docs.where((d) => d['isEssay'] == true).toList();
              final allQuestions = [...pg, ...essay];

              if (allQuestions.isEmpty) {
                return const Center(child: Text('Belum ada soal'));
              }

              if (answers.length != pg.length) {
                answers = List.filled(pg.length, -1);
              }
              _syncEssayControllers(essay.length);

              return Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Keluar Quiz?'),
                                content: const Text('Jawaban yang sudah diisi akan hilang.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                    child: const Text('Ya, Keluar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) Navigator.pop(context);
                          },
                        ),
                        const Expanded(
                          child: Text('EduQuiz',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0056A8))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            const Icon(Icons.timer, color: Color(0xFFDC2626), size: 14),
                            const SizedBox(width: 4),
                            Text(_formatTime(_remainingSeconds), style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 11)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16)),
                          child: Row(children: const [
                            Icon(Icons.lock, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text('Secure', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                          ]),
                        ),
                      ],
                    ),
                  ),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Soal ${_currentPage + 1} dari ${allQuestions.length}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            Text(widget.subjectName,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_currentPage + 1) / allQuestions.length,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: const Color(0xFF0056A8),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PageView soal (copy text dinonaktifkan)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allQuestions.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        final isEssay = allQuestions[index]['isEssay'] == true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pertanyaan — tidak bisa diselect/copy
                                  ExcludeSemantics(
                                    child: Text(
                                      allQuestions[index]['question'],
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B), height: 1.4),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (!isEssay)
                                    ...List.generate(
                                        (allQuestions[index]['options'] as List).length, (optIndex) {
                                      final isSelected = index < answers.length && answers[index] == optIndex;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (index < answers.length) answers[index] = optIndex;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFEBF3FC) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: isSelected ? const Color(0xFF0056A8) : const Color(0xFFE2E8F0),
                                                width: isSelected ? 2 : 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24, height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: isSelected ? const Color(0xFF0056A8) : const Color(0xFF94A3B8),
                                                      width: isSelected ? 6 : 2),
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  (allQuestions[index]['options'] as List)[optIndex],
                                                  style: TextStyle(
                                                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  else
                                    TextField(
                                      controller: _essayControllers[index - pg.length],
                                      maxLines: 6,
                                      decoration: InputDecoration(
                                        hintText: 'Tulis jawaban Anda di sini...',
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tombol Prev/Next/Submit
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (_currentPage > 0) ...[
                          OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(56, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFF0056A8)),
                            ),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF0056A8)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_currentPage < allQuestions.length - 1) {
                                      _pageController.nextPage(
                                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                    } else {
                                      _submit();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056A8),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(height: 24, width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _currentPage < allQuestions.length - 1 ? 'Berikutnya' : 'Kumpulkan',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _syncEssayControllers(int count) {
    final keysToRemove = <int>[];
    _essayControllers.forEach((k, v) {
      if (k >= count) { v.dispose(); keysToRemove.add(k); }
    });
    for (var k in keysToRemove) { _essayControllers.remove(k); }
    for (int i = 0; i < count; i++) {
      if (!_essayControllers.containsKey(i)) _essayControllers[i] = TextEditingController();
    }
  }

  Future<void> _submit() async {
    setState(() => isLoading = true);
    
    // Separate PG and essay questions
    final allDocs = widget.questions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final pgQuestions = allDocs.where((d) => d['isEssay'] == false).toList();
    
    // Score hanya dari PG
    int score = 0;
    for (int i = 0; i < pgQuestions.length; i++) {
      if (i < answers.length && answers[i] == pgQuestions[i]['correctIndex']) score += 10;
    }

    final essayMap = <String, String>{};
    _essayControllers.forEach((k, ctrl) => essayMap[k.toString()] = ctrl.text.trim());

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    String userName = 'anonymous';
    int currentXp = 0;
    int currentStreak = 0;
    int completedQuizzes = 0;
    List<String> unlockedBadges = [];
    List<String> unlockedCertificates = [];
    DateTime? lastQuizDate;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['name'] != null) userName = data['name'];
        if (data['xp'] != null) currentXp = data['xp'];
        if (data['streak'] != null) currentStreak = data['streak'];
        if (data['completedQuizzes'] != null) completedQuizzes = data['completedQuizzes'];
        if (data['unlockedBadges'] != null) unlockedBadges = List<String>.from(data['unlockedBadges']);
        if (data['unlockedCertificates'] != null) unlockedCertificates = List<String>.from(data['unlockedCertificates']);
        if (data['lastQuizDate'] != null) {
          lastQuizDate = (data['lastQuizDate'] as Timestamp).toDate();
        }
      }
    } catch (_) {}

    // Calculate streak
    int newStreak = currentStreak;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastQuizDate != null) {
      final lastDate = DateTime(lastQuizDate.year, lastQuizDate.month, lastQuizDate.day);
      final diff = today.difference(lastDate).inDays;
      
      if (diff == 0) {
        // Already did quiz today, streak stays the same
        newStreak = currentStreak;
      } else if (diff == 1) {
        // Did quiz yesterday, increment streak
        newStreak = currentStreak + 1;
      } else {
        // More than 1 day gap, reset streak
        newStreak = 1;
      }
    } else {
      // First quiz ever
      newStreak = 1;
    }

    try {
      final docRef = await FirebaseFirestore.instance.collection('results').add({
        'quizId': widget.quizId,
        'subjectName': widget.subjectName,
        'userId': userId,
        'userName': userName,
        'score': score,
        'answers': answers,
        'essay': essayMap,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update XP, Level, Streak, Badges
      if (widget.role == 'siswa' && userId != 'anonymous') {
        int gainedXp = score * 10; // e.g. 100 score = 1000 XP
        int newXp = currentXp + gainedXp;
        int newLevel = (newXp / 1000).floor() + 1; // 1 level per 1000 XP
        
        completedQuizzes += 1;
        
        // Evaluate Badges
        if (!unlockedBadges.contains('first_quiz')) unlockedBadges.add('first_quiz');
        if (score == 100 && !unlockedBadges.contains('perfect_score')) unlockedBadges.add('perfect_score');
        if (newStreak >= 3 && !unlockedBadges.contains('streak_3')) unlockedBadges.add('streak_3');
        if (newStreak >= 7 && !unlockedBadges.contains('streak_7')) unlockedBadges.add('streak_7');
        if (completedQuizzes >= 10 && !unlockedBadges.contains('quiz_10')) unlockedBadges.add('quiz_10');
        if (newLevel >= 5 && !unlockedBadges.contains('level_5')) unlockedBadges.add('level_5');

        // Evaluate Certificates
        if (newLevel >= 10 && !unlockedCertificates.contains('cert_level_10')) unlockedCertificates.add('cert_level_10');
        if (completedQuizzes >= 20 && score == 100 && !unlockedCertificates.contains('cert_perfect_20')) unlockedCertificates.add('cert_perfect_20');

        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'xp': newXp,
          'level': newLevel,
          'streak': newStreak,
          'lastQuizDate': Timestamp.fromDate(today),
          'completedQuizzes': completedQuizzes,
          'unlockedBadges': unlockedBadges,
          'unlockedCertificates': unlockedCertificates,
        });
      }

      // totalQuestions hanya PG (essay tidak dihitung correct/incorrect)
      int totalPgQuestions = pgQuestions.length;

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => ResultPage(
              score: score, 
              essay: essayMap.toString(), 
              role: widget.role,
              quizId: widget.quizId,
              subjectName: widget.subjectName,
              totalQuestions: totalPgQuestions,
              resultId: docRef.id,
              streak: newStreak,
            )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}
