import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'translations.dart';

class QuestionFormState {
  TextEditingController qCtrl = TextEditingController();
  List<TextEditingController> optCtrls = List.generate(5, (_) => TextEditingController());
  int correctIdx = 0;
  bool isEssay = false;

  void dispose() {
    qCtrl.dispose();
    for (var c in optCtrls) {
      c.dispose();
    }
  }
}

class CreateQuizPage extends StatefulWidget {
  final String? quizId;
  const CreateQuizPage({super.key, this.quizId});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  final List<QuestionFormState> _questionsData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      _loadExistingQuiz();
    } else {
      _questionsData.add(QuestionFormState());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _timeCtrl.dispose();
    for (var q in _questionsData) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingQuiz() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _titleCtrl.text = data['title'] ?? '';
        _subjectCtrl.text = data['subject'] ?? '';
        _timeCtrl.text = (data['timeLimit'] ?? '').toString();
        
        if (data['questions'] != null) {
          final List<dynamic> qList = data['questions'];
          for (var q in qList) {
            final qMap = q as Map<String, dynamic>;
            final qs = QuestionFormState();
            qs.qCtrl.text = qMap['question'] ?? '';
            qs.isEssay = qMap['isEssay'] ?? false;
            if (!qs.isEssay && qMap['options'] != null) {
              final opts = qMap['options'] as List<dynamic>;
              for (int i = 0; i < opts.length && i < 5; i++) {
                qs.optCtrls[i].text = opts[i].toString();
              }
              qs.correctIdx = qMap['correctIndex'] ?? 0;
            }
            _questionsData.add(qs);
          }
          if (_questionsData.isEmpty) {
            _questionsData.add(QuestionFormState());
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading quiz: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addBlankQuestion() {
    setState(() {
      _questionsData.add(QuestionFormState());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questionsData[index].dispose();
      _questionsData.removeAt(index);
      if (_questionsData.isEmpty) {
        _questionsData.add(QuestionFormState());
      }
    });
  }

  Future<void> _saveQuiz() async {
    final title = _titleCtrl.text.trim();
    final subject = _subjectCtrl.text.trim();
    final timeStr = _timeCtrl.text.trim();
    final time = int.tryParse(timeStr);

    if (title.isEmpty || subject.isEmpty || time == null || time <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua detail kuis dengan benar.")),
      );
      return;
    }

    final List<Map<String, dynamic>> questionsToSave = [];
    for (int i = 0; i < _questionsData.length; i++) {
      final q = _questionsData[i];
      if (q.qCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pertanyaan nomor ${i + 1} tidak boleh kosong.")),
        );
        return;
      }
      if (!q.isEssay) {
        bool optsValid = true;
        for (var c in q.optCtrls) {
          if (c.text.trim().isEmpty) optsValid = false;
        }
        if (!optsValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Semua opsi pada soal nomor ${i + 1} harus diisi.")),
          );
          return;
        }
      }
      
      questionsToSave.add({
        'question': q.qCtrl.text.trim(),
        'options': q.isEssay ? [] : q.optCtrls.map((c) => c.text.trim()).toList(),
        'correctIndex': q.isEssay ? null : q.correctIdx,
        'isEssay': q.isEssay,
      });
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (widget.quizId != null) {
          await FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId).update({
            'title': title,
            'subject': subject,
            'timeLimit': time,
            'questions': questionsToSave,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance.collection('quizzes').add({
            'title': title,
            'subject': subject,
            'timeLimit': time,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'questions': questionsToSave,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kuis berhasil disimpan!")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildQuestionCard(int index, bool isDark) {
    final q = _questionsData[index];
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
              Text("Soal ${index + 1}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeQuestion(index),
                tooltip: "Hapus Soal",
              ),
            ],
          ),
          Row(
            children: [
              Text("Tipe Soal: ", style: TextStyle(color: textColor)),
              Switch(
                value: q.isEssay,
                onChanged: (val) => setState(() => q.isEssay = val),
              ),
              Text(q.isEssay ? "Essay" : "Pilihan Ganda", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: q.qCtrl,
            maxLines: 3,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: "Pertanyaan",
              labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0056A8))),
            ),
          ),
          if (!q.isEssay) ...[
            const SizedBox(height: 16),
            Text("Pilihan Jawaban (Pilih yang Benar)", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            ...List.generate(5, (oIdx) {
              final labels = ['A', 'B', 'C', 'D', 'E'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // ignore: deprecated_member_use
                    Radio<int>(
                      value: oIdx,
                      groupValue: q.correctIdx,
                      onChanged: (val) {
                        if (val != null) setState(() => q.correctIdx = val);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: q.optCtrls[oIdx],
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Opsi ${labels[oIdx]}",
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0056A8))),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(Tr.get('create_quiz'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Detail Kuis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Judul Kuis (mis. Ujian Tengah Semester)",
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0056A8))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subjectCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Mata Pelajaran (mis. Matematika)",
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0056A8))),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _timeCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: "Batas Waktu (Menit)",
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0056A8))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(_questionsData.length, (index) => _buildQuestionCard(index, isDark)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addBlankQuestion,
                  icon: Icon(Icons.add, color: isDark ? Colors.blue[300] : const Color(0xFF0056A8)),
                  label: Text("Tambah Soal Baru", style: TextStyle(color: isDark ? Colors.blue[300] : const Color(0xFF0056A8), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? Colors.blue[300]! : const Color(0xFF0056A8)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056A8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Simpan Kuis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
