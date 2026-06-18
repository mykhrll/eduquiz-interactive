import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<String> _unlockedBadges = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _allBadges = [
    {
      'id': 'first_quiz',
      'title': 'Kuis Pertama',
      'desc': 'Selesaikan 1 kuis pertama Anda.',
      'icon': Icons.stars,
      'color': Colors.blue,
    },
    {
      'id': 'perfect_score',
      'title': 'Sempurna!',
      'desc': 'Dapatkan skor 100 pada sebuah kuis.',
      'icon': Icons.military_tech,
      'color': Colors.amber,
    },
    {
      'id': 'streak_3',
      'title': 'Pemanasan',
      'desc': 'Capai streak 3 hari berturut-turut.',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
    },
    {
      'id': 'streak_7',
      'title': 'Konsisten',
      'desc': 'Capai streak 7 hari berturut-turut.',
      'icon': Icons.whatshot,
      'color': Colors.deepOrange,
    },
    {
      'id': 'quiz_10',
      'title': 'Penikmat Kuis',
      'desc': 'Selesaikan total 10 kuis.',
      'icon': Icons.school,
      'color': Colors.purple,
    },
    {
      'id': 'level_5',
      'title': 'Naik Pangkat',
      'desc': 'Mencapai Level 5.',
      'icon': Icons.workspace_premium,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['unlockedBadges'] != null) {
          setState(() {
            _unlockedBadges = List<String>.from(data['unlockedBadges']);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load badges: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0056A8)),
        title: const Text(
          'Lencana Didapat',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _allBadges.length,
              itemBuilder: (context, index) {
                final badge = _allBadges[index];
                final isUnlocked = _unlockedBadges.contains(badge['id']);
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnlocked ? badge['color'] : Colors.grey[300]!,
                      width: isUnlocked ? 2 : 1,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: badge['color'].withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        badge['icon'],
                        size: 48,
                        color: isUnlocked ? badge['color'] : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        badge['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? const Color(0xFF1E293B) : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge['desc'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: isUnlocked ? const Color(0xFF64748B) : Colors.grey[400],
                        ),
                      ),
                      const Spacer(),
                      if (!isUnlocked)
                        const Icon(Icons.lock, size: 16, color: Colors.grey)
                      else
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
