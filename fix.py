import sys

path = r'c:\Coding\Flutter\eduquiz_interactive\lib\dashboard_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

replacement = """                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Active Now",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildProfileStatCard(Icons.quiz, Tr.get('quizzes_created'), _quizzesCreated.toString(), Colors.blue),
            const SizedBox(width: 12),
            _buildProfileStatCard(Icons.group, Tr.get('total_students'), _totalStudents.toString(), Colors.green),
            const SizedBox(width: 12),
            _buildProfileStatCard(Icons.star, Tr.get('avg_rating'), "${_avgRating.toStringAsFixed(1)}/5", Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                Icons.person_outline,
                Tr.get('account_settings'),
                "Manage your personal information and password",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              _buildSettingsTile(
                Icons.notifications_none,
                Tr.get('notification_pref'),
                "Customize alerts for student submissions",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPreferencesPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              _buildSettingsTile(
                Icons.business,
                Tr.get('school_info'),
                "View curriculum and departmental contacts",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchoolInformationPage()),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Color(0xFFBE123C)),
                ),
                title: Text(
                  Tr.get('logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                ),
                subtitle: const Text(
                  "Sign out of your teacher account",
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  import('package:firebase_auth/firebase_auth.dart').FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== STUDENT PROFILE (DESIGN 5) =====================
  Widget _buildStudentProfile(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
              _loadUserData();
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(color: const Color(0xFFDBEAFE), width: 4),
                    image: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(_userPhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                      ? null
                      : const Icon(Icons.person, color: Colors.white, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0056A8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 12),
                  ),
                ),
                Positioned(
                  bottom: -15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF86EFAC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Color(0xFF166534), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Level $_level",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Text(
            _userName.isNotEmpty ? _userName : 'Loading...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _userSubtitle.isNotEmpty ? _userSubtitle : 'Siswa',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 24),
        // Total XP Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            Tr.get('total_xp'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.bolt, color: Colors.blue, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${Tr.get('keep_it_up_level')} ${_level + 1}.",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _xp.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          " / ${(_level) * 1000}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_xp % 1000) / 1000,
                backgroundColor: const Color(0xFFCBD5E1),
                color: const Color(0xFF0284C7),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Badges row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFFD97706),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _streak.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      Tr.get('day_streak'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFEF3C7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF166534),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "0",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Text(
                      Tr.get('badges_earned'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsMenuCard(
          Icons.edit,
          Tr.get('edit_profile'),
          Colors.blue,
          const Color(0xFFE0F2FE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.workspace_premium,
          Tr.get('my_certificates'),
          Colors.green,
          const Color(0xFFDCFCE7),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCertificatesPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.bar_chart,
          Tr.get('perf_analytics'),
          Colors.orange,
          const Color(0xFFFFEDD5),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerformanceAnalyticsPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsMenuCard(
          Icons.settings,
          Tr.get('account_settings'),
          Colors.purple,
          const Color(0xFFF3E8FF),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingsMenuCard(
          Icons.logout,
          Tr.get('logout'),
          Colors.red,
          const Color(0xFFFEE2E2),
          onTap: () {
            import('package:firebase_auth/firebase_auth.dart').FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
"""

new_lines = lines[:1500] + [replacement] + lines[1547:]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Success')
