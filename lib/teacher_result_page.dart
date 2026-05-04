import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherResultPage extends StatelessWidget {
  const TeacherResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hasil & Feedback"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Nilai Siswa"),
              Tab(text: "Feedback"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Hasil quiz
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('results')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada hasil quiz"));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final userName = data['userName'] ?? data['userId'] ?? '-';
                    return Card(
                      child: ListTile(
                        title: Text("Nilai: ${data['score'] ?? '-'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Siswa: $userName"),
                            Text("Essay: ${data['essay'] ?? '-'}"),
                            Text(
                              "Tanggal: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : '-'}",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Tab 2: Feedback
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada feedback"));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final userName = data['userName'] ?? data['userId'] ?? '-';
                    return Card(
                      child: ListTile(
                        title: Text("Dari: $userName"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['feedback'] ?? ''),
                            Text(
                              "Waktu: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : '-'}",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
