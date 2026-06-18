import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'translations.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _showProfileToPublic = true;
  bool _showActivityStatus = true;
  bool _allowMessages = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final privacy = data['privacySettings'] as Map<String, dynamic>? ?? {};
        
        if (mounted) {
          setState(() {
            _showProfileToPublic = privacy['showProfileToPublic'] ?? true;
            _showActivityStatus = privacy['showActivityStatus'] ?? true;
            _allowMessages = privacy['allowMessages'] ?? true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'privacySettings': {
          'showProfileToPublic': _showProfileToPublic,
          'showActivityStatus': _showActivityStatus,
          'allowMessages': _allowMessages,
        }
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan privasi berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Tr.get('privacy_settings'),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Privasi Anda',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tentukan siapa yang dapat melihat profil dan aktivitas Anda di platform EduQuiz.',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 32),
                
                _buildToggleCard(
                  Icons.public,
                  'Profil Publik',
                  'Izinkan pengguna lain untuk melihat profil dan skor publik saya.',
                  isDark,
                  _showProfileToPublic,
                  (val) {
                    setState(() => _showProfileToPublic = val);
                    _savePrivacySettings();
                  },
                ),
                _buildToggleCard(
                  Icons.access_time,
                  'Status Aktivitas',
                  'Tampilkan kapan saya terakhir aktif di platform ini.',
                  isDark,
                  _showActivityStatus,
                  (val) {
                    setState(() => _showActivityStatus = val);
                    _savePrivacySettings();
                  },
                ),
                _buildToggleCard(
                  Icons.message_outlined,
                  'Pesan Langsung',
                  'Izinkan guru atau pengguna lain mengirimkan pesan kepada saya.',
                  isDark,
                  _allowMessages,
                  (val) {
                    setState(() => _allowMessages = val);
                    _savePrivacySettings();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildToggleCard(IconData icon, String title, String subtitle, bool isDark, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue[900]?.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.blue[300] : const Color(0xFF0056A8)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Colors.blue[400],
            ),
          ],
        ),
      ),
    );
  }
}
