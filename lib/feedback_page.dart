import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_answer_page.dart';

class FeedbackPage extends StatefulWidget {
  final String quizId;
  final String subjectName;
  final String? resultId;
  const FeedbackPage({super.key, required this.quizId, required this.subjectName, this.resultId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  TextEditingController controller = TextEditingController();
  
  String selectedUnderstanding = "";
  List<String> selectedTopics = [];
  
  final List<Map<String, dynamic>> understandingLevels = [
    {"icon": "🤩", "label": "Sangat\nPaham"},
    {"icon": "🤔", "label": "Kurang\nPaham"},
    {"icon": "😵", "label": "Belum\nPaham"},
  ];
  
  final List<String> topics = ["Variabel", "Tipe Data", "Looping (For/While)", "Lainnya"];

  Future<void> sendFeedback() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

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

    String fullFeedback = "";
    if (selectedUnderstanding.isNotEmpty) fullFeedback += "Pemahaman: $selectedUnderstanding.\n";
    if (selectedTopics.isNotEmpty) fullFeedback += "Sulit di: ${selectedTopics.join(', ')}.\n";
    if (controller.text.trim().isNotEmpty) fullFeedback += "Catatan: ${controller.text.trim()}";

    if (fullFeedback.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi feedback terlebih dahulu!")));
      }
      return;
    }

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': userId,
      'userName': userName,
      'quizId': widget.quizId,
      'subjectName': widget.subjectName,
      'feedback': fullFeedback,
      'resultId': widget.resultId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feedback terkirim")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.quizId == 'all' ? "Feedback ${widget.subjectName}" : "Feedback", style: const TextStyle(color: Color(0xFF0056A8), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: widget.quizId == 'all' ? _buildFeedbackList() : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Bagaimana\nbelajarmu hari ini?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.2),
              ),
              const SizedBox(height: 12),
              const Text(
                "Kami ingin tahu pendapatmu agar bisa\nmembuat EduQuiz lebih baik lagi untukmu.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              
              // Form Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Last Material
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.code, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("MATERI TERAKHIR", style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(widget.subjectName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Understanding Level
                    const Text("Tingkat Pemahamanmu", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: understandingLevels.map((level) {
                        bool isSelected = selectedUnderstanding == level['label'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedUnderstanding = level['label'];
                            });
                          },
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFEDD5) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Text(level['icon'], style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 8),
                                Text(
                                  level['label'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF9A3412) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Difficult Parts
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bagian mana yang paling sulit?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: topics.map((topic) {
                              bool isSelected = selectedTopics.contains(topic);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedTopics.remove(topic);
                                    } else {
                                      selectedTopics.add(topic);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    topic,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Optional Text
                    const Text("Ceritakan lebih lanjut (Opsional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Misal: Penjelasan tentang Looping terlalu cepat...",
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: sendFeedback,
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      label: const Text("Kirim Feedback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056A8),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              // Dummy Robot Image Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/robot.png'), // Placeholder
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Center(child: Icon(Icons.smart_toy, size: 64, color: Color(0xFF94A3B8))),
              ),
              const SizedBox(height: 12),
              const Text(
                "Setiap masukanmu sangat berharga untuk kemajuan\nkelas kita.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // First get teacher's quiz IDs for this subject, then show feedback for those quizzes
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('quizzes')
          .where('createdBy', isEqualTo: currentUserId)
          .get(),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Get quiz IDs for this subject
        final quizIds = <String>[];
        for (var doc in (quizSnapshot.data?.docs ?? [])) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['subject'] == widget.subjectName) {
            quizIds.add(doc.id);
          }
        }
        
        if (quizIds.isEmpty) {
          return const Center(child: Text("Belum ada kuis untuk mata pelajaran ini."));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('feedback')
              .where('quizId', whereIn: quizIds.take(10).toList()) // Firestore whereIn max 10
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Belum ada feedback dari siswa."));
            }

            // Sort client-side by createdAt
            final docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return (bTime as Timestamp).compareTo(aTime as Timestamp);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final userName = data['userName'] ?? 'Siswa';
                final feedback = data['feedback'] ?? '';
                final resultId = data['resultId'];
                final feedbackQuizId = data['quizId'];
                final studentUserId = data['userId'];

                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFDBEAFE),
                            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'S', style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(feedback, style: TextStyle(color: isDark ? Colors.grey[300] : const Color(0xFF475569))),
                      const SizedBox(height: 12),
                      if (feedbackQuizId != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              String? targetResultId = resultId;
                              
                              // Fallback for old data that doesn't have resultId saved in feedback
                              if (targetResultId == null && studentUserId != null) {
                                try {
                                  // Show loading indicator
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Mencari jawaban siswa...'), duration: Duration(seconds: 1)),
                                    );
                                  }
                                  
                                  final resultQuery = await FirebaseFirestore.instance
                                      .collection('results')
                                      .where('quizId', isEqualTo: feedbackQuizId)
                                      .where('userId', isEqualTo: studentUserId)
                                      .orderBy('createdAt', descending: true)
                                      .limit(1)
                                      .get();
                                      
                                  if (resultQuery.docs.isNotEmpty) {
                                    targetResultId = resultQuery.docs.first.id;
                                  }
                                } catch (e) {
                                  // Ignore error
                                }
                              }

                              if (targetResultId != null && context.mounted) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ReviewAnswerPage(quizId: feedbackQuizId, resultId: targetResultId!)
                                ));
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Data jawaban kuis ini tidak ditemukan atau sudah dihapus.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text("Lihat Jawaban"),
                          ),
                        )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
