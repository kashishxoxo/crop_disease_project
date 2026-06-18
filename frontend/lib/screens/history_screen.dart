import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Disease History')),
        body: const Center(child: Text('Please login to view your history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Disease History')),
      body: StreamBuilder(
        stream: UserService.scanHistoryStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No scans yet.\nScan a crop from dashboard to build history.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index].data();
              final String disease = item['predictedClass']?.toString() ?? '-';
              final double confidence =
                  (item['confidence'] as num?)?.toDouble() ?? 0;
              final predictionSource =
                  item['predictionSource']?.toString() ?? 'cloud';
              final diagnosisStatus =
                  item['diagnosisStatus']?.toString() ?? 'accepted';
              final diagnosisNote = item['diagnosisNote']?.toString() ?? '';
              final scannedAtRaw = item['scannedAt'];
              DateTime scannedAt = DateTime.now();
              if (scannedAtRaw != null) {
                try {
                  scannedAt = scannedAtRaw.toDate();
                } catch (_) {}
              }
              final String confidenceText =
                  '${(confidence * 100).toStringAsFixed(2)}%';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF1565C0)),
                  title: Text(disease),
                  subtitle: Text(
                    'Confidence: $confidenceText\n'
                    '${_historyModeLabel(predictionSource, diagnosisStatus)}\n'
                    '${diagnosisNote.isEmpty ? '' : '$diagnosisNote\n'}'
                    'Scanned: ${_formatDateTime(scannedAt)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$date  $hour:$minute $amPm';
  }

  String _historyModeLabel(String predictionSource, String diagnosisStatus) {
    if (predictionSource == 'offline') {
      return 'Mode: Offline estimate';
    }
    if (diagnosisStatus == 'provisional') {
      return 'Mode: Provisional cloud result';
    }
    return 'Mode: Verified cloud result';
  }
}
