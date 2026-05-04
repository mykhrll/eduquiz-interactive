import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();

  // ❌ Tidak ada lagi dropdown role – siswa tidak bisa pilih role

  Future<void> handleAuth() async {
    try {
      if (isLogin) {
        // ========== LOGIN ==========
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text.trim(),
            );

        // Ambil role dari Firestore berdasarkan UID
        String role = await _getUserRole(userCredential.user!.uid);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
        );
      } else {
        // ========== REGISTER (SISWA SAJA) ==========
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text.trim(),
            );

        // Simpan data siswa ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': name.text.trim(),
              'email': email.text.trim(),
              'role': 'siswa',
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!mounted) return;
        // Langsung ke dashboard siswa
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage(role: 'siswa')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  /// Mengambil role user dari Firestore.
  /// Jika dokumen tidak ditemukan (misal akun guru yg dibuat manual),
  /// fallback ke "siswa" atau bisa juga throw error.
  Future<String> _getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc['role'] != null) {
        return doc['role'];
      }
      // Fallback jika data role tidak ada
      return 'siswa';
    } catch (_) {
      return 'siswa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "EduQuiz Interactive",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Nama hanya untuk registrasi
                if (!isLogin)
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: "Nama"),
                  ),

                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),

                // ❌ Tidak ada dropdown role lagi
                // Tampilkan keterangan bahwa registrasi adalah sebagai Siswa
                if (!isLogin) ...[
                  const SizedBox(height: 4),
                  const Text(
                    "Anda akan terdaftar sebagai Siswa",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleAuth,
                  child: Text(isLogin ? "Login" : "Daftar"),
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? "Belum punya akun?" : "Sudah punya akun?",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }
}
