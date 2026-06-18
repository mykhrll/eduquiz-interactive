import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'privacy_settings_page.dart';
import 'translations.dart';
import 'app_state.dart';
import 'auth_page.dart';
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            final isDark = themeMode == ThemeMode.dark;
            final isEn = locale.languageCode == 'en';
            
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
              body: SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Tr.get('settings_title'),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.blue[300] : const Color(0xFF0056A8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(Tr.get('settings_title'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Text(Tr.get('settings_subtitle'), style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF475569), height: 1.4)),
                          const SizedBox(height: 24),
                          
                          _buildSettingCard(
                            Icons.person_outline,
                            Tr.get('personal_info'),
                            Tr.get('personal_info_desc'),
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                            },
                          ),
                          _buildSettingCard(
                            Icons.lock_outline,
                            Tr.get('change_password'),
                            Tr.get('change_password_desc'),
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
                            },
                          ),
                          _buildSettingCard(
                            Icons.visibility_outlined,
                            Tr.get('privacy_settings'),
                            Tr.get('privacy_settings_desc'),
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsPage()));
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          
                          _buildToggleSettingCard(
                            Icons.language,
                            Tr.get('language'),
                            Tr.get('language_desc'),
                            isDark: isDark,
                            value: isEn,
                            onChanged: (val) {
                              appLocale.value = val ? const Locale('en', 'US') : const Locale('id', 'ID');
                            },
                            activeText: 'EN',
                            inactiveText: 'ID',
                          ),
                          _buildToggleSettingCard(
                            Icons.dark_mode_outlined,
                            Tr.get('theme'),
                            Tr.get('theme_desc'),
                            isDark: isDark,
                            value: isDark,
                            onChanged: (val) {
                              appThemeMode.value = val ? ThemeMode.dark : ThemeMode.light;
                            },
                            activeText: 'Dark',
                            inactiveText: 'Light',
                          ),
                          
                          const SizedBox(height: 32),
                          const Divider(height: 1),
                          const SizedBox(height: 32),
                          
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AuthPage()),
                                    (route) => false,
                                  );
                                }
                              },
                              icon: const Icon(Icons.logout, color: Color(0xFFBE123C)),
                              label: Text(Tr.get('logout'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBE123C), fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingCard(IconData icon, String title, String subtitle, {String? badge, VoidCallback? onTap, bool isDark = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.blue[900]?.withValues(alpha: 0.3) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? Colors.blue[300] : const Color(0xFF0056A8)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), height: 1.4)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF14532D))),
              ),
            Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleSettingCard(IconData icon, String title, String subtitle, {required bool isDark, required bool value, required ValueChanged<bool> onChanged, required String activeText, required String inactiveText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDark ? Colors.blue[900]?.withValues(alpha: 0.3) : const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? Colors.blue[300] : const Color(0xFF0056A8)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), height: 1.4)),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.blue[200],
          activeThumbColor: Colors.blue[400],
        ),
      ),
    );
  }
}
