import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Project')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InfoCard(
            title: 'AI Model',
            text:
                'Disease classification is powered by MobileNetV2 transfer learning trained on PlantVillage classes.',
            icon: Icons.memory,
          ),
          _InfoCard(
            title: 'Flask Backend',
            text:
                'Captured crop images are sent to a Flask API endpoint that returns predicted class and confidence.',
            icon: Icons.dns_outlined,
          ),
          _InfoCard(
            title: 'Flutter Frontend',
            text:
                'The Android app provides a fast scan flow, premium result visualization, history, and advisory insights.',
            icon: Icons.phone_android,
          ),
          _InfoCard(
            title: 'Advisory Purpose',
            text:
                'The system helps farmers make faster decisions by combining prediction confidence with practical prevention steps.',
            icon: Icons.eco_outlined,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x162E7D32),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(fontSize: 14, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
