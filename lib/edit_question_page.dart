import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditQuestionPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditQuestionPage({
    super.key,
    required this.docId,
    required this.currentData,
  });

  @override
  State<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<EditQuestionPage> {
  late TextEditingController questionCtrl;
  late List<TextEditingController> optionCtrls;
  late int correctIndex;
  late bool isEssay;

  @override
  void initState() {
    super.initState();
    final data = widget.currentData;
    isEssay = data['isEssay'] ?? false;
    questionCtrl = TextEditingController(text: data['question'] ?? '');
    if (!isEssay) {
      final options = List<String>.from(data['options'] ?? []);
      optionCtrls = List.generate(
        options.length,
        (i) => TextEditingController(text: options[i]),
      );
      correctIndex = data['correctIndex'] ?? 0;
    } else {
      optionCtrls = [];
      correctIndex = 0;
    }
  }

  Future<void> updateQuestion() async {
    if (questionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pertanyaan tidak boleh kosong")),
      );
      return;
    }

    final updatedData = <String, dynamic>{
      'question': questionCtrl.text.trim(),
      'isEssay': isEssay,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!isEssay) {
      updatedData['options'] = optionCtrls.map((c) => c.text.trim()).toList();
      updatedData['correctIndex'] = correctIndex;
    }

    await FirebaseFirestore.instance
        .collection('questions')
        .doc(widget.docId)
        .update(updatedData);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Soal berhasil diperbarui")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEssay ? "Edit Soal Essay" : "Edit Soal PG")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: questionCtrl,
            decoration: const InputDecoration(labelText: "Pertanyaan"),
          ),
          const SizedBox(height: 16),
          if (!isEssay) ...[
            const Text("Opsi Jawaban"),
            const SizedBox(height: 8),
            for (int i = 0; i < optionCtrls.length; i++)
              Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<int>(
                    value: i,
                    groupValue: correctIndex,
                    onChanged: (v) => setState(() => correctIndex = v!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: optionCtrls[i],
                      decoration: InputDecoration(
                        hintText: "Opsi ${i + 1}",
                        suffixIcon: i == correctIndex
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
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: updateQuestion,
            child: const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    questionCtrl.dispose();
    for (var c in optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }
}
