import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';

class SchoolInformationPage extends StatefulWidget {
  const SchoolInformationPage({super.key});

  @override
  State<SchoolInformationPage> createState() => _SchoolInformationPageState();
}

class _SchoolInformationPageState extends State<SchoolInformationPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _schoolInfo;

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  Future<void> _loadSchoolInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final info = data['schoolInfo'] as Map<String, dynamic>?;
        if (info != null) {
          _schoolInfo = Map<String, dynamic>.from(info);
        }
      }
    } catch (e) {
      debugPrint('Load school info error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'schoolInfo': _schoolInfo,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved ✓'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _initEmptyData() {
    setState(() {
      _schoolInfo = {
        'institution': '',
        'institutionType': '',
        'department': '',
        'departmentType': '',
        'headName': '',
        'headEmail': '',
        'classes': <Map<String, dynamic>>[],
      };
    });
  }

  Future<void> _editField(String title, String fieldKey, {String? secondFieldKey, String? secondLabel}) async {
    final ctrl = TextEditingController(text: _schoolInfo?[fieldKey] ?? '');
    final ctrl2 = secondFieldKey != null ? TextEditingController(text: _schoolInfo?[secondFieldKey] ?? '') : null;

    final isDark = appThemeMode.value == ThemeMode.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Edit $title', style: TextStyle(color: textColor, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: title,
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (ctrl2 != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: ctrl2,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: secondLabel ?? 'Type',
                  labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _schoolInfo![fieldKey] = ctrl.text.trim();
        if (secondFieldKey != null && ctrl2 != null) {
          _schoolInfo![secondFieldKey] = ctrl2.text.trim();
        }
      });
      await _saveToFirestore();
    }
    ctrl.dispose();
    ctrl2?.dispose();
  }

  Future<void> _editDeptHead() async {
    final nameCtrl = TextEditingController(text: _schoolInfo?['headName'] ?? '');
    final emailCtrl = TextEditingController(text: _schoolInfo?['headEmail'] ?? '');

    final isDark = appThemeMode.value == ThemeMode.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Edit Department Head', style: TextStyle(color: textColor, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _schoolInfo!['headName'] = nameCtrl.text.trim();
        _schoolInfo!['headEmail'] = emailCtrl.text.trim();
      });
      await _saveToFirestore();
    }
    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  Future<void> _editClass(int index) async {
    final classes = List<Map<String, dynamic>>.from(_schoolInfo!['classes'] ?? []);
    final isNew = index < 0;
    final nameCtrl = TextEditingController(text: isNew ? '' : (classes[index]['name'] ?? ''));
    final studentsCtrl = TextEditingController(text: isNew ? '' : '${classes[index]['students'] ?? 0}');

    final isDark = appThemeMode.value == ThemeMode.dark;
    final dialogBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(isNew ? 'Add Class' : 'Edit Class', style: TextStyle(color: textColor, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Class Name',
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: studentsCtrl,
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Students',
                labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          if (!isNew)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056A8)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      final entry = {
        'name': nameCtrl.text.trim(),
        'students': int.tryParse(studentsCtrl.text.trim()) ?? 0,
      };
      setState(() {
        if (isNew) {
          classes.add(entry);
        } else {
          classes[index] = entry;
        }
        _schoolInfo!['classes'] = classes;
      });
      await _saveToFirestore();
    } else if (result == 'delete' && !isNew) {
      setState(() {
        classes.removeAt(index);
        _schoolInfo!['classes'] = classes;
      });
      await _saveToFirestore();
    }
    nameCtrl.dispose();
    studentsCtrl.dispose();
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
                  const Icon(Icons.business_outlined, color: Color(0xFF0056A8)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _schoolInfo == null
                      ? _buildEmptyState(textColor, subtitleColor)
                      : _buildContent(cardColor, textColor, subtitleColor, borderColor, labelColor, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 64, color: subtitleColor),
          const SizedBox(height: 16),
          Text("No School Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text("Add your school details to get started.", style: TextStyle(fontSize: 14, color: subtitleColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _initEmptyData();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Tambah Informasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056A8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color cardColor, Color textColor, Color subtitleColor, Color borderColor, Color labelColor, bool isDark) {
    final classes = List<Map<String, dynamic>>.from(_schoolInfo!['classes'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text("School Information", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        Text("Institutional details and assigned class overview.", style: TextStyle(fontSize: 14, color: subtitleColor)),
        const SizedBox(height: 24),

        // Institution
        _buildInfoCard(
          icon: Icons.account_balance,
          iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
          iconColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          label: "INSTITUTION",
          title: _schoolInfo!['institution'] ?? '',
          subtitle: _schoolInfo!['institutionType'] ?? '',
          onEdit: () => _editField('Institution', 'institution', secondFieldKey: 'institutionType', secondLabel: 'Institution Type'),
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: labelColor,
          subtitleColor: subtitleColor,
        ),

        // Department
        _buildInfoCard(
          icon: Icons.code,
          iconBg: isDark ? const Color(0xFF14532D) : const Color(0xFF86EFAC),
          iconColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D),
          label: "DEPARTMENT",
          title: _schoolInfo!['department'] ?? '',
          subtitle: _schoolInfo!['departmentType'] ?? '',
          onEdit: () => _editField('Department', 'department', secondFieldKey: 'departmentType', secondLabel: 'Department Type'),
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          labelColor: labelColor,
          subtitleColor: subtitleColor,
        ),

        // Department Head
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                child: Icon(Icons.person, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DEPARTMENT HEAD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
                    const SizedBox(height: 4),
                    Text(
                      (_schoolInfo!['headName'] ?? '').isEmpty ? 'Not set' : _schoolInfo!['headName'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      (_schoolInfo!['headEmail'] ?? '').isEmpty ? '' : _schoolInfo!['headEmail'],
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: labelColor, size: 20),
                onPressed: _editDeptHead,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // My Classes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("My Classes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("${classes.length} Assigned", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editClass(-1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0056A8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...List.generate(classes.length, (i) {
          final cls = classes[i];
          return _buildClassCard(
            cls['name'] ?? '',
            '${cls['students'] ?? 0} Students',
            () => _editClass(i),
            cardColor,
            borderColor,
            textColor,
            subtitleColor,
            labelColor,
          );
        }),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color labelColor,
    required Color subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'Not set' : title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                if (subtitle.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: subtitleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(subtitle, style: TextStyle(fontSize: 10, color: subtitleColor)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: labelColor, size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(String title, String students, VoidCallback onEdit, Color cardColor, Color borderColor, Color textColor, Color subtitleColor, Color labelColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              IconButton(
                icon: Icon(Icons.edit, color: labelColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.people_outline, color: Color(0xFF0056A8), size: 16),
              const SizedBox(width: 8),
              Text(students, style: TextStyle(color: subtitleColor)),
            ],
          ),
        ],
      ),
    );
  }
}
