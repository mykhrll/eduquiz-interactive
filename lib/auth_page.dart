import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();

  // === RATE LIMITING: max 5 kali gagal login dalam 15 menit ===
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get _isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      return false;
    }
    return true;
  }

  /// Sanitize input: trim + remove HTML-like chars
  String _sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }

  Future<void> handleAuth() async {
    if (_isLockedOut) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      _showSnack('Terlalu banyak percobaan. Coba lagi dalam $remaining menit.', isError: true);
      return;
    }

    final emailVal = email.text.trim();
    final passVal = password.text;

    // Validasi dasar
    if (emailVal.isEmpty || passVal.isEmpty) {
      _showSnack('Email dan password wajib diisi.', isError: true);
      return;
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailVal)) {
      _showSnack('Format email tidak valid.', isError: true);
      return;
    }
    if (passVal.length < 6) {
      _showSnack('Password minimal 6 karakter.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // ========== LOGIN ==========
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailVal,
          password: passVal,
        );

        final role = await _getUserRole(cred.user!.uid);

        // Cek verifikasi email HANYA untuk siswa
        if (role != 'guru' && !cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          _showVerificationDialog(cred.user!);
          return;
        }

        // Update emailVerified in Firestore if it is true
        if (cred.user!.emailVerified) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).update({
              'emailVerified': true,
            });
          } catch (e) {
            // Ignore if doc doesn't exist
          }
        }

        _failedAttempts = 0;

        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('login_timestamp', DateTime.now().toIso8601String());
        
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(role: role)),
        );
      } else {
        // ========== REGISTER (SISWA) ==========
        final nameVal = _sanitize(name.text);
        if (nameVal.isEmpty) {
          _showSnack('Nama tidak boleh kosong.', isError: true);
          return;
        }
        if (nameVal.length > 60) {
          _showSnack('Nama terlalu panjang.', isError: true);
          return;
        }

        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailVal,
          password: passVal,
        );

        // Simpan user ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': nameVal,
          'email': emailVal,
          'role': 'siswa',
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
          'xp': 0,
          'level': 1,
          'streak': 0,
        });

        // Kirim email verifikasi
        await cred.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        _showVerificationSentDialog(emailVal);
      }
    } on FirebaseAuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 15));
        _showSnack('Akun dikunci 15 menit karena terlalu banyak percobaan gagal.', isError: true);
      } else {
        _showSnack(_friendlyError(e.code), isError: true);
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan. Silakan coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.mark_email_unread, color: Color(0xFF0056A8)),
          SizedBox(width: 8),
          Text('Verifikasi Email', style: TextStyle(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email ${user.email} belum diverifikasi.\nSilakan cek inbox email Anda.'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                await user.sendEmailVerification();
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack('Email verifikasi telah dikirim ulang.');
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Kirim Ulang Email'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8), foregroundColor: Colors.white),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showVerificationSentDialog(String emailAddr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.mark_email_read, color: Color(0xFF16A34A)),
          SizedBox(width: 8),
          Text('Email Terkirim!', style: TextStyle(fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode verifikasi telah dikirim ke:\n$emailAddr'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
              child: const Text(
                '📧 Buka email Anda dan klik tautan verifikasi, lalu login kembali.',
                style: TextStyle(fontSize: 13, color: Color(0xFF166534)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isLogin = true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8), foregroundColor: Colors.white),
            child: const Text('OK, Ke Halaman Login'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan min. 6 karakter.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Login gagal. Periksa email dan password Anda.';
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
    ));
  }

  Future<String> _getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc['role'] != null) return doc['role'];
      return 'siswa';
    } catch (_) {
      return 'siswa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: isLogin ? _buildLoginView() : _buildRegisterView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icon.png', height: 60,
            errorBuilder: (_, _, _) => const Text('EQ',
                style: TextStyle(color: Color(0xFF0066CC), fontSize: 48, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
        const SizedBox(height: 24),
        const Text('Selamat Datang Kembali', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0056A8)), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Masuk untuk melanjutkan perjalanan belajar Anda.',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A657A)), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _buildLoginField(controller: email, label: 'Email Address', hint: 'emailanda@gmail.com'),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _forgotPassword,
            child: const Text('Lupa Password?',
                style: TextStyle(fontSize: 12, color: Color(0xFF0056A8), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : handleAuth,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056A8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Siswa baru? ', style: TextStyle(color: Color(0xFF4A657A))),
            GestureDetector(
              onTap: () => setState(() => isLogin = false),
              child: const Text('Daftar di sini', style: TextStyle(color: Color(0xFF0056A8), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 14, color: Color(0xFF7A8B99))),
            SizedBox(width: 6),
            Expanded(child: Text('Akun guru dibuat oleh administrator.',
                style: TextStyle(fontSize: 11, color: Color(0xFF7A8B99)))),
          ],
        ),
      ],
    ));
  }

  Widget _buildRegisterView() {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Image.asset('assets/icon.png', height: 60,
            errorBuilder: (_, _, _) => const Text('EQ',
                style: TextStyle(color: Color(0xFF0066CC), fontSize: 48, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
        const SizedBox(height: 24),
        const Text('Daftar ke EduQuiz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        const Text('Buat akun untuk mulai belajar!',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A657A)), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _buildRegisterField(controller: name, label: 'Nama Lengkap', hint: 'Nama Anda', icon: Icons.person_outline),
        const SizedBox(height: 16),
        _buildRegisterField(controller: email, label: 'Email Address', hint: 'emailanda@gmail.com', icon: Icons.mail_outline),
        const SizedBox(height: 16),
        _buildRegisterField(controller: password, label: 'Password (min. 6 karakter)', hint: '••••••••', icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBAE6FD))),
          child: Row(children: const [
            Icon(Icons.mark_email_read, color: Color(0xFF0369A1), size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Setelah daftar, cek email Anda untuk verifikasi akun sebelum bisa login. Cek pada folder spam jika email tidak muncul pada kotak masuk utama.',
                style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)))),
          ]),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Mendaftar sebagai:', style: TextStyle(color: Color(0xFF4A657A), fontSize: 14)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF86EFAC), borderRadius: BorderRadius.circular(20)),
              child: Row(children: const [
                Icon(Icons.face, size: 16, color: Color(0xFF166534)),
                SizedBox(width: 4),
                Text('Siswa', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : handleAuth,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056A8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ]),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sudah punya akun? ', style: TextStyle(color: Color(0xFF4A657A))),
            GestureDetector(
              onTap: () => setState(() => isLogin = true),
              child: const Text('Login', style: TextStyle(color: Color(0xFF0056A8), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ],
      ),
    );
  }

  void _forgotPassword() {
    final emailCtrl = TextEditingController(text: email.text.trim());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan email Anda untuk menerima link reset password.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                hintText: 'email@smk.edu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final e = emailCtrl.text.trim();
              if (e.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: e);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack('Link reset password dikirim ke $e');
              } catch (_) {
                if (context.mounted) _showSnack('Gagal mengirim email reset.', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8), foregroundColor: Colors.white),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginField({required TextEditingController controller, required String label, required String hint}) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          TextField(
            controller: password,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF64748B), size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: label.contains('Email') ? TextInputType.emailAddress : TextInputType.text,
          autofillHints: label.contains('Email') ? const [AutofillHints.email] : 
                         label.contains('Password') ? const [AutofillHints.newPassword] : 
                         const [AutofillHints.name],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
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
