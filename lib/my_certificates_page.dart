import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCertificatesPage extends StatefulWidget {
  const MyCertificatesPage({super.key});

  @override
  State<MyCertificatesPage> createState() => _MyCertificatesPageState();
}

class _MyCertificatesPageState extends State<MyCertificatesPage> {
  List<String> _unlockedCertificates = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _allCertificates = [
    {
      'id': 'cert_level_10',
      'title': 'Sertifikat Dedikasi Belajar',
      'desc': 'Diberikan karena telah mencapai Level 10.',
      'icon': Icons.workspace_premium,
      'color': Colors.blueAccent,
    },
    {
      'id': 'cert_perfect_20',
      'title': 'Sertifikat Penguasaan Materi',
      'desc': 'Diberikan karena telah menyelesaikan 20 kuis dengan nilai sempurna pada kuis terakhir.',
      'icon': Icons.stars,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['unlockedCertificates'] != null) {
          setState(() {
            _unlockedCertificates = List<String>.from(data['unlockedCertificates']);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load certificates: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Center(
                          child: Text("Sertifikat Saya", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text("Rayakan pencapaian Anda dan unduh\nsertifikat penghargaan Anda.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4)),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                                      child: const Icon(Icons.workspace_premium, color: Color(0xFF1E3A8A)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("TOTAL\nDIDAPAT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), height: 1.2)),
                                        Text("${_unlockedCertificates.length}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        if (_unlockedCertificates.isEmpty) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                "Anda belum mendapatkan sertifikat apa pun.\nSelesaikan kuis dan naik level untuk mendapatkannya!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ] else ...[
                          ..._allCertificates.where((c) => _unlockedCertificates.contains(c['id'])).map((cert) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cert['color'].withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: cert['color'].withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(cert['icon'], size: 48, color: cert['color']),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cert['title'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cert['desc'],
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: Color(0xFF0056A8)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sertifikat berhasil diunduh!')),
                                      );
                                    },
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Keep Learning
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid), // Dashed normally
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                                child: const Icon(Icons.school, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              const Text("Terus Belajar!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 8),
                              const Text("Selesaikan lebih banyak modul untuk\nmembuka sertifikat tambahan.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
}
