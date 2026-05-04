import 'package:flutter/material.dart';
import 'add_question_page.dart';
import 'quiz_page.dart';
import 'feedback_page.dart';
import 'teacher_result_page.dart';
import 'manage_questions_page.dart';
import 'auth_page.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  const DashboardPage({super.key, required this.role});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EduQuiz Interactive"),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (currentIndex == 0) {
      return _buildHome();
    } else if (currentIndex == 1) {
      return _buildMenu();
    } else {
      return _buildProfile();
    }
  }

  // 🏠 BERANDA (SESUAI ROLE)
  Widget _buildHome() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selamat Datang (${widget.role.toUpperCase()})",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 🔹 GURU
          if (widget.role == "guru") ...[
            _menuCard(
              icon: Icons.add,
              title: "Buat Soal",
              subtitle: "Tambahkan soal pilihan ganda & essay",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddQuestionPage()),
                );
              },
            ),
            _menuCard(
              icon: Icons.list_alt,
              title: "Kelola Soal",
              subtitle: "Lihat, edit, atau hapus soal",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageQuestionsPage(),
                  ),
                );
              },
            ),
            _menuCard(
              icon: Icons.bar_chart,
              title: "Hasil Siswa",
              subtitle: "Lihat nilai & feedback siswa",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherResultPage()),
                );
              },
            ),
          ],

          // 🔹 SISWA
          if (widget.role == "siswa") ...[
            _menuCard(
              icon: Icons.quiz,
              title: "Akses Quiz",
              subtitle: "Kerjakan soal yang tersedia",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(role: widget.role), // ✅ perbaikan
                  ),
                );
              },
            ),
            _menuCard(
              icon: Icons.feedback,
              title: "Feedback",
              subtitle: "Berikan feedback pembelajaran",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackPage()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // 📚 MENU (GURU / SISWA)
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          if (widget.role == "guru") ...[
            _menuCard(
              icon: Icons.add,
              title: "Buat Soal",
              subtitle: "Tambahkan soal pilihan ganda & essay",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddQuestionPage()),
                );
              },
            ),
            _menuCard(
              icon: Icons.list_alt,
              title: "Kelola Soal",
              subtitle: "Lihat, edit, atau hapus soal",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageQuestionsPage(),
                  ),
                );
              },
            ),
            _menuCard(
              icon: Icons.bar_chart,
              title: "Hasil Siswa",
              subtitle: "Lihat nilai & feedback siswa",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherResultPage()),
                );
              },
            ),
          ],

          if (widget.role == "siswa") ...[
            _menuCard(
              icon: Icons.quiz,
              title: "Kerjakan Quiz",
              subtitle: "Mulai mengerjakan soal",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(role: widget.role), // ✅ perbaikan
                  ),
                );
              },
            ),
            _menuCard(
              icon: Icons.feedback,
              title: "Isi Feedback",
              subtitle: "Berikan pendapatmu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackPage()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // 👤 PROFILE
  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF1565C0),
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 15),
          Text(
            "Akun ${widget.role.toUpperCase()}",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  // 🔹 WIDGET CARD MENU
  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
