import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String summary;

  const SummaryCard({super.key, required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
