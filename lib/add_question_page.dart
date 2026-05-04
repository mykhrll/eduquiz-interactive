import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({super.key});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  // --- Form Pilihan Ganda ---
  final _pgQuestionCtrl = TextEditingController();
  final List<TextEditingController> _pgOptionCtrls = List.generate(
    5,
    (_) => TextEditingController(),
  );
  int _correctAnswerIndex = 0;

  // --- Form Essay ---
  final _essayQuestionCtrl = TextEditingController();

  // 🔹 Simpan soal PG
  Future<void> _savePG() async {
    if (_pgQuestionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Soal PG tidak boleh kosong")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('questions').add({
      'question': _pgQuestionCtrl.text.trim(),
      'options': _pgOptionCtrls.map((c) => c.text.trim()).toList(),
      'correctIndex': _correctAnswerIndex,
      'isEssay': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // reset form
    _pgQuestionCtrl.clear();
    for (var c in _pgOptionCtrls) {
      c.clear();
    }
    setState(() {
      _correctAnswerIndex = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Soal PG berhasil disimpan")),
      );
    }
  }

  // 🔹 Simpan soal Essay
  Future<void> _saveEssay() async {
    if (_essayQuestionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Soal Essay tidak boleh kosong")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('questions').add({
      'question': _essayQuestionCtrl.text.trim(),
      'options': [],
      'correctIndex': null,
      'isEssay': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _essayQuestionCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Soal Essay berhasil disimpan")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Soal")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========================
          // BAGIAN PILIHAN GANDA
          // ========================
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Soal Pilihan Ganda",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pgQuestionCtrl,
                    decoration: const InputDecoration(
                      labelText: "Pertanyaan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Opsi Jawaban",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _correctAnswerIndex,
                            onChanged: (v) {
                              setState(() {
                                _correctAnswerIndex = v!;
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _pgOptionCtrls[i],
                              decoration: InputDecoration(
                                hintText: "Opsi ${i + 1}",
                                border: const OutlineInputBorder(),
                                suffixIcon: i == _correctAnswerIndex
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _savePG,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Soal PG"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ========================
          // BAGIAN ESSAY
          // ========================
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Soal Essay",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _essayQuestionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Pertanyaan Essay",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveEssay,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Soal Essay"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pgQuestionCtrl.dispose();
    for (var c in _pgOptionCtrls) {
      c.dispose();
    }
    _essayQuestionCtrl.dispose();
    super.dispose();
  }
}
