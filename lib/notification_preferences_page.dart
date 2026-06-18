import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool newSubmission = true;
  bool lowScore = true;
  bool weeklySummary = true;
  bool systemUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final prefs = data['notificationPrefs'] as Map<String, dynamic>?;
        if (prefs != null) {
          newSubmission = prefs['newSubmission'] ?? true;
          lowScore = prefs['lowScore'] ?? true;
          weeklySummary = prefs['weeklySummary'] ?? true;
          systemUpdates = prefs['systemUpdates'] ?? false;
        }
      }
    } catch (e) {
      debugPrint('Load notification prefs error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'notificationPrefs': {
          'newSubmission': newSubmission,
          'lowScore': lowScore,
          'weeklySummary': weeklySummary,
          'systemUpdates': systemUpdates,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully ✓'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400]! : const Color(0xFF475569);
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);
    final labelColor = isDark ? Colors.grey[500]! : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "EduQuiz",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0056A8)),
                    ),
                  ),
                  const Icon(Icons.notifications_outlined, color: Color(0xFF0056A8)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          "Notification\nPreferences",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Manage how and when you receive alerts for your classes.",
                          style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Academic Alerts
                        _buildSectionCard(
                          Icons.school_outlined,
                          "Academic Alerts",
                          [
                            _buildSwitchTile("New Student Submission", "Receive an alert when a student completes and submits an assignment or quiz.", newSubmission, (v) => setState(() => newSubmission = v), textColor, labelColor),
                            _buildSwitchTile("Low Score Alerts", "Get notified immediately if a student scores below 60% on a major assessment.", lowScore, (v) => setState(() => lowScore = v), textColor, labelColor),
                          ],
                          cardColor,
                          borderColor,
                          textColor,
                        ),

                        // Reports
                        _buildSectionCard(
                          Icons.insert_drive_file_outlined,
                          "Reports",
                          [
                            _buildSwitchTile("Weekly Class Summary", "A comprehensive overview of class performance, completion rates, and upcoming deadlines sent every Friday.", weeklySummary, (v) => setState(() => weeklySummary = v), textColor, labelColor),
                          ],
                          cardColor,
                          borderColor,
                          textColor,
                        ),

                        // System
                        _buildSectionCard(
                          Icons.update,
                          "System",
                          [
                            _buildSwitchTile("System Updates", "Stay informed about new EduQuiz features, scheduled maintenance, and platform announcements.", systemUpdates, (v) => setState(() => systemUpdates = v), textColor, labelColor),
                          ],
                          cardColor,
                          borderColor,
                          textColor,
                        ),

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Cancel", style: TextStyle(color: Color(0xFF0056A8), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _savePreferences,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0056A8),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text("Save Preferences", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(IconData icon, String title, List<Widget> children, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, Color textColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: labelColor, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2196F3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}
