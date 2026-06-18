import 'app_state.dart';

class Tr {
  static String get(String key) {
    final isEn = appLocale.value.languageCode == 'en';
    return _strings[key]?[isEn ? 1 : 0] ?? key;
  }



  // Key: [Indonesian, English]
  static final Map<String, List<String>> _strings = {
    'notification_desc': ['Sesuaikan peringatan untuk tugas siswa', 'Customize alerts for student submissions'],
    'certificates_desc': ['Lihat pencapaian dan sertifikat', 'View achievements and certificates'],
    'quiz_details': ['Detail Kuis', 'Quiz Details'],
    'quiz_not_found': ['Kuis tidak ditemukan', 'Quiz not found'],
    'untitled_quiz': ['Kuis Tanpa Judul', 'Untitled Quiz'],
    'general': ['Umum', 'General'],
    'minutes': ['Menit', 'Minutes'],
    'start_quiz': ['Mulai Kerjakan', 'Start Quiz'],
    'teacher': ['Guru', 'Teacher'],
    'student': ['Siswa', 'Student'],
    'edit_profile': ['Edit Profil', 'Edit Profile'],
    // Navigation
    'nav_home': ['Beranda', 'Home'],
    'nav_quizzes': ['Kuis', 'Quizzes'],
    'nav_results': ['Hasil', 'Results'],
    'nav_rankings': ['Peringkat', 'Rankings'],
    'nav_profile': ['Profil', 'Profile'],
    
    // Teacher Home
    'welcome_back': ['Selamat Datang Kembali', 'Welcome back'],
    'teacher_home_subtitle': ['Berikut adalah aktivitas kelas Anda hari ini.', 'Here is what\'s happening with your classes today.'],
    'create_quiz': ['Buat Kuis', 'Create Quiz'],
    'manage': ['Kelola', 'Manage'],
    'active_quizzes': ['Kuis Aktif', 'Active Quizzes'],
    'total_students': ['Total Siswa', 'Total Students'],
    'avg_completion': ['Rata-rata Penyelesaian', 'Avg. Completion'],
    'recent_quizzes': ['Kuis Terbaru', 'Recent Quizzes'],
    'view_all': ['Lihat Semua', 'View All'],
    'needs_attention': ['Perlu Perhatian', 'Needs Attention'],
    'low_scores_detected': ['Nilai Rendah Terdeteksi', 'Low Scores Detected'],
    'keep_it_up_level': ['Pertahankan Level', 'Keep It Up Level'],
    'teacher_profile': ['Profil Guru', 'Teacher Profile'],
    'student_profile': ['Profil Siswa', 'Student Profile'],
    'student_feedback': ['Umpan Balik Siswa', 'Student Feedback'],
    'recent_feedback': ['Umpan Balik Terbaru', 'Recent Feedback'],
    'no_quizzes_available': ['Belum ada kuis tersedia', 'No quizzes available'],
    'no_data': ['Belum ada data', 'No data available'],
    'no_rankings': ['Belum ada data peringkat', 'No ranking data available'],
    'no_feedback': ['Belum ada umpan balik dari siswa', 'No feedback from students yet'],
    'day_streak': ['HARI BERTURUT-TURUT', 'DAY STREAK'],
    'badges_earned': ['LENCANA DIDAPAT', 'BADGES EARNED'],
    
    // Student Home
    'ready_level_up': ['Siap naik level', 'Ready to level up'],
    'new_quizzes_waiting': ['Ada kuis baru yang menunggumu. Ayo dapatkan nilai sempurna!', 'You have new quizzes waiting. Let\'s get that perfect score!'],
    'start_next_quiz': ['Mulai Kuis Berikutnya', 'Start Next Quiz'],
    'total_xp': ['Total XP', 'Total XP'],
    'weekly_leaderboard': ['Papan Peringkat Mingguan', 'Weekly Leaderboard'],
    'up_next': ['Selanjutnya', 'Up Next'],
    'start': ['Mulai', 'Start'],
    'xp_to_level': ['XP menuju Level', 'XP to Level'],
    
    // Profile
    'active_now': ['Aktif Sekarang', 'Active Now'],
    'quizzes_created': ['Kuis Dibuat', 'Quizzes Created'],
    'avg_rating': ['Rata-rata Penilaian', 'Avg. Rating'],
    'completed_quizzes': ['Kuis Diselesaikan', 'Completed Quizzes'],
    'completed_quiz': ['Kamu telah menyelesaikan kuis Software Engineering Basics!', 'You have completed the Software Engineering Basics quiz!'],
    'average_score': ['Nilai Rata-rata', 'Average Score'],
    'account_settings': ['Pengaturan Akun', 'Account Settings'],
    'account_settings_desc': ['Kelola informasi personal dan kata sandi Anda', 'Manage your personal information and password'],
    'notification_pref': ['Preferensi Notifikasi', 'Notification Preferences'],
    'notification_pref_desc': ['Atur peringatan untuk tugas siswa', 'Customize alerts for student submissions'],
    'school_info': ['Informasi Sekolah', 'School Information'],
    'school_info_desc': ['Lihat kurikulum dan kontak departemen', 'View curriculum and departmental contacts'],
    'my_certificates': ['Sertifikat Saya', 'My Certificates'],
    'my_certificates_desc': ['Lihat sertifikat dan pencapaian Anda', 'View earned certificates and achievements'],
    'perf_analytics': ['Analitik Performa', 'Performance Analytics'],
    'perf_analytics_desc': ['Rincian skor kuis Anda', 'Detailed breakdown of your quiz scores'],
    'support_feedback': ['Bantuan & Umpan Balik', 'Support Feedback'],
    'support_feedback_desc': ['Laporkan masalah atau berikan saran', 'Report issues or suggest improvements'],
    'logout': ['Keluar', 'Logout'],
    'logout_desc': ['Keluar dari akun Anda', 'Sign out of your account'],
    'guru': ['Guru', 'Teacher'],
    'siswa': ['Siswa', 'Student'],
    'level': ['Tingkat', 'Level'],
    
    // Settings
    'settings_title': ['Pengaturan Akun', 'Account Settings'],
    'settings_subtitle': ['Kelola profil dan preferensi keamanan Anda.', 'Manage your professional profile and security preferences.'],
    'personal_info': ['Info Personal', 'Personal Info'],
    'personal_info_desc': ['Perbarui nama, sekolah, dan kontak Anda', 'Update your name, school, and contact details'],
    'change_password': ['Ubah Kata Sandi', 'Change Password'],
    'change_password_desc': ['Pastikan akun Anda tetap aman', 'Ensure your account remains secure'],
    'privacy_settings': ['Pengaturan Privasi', 'Privacy Settings'],
    'privacy_settings_desc': ['Atur apa yang bisa dilihat orang lain', 'Manage what students and colleagues can see'],
    'language': ['Bahasa', 'Language'],
    'language_desc': ['Pilih bahasa aplikasi (Indonesia / English)', 'Choose app language (Indonesia / English)'],
    'theme': ['Tema', 'Theme'],
    'theme_desc': ['Pilih tema Terang atau Gelap', 'Choose Light or Dark theme'],
  };
}
