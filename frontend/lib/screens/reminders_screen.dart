import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Reminders')),
        body: const Center(child: Text('Please login to view reminders.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EC),
      appBar: AppBar(title: const Text('Treatment Reminders')),
      body: StreamBuilder(
        stream: ReminderService.reminderStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          final docs = snapshot.data!.docs;
          final pendingCount = docs.where((doc) {
            final status = doc.data()['status']?.toString() ?? 'pending';
            return status != 'done';
          }).length;
          final doneCount = docs.length - pendingCount;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ReminderOverview(
                  totalCount: docs.length,
                  pendingCount: pendingCount,
                  doneCount: doneCount,
                );
              }

              final doc = docs[index - 1];
              final data = doc.data();
              final title = data['title']?.toString() ?? 'Treatment Reminder';
              final disease = data['disease']?.toString() ?? '-';
              final note = data['note']?.toString() ?? '';
              final status = data['status']?.toString() ?? 'pending';
              final scheduledForRaw = data['scheduledFor'];
              DateTime scheduledFor = DateTime.now();
              if (scheduledForRaw != null) {
                try {
                  scheduledFor = scheduledForRaw.toDate();
                } catch (_) {}
              }

              final isDone = status == 'done';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE3E7DA)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0x162E7D32)
                                  : const Color(0x16C68D4A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.verified_rounded
                                  : Icons.alarm_rounded,
                              color: isDone
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFB66A1E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1C3221),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _ReminderTag(
                                      label: 'Disease: $disease',
                                      tone: const Color(0xFFE5F0E3),
                                      textColor: const Color(0xFF2C6134),
                                    ),
                                    _ReminderTag(
                                      label: isDone ? 'Done' : 'Pending',
                                      tone: isDone
                                          ? const Color(0x162E7D32)
                                          : const Color(0x1AB66A1E),
                                      textColor: isDone
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFB66A1E),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF425847),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F2E8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: Color(0xFF6B5A34),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Scheduled: ${_formatDateTime(scheduledFor)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B5A34),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                ReminderService.updateReminderStatus(
                              uid: uid,
                              reminderId: doc.id,
                              status: isDone ? 'pending' : 'done',
                            ),
                            icon: Icon(
                              isDone
                                  ? Icons.restart_alt_rounded
                                  : Icons.check_circle_outline,
                            ),
                            label: Text(isDone ? 'Mark Pending' : 'Mark Done'),
                          ),
                          TextButton.icon(
                            onPressed: () => ReminderService.deleteReminder(
                              uid: uid,
                              reminderId: doc.id,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE3E7DA)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Color(0xFFB66A1E),
              ),
              SizedBox(height: 12),
              Text(
                'No reminders yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF213627),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Schedule one from the diagnosis result screen to track treatment follow-up.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: Color(0xFF617365),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$date  $hour:$minute $amPm';
  }
}

class _ReminderOverview extends StatelessWidget {
  const _ReminderOverview({
    required this.totalCount,
    required this.pendingCount,
    required this.doneCount,
  });

  final int totalCount;
  final int pendingCount;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A4B2F), Color(0xFF416C48), Color(0xFF6B7F4A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Treatment Timeline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep diagnosis follow-up organized so treatment does not slip.',
            style: TextStyle(
              color: Color(0xD9FFFFFF),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  value: totalCount.toString(),
                  label: 'Total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  value: pendingCount.toString(),
                  label: 'Pending',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  value: doneCount.toString(),
                  label: 'Done',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTag extends StatelessWidget {
  const _ReminderTag({
    required this.label,
    required this.tone,
    required this.textColor,
  });

  final String label;
  final Color tone;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
