import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateTeacherDialog extends StatefulWidget {
  final String teacherId;
  const RateTeacherDialog({super.key, required this.teacherId});

  @override
  State<RateTeacherDialog> createState() => _RateTeacherDialogState();
}

class _RateTeacherDialogState extends State<RateTeacherDialog> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Create a rating document
      await FirebaseFirestore.instance.collection('teacher_ratings').doc('${widget.teacherId}_$userId').set({
        'teacherId': widget.teacherId,
        'studentId': userId,
        'rating': _rating,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the teacher's profile average rating
      final teacherDoc = await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).get();
      if (teacherDoc.exists) {
        final data = teacherDoc.data()!;
        final currentTotalRating = (data['totalRating'] ?? 0) as num;
        final currentRatingCount = (data['ratingCount'] ?? 0) as num;
        
        await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).update({
          'totalRating': currentTotalRating + _rating,
          'ratingCount': currentRatingCount + 1,
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih atas penilaianmu!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim rating: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nilai Gurumu', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bagaimana menurutmu cara guru mengajar dan materi kuis ini?', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () {
                  setState(() => _rating = index + 1);
                },
              );
            }),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kirim Rating'),
        ),
      ],
    );
  }
}
