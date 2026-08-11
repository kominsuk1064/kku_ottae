// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    final text = _commentController.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('코멘트를 5자 이상 입력해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': uid,
        'rating': _rating,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('피드백이 정상적으로 전송되었습니다!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('전송 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('피드백 보내기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('앱 전반에 대한 만족도를 남겨주세요!', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: _rating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (value) =>
                  setState(() => _rating = value.toInt()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '코멘트를 입력해 주세요 (5자 이상)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('보내기'),
            ),
          ],
        ),
      ),
    );
  }
}
