import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerformanceAnalyticsPage extends StatefulWidget {
  const PerformanceAnalyticsPage({super.key});

  @override
  State<PerformanceAnalyticsPage> createState() => _PerformanceAnalyticsPageState();
}

class _PerformanceAnalyticsPageState extends State<PerformanceAnalyticsPage> {
  int totalQuizzes = 0;
  double avgAccuracy = 0.0;
  List<double> xpWeekly = [0, 0, 0, 0, 0, 0, 0];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance.collection('results').where('userId', isEqualTo: uid).get();
      
      int quizzes = snap.docs.length;
      double totalScore = 0;
      List<double> weekly = [0, 0, 0, 0, 0, 0, 0];
      
      final now = DateTime.now();
      
      for (var doc in snap.docs) {
        final data = doc.data();
        final score = (data['score'] ?? 0) as num;
        totalScore += score;
        
        // XP is score * 10
        final xp = score.toDouble() * 10;
        
        if (data['createdAt'] != null) {
          final date = (data['createdAt'] as Timestamp).toDate();
          final diff = now.difference(date).inDays;
          if (diff >= 0 && diff < 7) {
            // map difference to today vs 7 days ago. 
            // 0 = today, 6 = 6 days ago.
            // In the UI we have Mon-Sun, let's just reverse map it to the last 7 days.
            weekly[6 - diff] += xp;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          totalQuizzes = quizzes;
          avgAccuracy = quizzes > 0 ? totalScore / quizzes : 0.0;
          xpWeekly = weekly;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // removed const constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0056A8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "EduQuiz",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0056A8)),
                    ),
                  ),
                  const Icon(Icons.local_fire_department_outlined, color: Color(0xFF0056A8)),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text("Your Performance", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  const Text("Keep up the great work!", style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
                  const SizedBox(height: 24),
                  
                  // XP Growth Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("XP Growth (This Week)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                            Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Mock Bar Chart
                        SizedBox(
                          height: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar("Day 1", xpWeekly[0], const Color(0xFFCBD5E1)),
                              _buildBar("Day 2", xpWeekly[1], const Color(0xFF94A3B8)),
                              _buildBar("Day 3", xpWeekly[2], const Color(0xFF94A3B8)),
                              _buildBar("Day 4", xpWeekly[3], const Color(0xFF64748B)),
                              _buildBar("Day 5", xpWeekly[4], const Color(0xFF475569)),
                              _buildBar("Day 6", xpWeekly[5], const Color(0xFF0056A8)),
                              _buildBar("Today", xpWeekly[6], const Color(0xFFE2E8F0)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Cards
                  _buildStatRowCard(Icons.check_circle, const Color(0xFF4ADE80), "Average Accuracy", "${avgAccuracy.toStringAsFixed(1)}%"),
                  const SizedBox(height: 12),
                  _buildStatRowCard(Icons.school, const Color(0xFFBAE6FD), "Quizzes Completed", "$totalQuizzes"),
                  const SizedBox(height: 24),
                  
                  // Strengths
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_up, color: Color(0xFF16A34A)),
                            SizedBox(width: 8),
                            Text("Strengths", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow("Logic & Algorithms", "0%", 0.0, const Color(0xFF16A34A)),
                        const SizedBox(height: 16),
                        _buildProgressRow("Networking Basics", "0%", 0.0, const Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Areas to Improve
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_down, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text("Areas to Improve", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildProgressRow("Database Management", "0%", 0.0, const Color(0xFFDC2626)),
                        const SizedBox(height: 16),
                        _buildProgressRow("UI/UX Principles", "0%", 0.0, const Color(0xFFDC2626)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0F2FE),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Review Database Quizzes", style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double xp, Color color) {
    double height = xp / 2; // scale XP to height
    if (height > 150) height = 150; // cap height
    if (height < 10) height = 10; // min height
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: "${xp.toInt()} XP",
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: 30,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildStatRowCard(IconData icon, Color iconBg, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String percent, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(percent, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: const Color(0xFFE2E8F0),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
