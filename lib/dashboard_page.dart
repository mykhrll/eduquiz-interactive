import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'feedback_page.dart';
import 'manage_questions_page.dart';
import 'auth_page.dart';
import 'account_settings_page.dart';
import 'notification_preferences_page.dart';
import 'school_information_page.dart';
import 'edit_profile_page.dart';
import 'performance_analytics_page.dart';
import 'my_certificates_page.dart';
import 'badges_page.dart';
import 'translations.dart';
import 'app_state.dart';
import 'pre_quiz_page.dart';
import 'create_quiz_page.dart'; 
import 'teacher_feedback_subjects_page.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  const DashboardPage({super.key, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  // Data profil user dari Firebase
  String _userName = '';
  String _userSubtitle = '';
  String? _userPhotoUrl;
  
  int _xp = 0;
  int _level = 1;
  int _streak = 0;
  
  int _quizzesCreated = 0;
  int _totalStudents = 0;
  double _avgRating = 0.0;
  int _badgesEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _saveFcmTokenToFirestore();
  }

  Future<void> _saveFcmTokenToFirestore() async {
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        
        int totalStudents = 0;
        int quizzesCreated = 0;
        
        if (widget.role == 'guru') {
          final studentDocs = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'siswa').get();
          totalStudents = studentDocs.docs.length;
          final quizzesDocs = await FirebaseFirestore.instance.collection('quizzes').where('createdBy', isEqualTo: uid).get();
          quizzesCreated = quizzesDocs.docs.length;
        }

        setState(() {
          _userName = data['name'] ?? 'Pengguna';
          _userSubtitle = data['school'] ?? (widget.role == 'guru' ? 'Guru' : 'Siswa');
          _userPhotoUrl = data['photoUrl'];
          _xp = data['xp'] ?? 0;
          _level = data['level'] ?? 1;
          _streak = data['streak'] ?? 0;
          
          _quizzesCreated = quizzesCreated;
          _totalStudents = totalStudents;
          
          if (data['unlockedBadges'] != null) {
            _badgesEarned = (data['unlockedBadges'] as List).length;
          }

          final totalR = (data['totalRating'] ?? 0) as num;
          final countR = (data['ratingCount'] ?? 0) as num;
          _avgRating = countR > 0 ? (totalR / countR).toDouble() : 0.0;
        });
      }
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, theme, _) {
        final isDark = theme == ThemeMode.dark;
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
              body: SafeArea(child: _buildBody(isDark)),
              bottomNavigationBar: _buildBottomNav(isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => setState(() => currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      selectedItemColor: isDark ? Colors.blue[300] : const Color(0xFF0056A8),
      unselectedItemColor: isDark ? Colors.grey[600] : const Color(0xFF94A3B8),
      showUnselectedLabels: true,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_filled),
          label: Tr.get('nav_home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.school_outlined),
          label: Tr.get('nav_quizzes'),
        ),
        if (widget.role == "guru")
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: Tr.get('nav_results'),
          )
        else
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard_outlined),
            label: Tr.get('nav_rankings'),
          ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: Tr.get('nav_profile'),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (currentIndex == 0) {
      return widget.role == "guru" ? _buildTeacherHome(isDark) : _buildStudentHome(isDark);
    } else if (currentIndex == 1) {
      return _buildMenu(); // Quizzes
    } else if (currentIndex == 2) {
      return widget.role == "guru"
          ? _buildTeacherFeedbackAnalytics()
          : _buildStudentRankings(isDark);
    } else {
      return _buildProfile(isDark);
    }
  }

  // ===================== TEACHER DASHBOARD (DESIGN 3) =====================
  Widget _buildTeacherHome(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _loadUserData(),
      child: ListView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
        _buildAppBarTeacher(),
        const SizedBox(height: 24),
        Text(
          "${Tr.get('welcome_back')},\n${_userName.isNotEmpty ? _userName.split(' ').first : Tr.get('guru')}",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Tr.get('teacher_home_subtitle'),
          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateQuizPage()),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  Tr.get('create_quiz'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056A8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageQuestionsPage(role: 'guru'),
                  ),
                ),
                icon: const Icon(
                  Icons.folder_open,
                  color: Color(0xFF0056A8),
                  size: 18,
                ),
                label: Text(
                  Tr.get('manage'),
                  style: const TextStyle(
                    color: Color(0xFF0056A8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Dummy stats removed based on user request
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Tr.get('recent_quizzes'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageQuestionsPage(role: 'guru'),
                  ),
                );
              },
              child: Text(
                Tr.get('view_all'),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0056A8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final allDocs = snapshot.data?.docs ?? [];
            // Sort client-side to avoid composite index
            allDocs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return (bTime as Timestamp).compareTo(aTime as Timestamp);
            });
            final docs = allDocs.take(3).toList();
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: const Text("Belum ada kuis yang dibuat.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
              );
            }
            
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: List.generate(docs.length, (index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Untitled';
                  final subject = data['subject'] ?? 'No Subject';
                  final status = data['status'] ?? 'Active';
                  final color = status == 'Active' ? Colors.green : Colors.grey;
                  
                  return Column(
                    children: [
                      _buildRecentQuizItem(title, subject, status, color),
                      if (index < docs.length - 1)
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ],
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          Tr.get('needs_attention'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('results')
              .where('score', isLessThan: 60)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allResults = snapshot.data?.docs ?? [];
            
            // To filter results belonging to this teacher, we query the teacher's quizzes
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, quizSnapshot) {
                if (quizSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                
                final myQuizIds = quizSnapshot.data?.docs.map((d) => d.id).toSet() ?? {};
                
                // Filter results to only include this teacher's quizzes
                final myLowScores = allResults.where((r) {
                  final data = r.data() as Map<String, dynamic>;
                  return myQuizIds.contains(data['quizId']);
                }).toList();

                if (myLowScores.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Text('Semua siswa mendapat nilai memuaskan!', style: TextStyle(color: isDark ? Colors.grey[300] : const Color(0xFF475569))),
                      ],
                    ),
                  );
                }

                return Column(
                  children: List.generate(myLowScores.take(3).length, (index) {
                    final data = myLowScores[index].data() as Map<String, dynamic>;
                    final studentName = data['userName'] ?? 'Siswa';
                    final score = data['score'] ?? 0;
                    final subject = data['subjectName'] ?? 'Kuis';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Tr.get('low_scores_detected'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$studentName mendapat nilai $score pada $subject.",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildRecentQuizItem(
    String title,
    String subtitle,
    String status,
    Color statusColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.code, color: Color(0xFF64748B)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ),
    );
  }



  Widget _buildAppBarTeacher() {
    return Row(
      children: [
        _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_userPhotoUrl!),
                backgroundColor: Colors.transparent,
              )
            : CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
        const SizedBox(width: 12),
        const Text(
          "EduQuiz",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0056A8),
          ),
        ),
        const Spacer(),
        const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
      ],
    );
  }


  // ===================== STUDENT DASHBOARD (DESIGN 4) =====================
  Widget _buildStudentHome(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _loadUserData(),
      child: ListView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildAppBarStudent(),
          const SizedBox(height: 24),
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Tr.get('ready_level_up').replaceAll('Ready to level up', 'Ready to level up,\n${_userName.isNotEmpty ? _userName.split(' ').first : 'Siswa'}?').replaceAll('Siap naik level', 'Siap naik level,\n${_userName.isNotEmpty ? _userName.split(' ').first : 'Siswa'}?'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                Tr.get('new_quizzes_waiting'),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final snap = await FirebaseFirestore.instance.collection('quizzes').orderBy('createdAt', descending: true).limit(1).get();
                  if (snap.docs.isNotEmpty && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreQuizPage(quizId: snap.docs.first.id),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Tr.get('no_quizzes_available'))));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[300] : const Color(0xFF0056A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  Tr.get('start_next_quiz'),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Total XP
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.green[900]! : const Color(0xFFDCFCE7)),
          ),
          child: Column(
            children: [
              Text(
                Tr.get('total_xp'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Color(0xFF16A34A), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    _xp.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${Tr.get('level')} $_level",
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_xp % 1000) / 1000,
                backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFDCFCE7),
                color: const Color(0xFF16A34A),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                "${1000 - (_xp % 1000)} ${Tr.get('xp_to_level')} ${_level + 1}",
                style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Weekly Leaderboard
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        Tr.get('nav_rankings'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = 2; // Navigate to Rankings Tab
                      });
                    },
                    child: Text(
                      Tr.get('view_all'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .limit(30) // Ambil cukup banyak, lalu filter 'siswa' secara lokal
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  // Local filter for 'siswa'
                  final allDocs = snapshot.data?.docs ?? [];
                  final studentDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['role'] == 'siswa';
                  }).toList();
                  studentDocs.sort((a, b) {
                    final xpA = (a.data() as Map<String, dynamic>)['xp'] ?? 0;
                    final xpB = (b.data() as Map<String, dynamic>)['xp'] ?? 0;
                    return xpB.compareTo(xpA);
                  });
                  final top3 = studentDocs.take(3).toList(); // Ambil top 3

                  if (top3.isEmpty) {
                    return Center(child: Text(Tr.get('no_data')));
                  }
                  
                  return Column(
                    children: List.generate(top3.length, (index) {
                      final data = top3[index].data() as Map<String, dynamic>;
                      final isMe = top3[index].id == FirebaseAuth.instance.currentUser?.uid;
                      
                      Widget item = _buildLeaderboardItem(
                        "${index + 1}",
                        data['name']?.toString().split(' ').first ?? 'Siswa',
                        "${data['xp'] ?? 0} XP",
                        index == 0,
                        isDark,
                      );
                      
                      if (isMe) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEBF3FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: item,
                          ),
                        );
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: item,
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          Tr.get('up_next'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildUpNextCard(),
      ],
    ),
  );
}

  Widget _buildLeaderboardItem(
    String rank,
    String name,
    String xp,
    bool isFirst,
    bool isDark,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            rank,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isFirst ? Colors.orange : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Text(
          xp,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isFirst ? Colors.green : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildUpNextCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(child: Text(Tr.get('no_quizzes_available'))),
          );
        }

        final doc = docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Kuis Baru';
        final subject = data['subject'] ?? 'Umum';
        final duration = data['timeLimit'] ?? 10;
        final xp = data['xpReward'] ?? 100;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        "$duration mins",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "+$xp XP",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreQuizPage(quizId: doc.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(Tr.get('play')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBarStudent() {
    return Row(
      children: [
        _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_userPhotoUrl!),
                backgroundColor: Colors.transparent,
              )
            : const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
        const SizedBox(width: 12),
        const Text(
          "EduQuiz",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0056A8),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      "$_streak Day Streak!",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ayo kerjakan kuis setiap hari untuk mempertahankan streak-mu!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056A8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  "$_streak Day Streak!",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== MENUS (Quizzes & Profile) =====================
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            "All Quizzes",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (widget.role == "guru") ...[
            _menuCard(
              icon: Icons.add,
              title: "Buat Soal",
              subtitle: "Tambahkan soal pilihan ganda & essay",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateQuizPage()),
              ),
            ),
            _menuCard(
              icon: Icons.list_alt,
              title: "Kelola Soal",
              subtitle: Tr.get('teacher_home_subtitle'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageQuestionsPage(role: 'guru')),
              ),
            ),
          ],
          if (widget.role == "siswa") ...[
            _menuCard(
              icon: Icons.quiz,
              title: "Kerjakan Quiz",
              subtitle: "Mulai mengerjakan soal",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageQuestionsPage(role: 'siswa')),
              ),
            ),
            _menuCard(
              icon: Icons.feedback,
              title: "Isi Feedback",
              subtitle: "Berikan pendapatmu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherFeedbackSubjectsPage()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ===================== TEACHER FEEDBACK ANALYTICS (DESIGN 2) =====================
  // ===================== TEACHER FEEDBACK ANALYTICS (DESIGN 2) =====================
  Widget _buildTeacherFeedbackAnalytics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').where('createdBy', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(Tr.get('no_feedback'), style: TextStyle(color: Color(0xFF64748B))));
          }

          // Extract unique subjects
          final Set<String> subjects = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['subject'] != null) {
              subjects.add(data['subject']);
            }
          }

          final subjectList = subjects.toList()..sort();

          if (subjectList.isEmpty) {
            return Center(child: Text(Tr.get('no_feedback'), style: TextStyle(color: Color(0xFF64748B))));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: subjectList.length,
            itemBuilder: (context, index) {
              final subject = subjectList[index];
              
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackPage(quizId: 'all', subjectName: subject),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.folder, color: Color(0xFF1D4ED8), size: 32),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          subject,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }




  // ===================== STUDENT RANKINGS (DESIGN 4) =====================
  Widget _buildStudentRankings(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAppBarStudent(),
        const SizedBox(height: 40),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black)));
            }
            
            final allDocs = snapshot.data?.docs ?? [];
            final studentDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['role'] == 'siswa';
            }).toList();
            studentDocs.sort((a, b) {
              final xpA = (a.data() as Map<String, dynamic>)['xp'] ?? 0;
              final xpB = (b.data() as Map<String, dynamic>)['xp'] ?? 0;
              return xpB.compareTo(xpA);
            });
            
            final top3 = studentDocs.take(3).toList();
            final rest = studentDocs.skip(3).toList();

            if (studentDocs.isEmpty) {
              return Center(child: Text(Tr.get('no_rankings'), style: TextStyle(color: isDark ? Colors.white : Colors.black)));
            }

            Widget buildPodium() {
              if (top3.isEmpty) return const SizedBox();
              
              String getName(int idx) => (top3[idx].data() as Map<String, dynamic>)['name']?.toString().split(' ').first ?? 'Siswa';
              String getXp(int idx) => "${(top3[idx].data() as Map<String, dynamic>)['xp'] ?? 0} XP";

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 2nd Place
                  if (top3.length > 1)
                    _buildPodiumSpot(
                      getName(1),
                      getXp(1),
                      "2",
                      120,
                      const Color(0xFFE2E8F0),
                    )
                  else
                    const SizedBox(width: 90),
                  // 1st Place
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildPodiumSpot(
                      getName(0),
                      getXp(0),
                      "1",
                      160,
                      const Color(0xFFFFEDD5),
                      isFirst: true,
                    ),
                  ),
                  // 3rd Place
                  if (top3.length > 2)
                    _buildPodiumSpot(
                      getName(2),
                      getXp(2),
                      "3",
                      100,
                      const Color(0xFFF1F5F9),
                      isThird: true,
                    )
                  else
                    const SizedBox(width: 90),
                ],
              );
            }

            return Column(
              children: [
                buildPodium(),
                const SizedBox(height: 24),
                if (rest.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: List.generate(rest.length, (index) {
                        final doc = rest[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isMe = doc.id == FirebaseAuth.instance.currentUser?.uid;
                        return Column(
                          children: [
                            _buildRankingRow(
                              "${index + 4}",
                              data['name'] ?? 'Siswa',
                              "Level ${data['level'] ?? 1}",
                              "${data['xp'] ?? 0} XP",
                              isMe: isMe,
                            ),
                            if (index < rest.length - 1)
                              Divider(height: 1, color: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0)),
                          ],
                        );
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPodiumSpot(
    String name,
    String xp,
    String rank,
    double height,
    Color bgColor, {
    bool isFirst = false,
    bool isThird = false,
  }) {
    Color rankColor = isFirst
        ? const Color(0xFFD97706)
        : (isThird ? const Color(0xFF78350F) : const Color(0xFF94A3B8));
    return Column(
      children: [
        if (isFirst) const Icon(Icons.stars, color: Colors.orange, size: 28),
        if (isFirst) const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    rank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(top: BorderSide(color: rankColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: rankColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFirst
                      ? const Color(0xFF0056A8)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                xp,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingRow(
    String rank,
    String name,
    String subtitle,
    String xp, {
    bool isMe = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF0F9FF) : Colors.transparent,
        border: isMe
            ? const Border(left: BorderSide(color: Color(0xFF0056A8), width: 4))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isMe ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE2E8F0),
            child: isMe
                ? const Icon(Icons.person, color: Colors.orange)
                : Text(
                    name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMe
                        ? const Color(0xFF0056A8)
                        : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            xp,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(bool isDark) {
    return widget.role == "guru"
        ? _buildTeacherProfile(isDark)
        : _buildStudentProfile(isDark);
  }

  // ===================== TEACHER PROFILE (DESIGN 2) =====================
  Widget _buildTeacherProfile(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAppBarSimple(Tr.get('teacher_profile')),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              _loadUserData();
            },
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 4),
                    image: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_userPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage("assets/teacher.png"),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.person, color: Colors.white, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0056A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _userName.isNotEmpty ? _userName : 'Loading...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _userSubtitle.isNotEmpty ? _userSubtitle : Tr.get('teacher'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 6),
                Text(
                  "${_avgRating.toStringAsFixed(1)} Rating",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildProfileStatCard(Icons.quiz, Tr.get('quizzes_created'), _quizzesCreated.toString(), Colors.blue),
            const SizedBox(width: 12),
            _buildProfileStatCard(Icons.group, Tr.get('total_students'), _totalStudents.toString(), Colors.green),
            const SizedBox(width: 12),
            _buildProfileStatCard(Icons.star, Tr.get('avg_rating'), "${_avgRating.toStringAsFixed(1)}/5", Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                Icons.person_outline,
                Tr.get('account_settings'),
                Tr.get('personal_info_desc'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              _buildSettingsTile(
                Icons.notifications_none,
                Tr.get('notification_pref'),
                Tr.get('notification_pref_desc'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPreferencesPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              _buildSettingsTile(
                Icons.business,
                Tr.get('school_info'),
                Tr.get('school_info_desc'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchoolInformationPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Color(0xFFBE123C)),
                ),
                title: Text(
                  Tr.get('logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                ),
                subtitle: Text(
                  Tr.get('logout_desc'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== STUDENT PROFILE (DESIGN 5) =====================
  Widget _buildStudentProfile(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              _loadUserData();
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 4),
                    image: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_userPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.person, color: Colors.white, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0056A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 12),
                  ),
                ),
                Positioned(
                  bottom: -15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF86EFAC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Color(0xFF166534), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Level $_level",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Text(
            _userName.isNotEmpty ? _userName : 'Loading...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _userSubtitle.isNotEmpty ? _userSubtitle : 'Siswa',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 24),
        // Total XP Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            Tr.get('total_xp'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.bolt, color: Colors.blue, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${Tr.get('keep_it_up_level')} ${_level + 1}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _xp.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          " / ${(_level) * 1000}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_xp % 1000) / 1000,
                backgroundColor: const Color(0xFFCBD5E1),
                color: const Color(0xFF0284C7),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Badges row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 80),
                          const SizedBox(height: 16),
                          Text(
                            "$_streak Hari Streak!",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Luar biasa! Kamu terus belajar tanpa henti. Pertahankan semangatmu!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFFD97706),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _streak.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        Tr.get('day_streak'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFEF3C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesPage()));
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF86EFAC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF166534),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _badgesEarned.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      Text(
                        Tr.get('badges_earned'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsMenuCard(
          Icons.edit,
          Tr.get('edit_profile'),
          Colors.blue,
          const Color(0xFFE0F2FE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.workspace_premium,
          Tr.get('my_certificates'),
          Colors.green,
          const Color(0xFFDCFCE7),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCertificatesPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.bar_chart,
          Tr.get('perf_analytics'),
          Colors.orange,
          const Color(0xFFFFEDD5),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerformanceAnalyticsPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.settings,
          Tr.get('account_settings'),
          Colors.purple,
          const Color(0xFFF3E8FF),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingsMenuCard(
          Icons.logout,
          Tr.get('logout'),
          Colors.red,
          const Color(0xFFFEE2E2),
          onTap: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  Widget _buildSettingsMenuCard(
    IconData icon,
    String title,
    Color iconColor,
    Color bgColor, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: isDark ? 0.2 : 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isDark ? iconColor.withValues(alpha: 0.8) : iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        trailing: title == Tr.get('logout')
            ? null
            : Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0056A8)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        trailing: Icon(Icons.chevron_right, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

  PreferredSizeWidget _buildAppBarSimple(String title) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: const Color(0xFF0056A8),
      elevation: 0,
    );
  }

  Widget _buildProfileStatCard(IconData icon, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
