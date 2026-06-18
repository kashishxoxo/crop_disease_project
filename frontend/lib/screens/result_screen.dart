import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user_profile_model.dart';
import '../services/advisory_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../services/user_service.dart';

class _LesionPreview extends StatelessWidget {
  const _LesionPreview({
    required this.imageFile,
    this.lesionBox,
  });

  final File imageFile;
  final Map<String, double>? lesionBox;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final box = lesionBox;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(imageFile, fit: BoxFit.cover),
                if (box != null)
                  Positioned(
                    left: (box['x'] ?? 0) * constraints.maxWidth,
                    top: (box['y'] ?? 0) * constraints.maxHeight,
                    width: (box['w'] ?? 0) * constraints.maxWidth,
                    height: (box['h'] ?? 0) * constraints.maxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE53935),
                          width: 2.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0x33E53935),
                      ),
                    ),
                  ),
                if (box != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDDE53935),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Suspected infected region',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.predictedClass,
    required this.confidence,
    this.imageFile,
    this.lesionBox,
    this.scanQuality,
    this.reportInfo,
    this.rejectionReason,
    this.rawPredictedClass,
    this.confidenceMargin,
    this.diagnosisStatus = 'accepted',
    this.diagnosisNote,
    this.predictionSource = 'cloud',
    this.syncPending = false,
  });

  final String predictedClass;
  final double confidence;
  final File? imageFile;
  final Map<String, double>? lesionBox;
  final Map<String, dynamic>? scanQuality;
  final Map<String, dynamic>? reportInfo;
  final String? rejectionReason;
  final String? rawPredictedClass;
  final double? confidenceMargin;
  final String diagnosisStatus;
  final String? diagnosisNote;
  final String predictionSource;
  final bool syncPending;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Future<_ResultContextData> _contextFuture;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext();
  }

  Future<_ResultContextData> _loadContext() async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) {
      return const _ResultContextData();
    }
    final profile = await UserService.getProfile(uid);
    final recentScans = await UserService.getRecentScanHistory(uid, limit: 8);
    return _ResultContextData(profile: profile, recentScans: recentScans);
  }

  Future<void> _scheduleReminder(
    BuildContext context,
    Map<String, dynamic> advisory,
  ) async {
    final uid = AuthService.currentUser()?.uid;
    if (uid == null) return;

    final reminderDays = List<int>.from(
      (advisory['reminder_days'] as List<dynamic>? ?? const <dynamic>[2]),
    );
    final initialDate = DateTime.now().add(
      Duration(days: reminderDays.isEmpty ? 2 : reminderDays.first),
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (selectedDate == null || !mounted) return;

    final displayName =
        advisory['display_name']?.toString() ?? widget.predictedClass;
    final advice = List<String>.from(
      advisory['advice'] as List<dynamic>? ?? const <dynamic>[],
    );

    await ReminderService.addReminder(
      uid: uid,
      title: 'Follow-up for $displayName',
      disease: widget.predictedClass,
      note: advice.isNotEmpty
          ? advice.first
          : 'Review crop condition and apply the planned treatment steps.',
      scheduledFor: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        9,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treatment reminder scheduled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double score = widget.confidence.clamp(0.0, 1.0);
    final bool isOfflineEstimate = widget.predictionSource == 'offline';
    final bool isProvisional = widget.diagnosisStatus == 'provisional';
    final bool isRejected = widget.diagnosisStatus == 'rejected';
    final String confidenceLabel = isOfflineEstimate
        ? 'Offline estimate'
        : isProvisional
            ? 'Provisional confidence'
            : 'Confidence';
    final String confidenceText = '${(score * 100).toStringAsFixed(2)}%';

    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF3),
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<_ResultContextData>(
          future: _contextFuture,
          builder: (context, snapshot) {
            final resultContext = snapshot.data ?? const _ResultContextData();
            final advisory = AdvisoryService.getAdvisory(
              widget.predictedClass,
              profile: resultContext.profile,
              recentScans: resultContext.recentScans,
            );
            final String severity = advisory['severity'] as String;
            final language =
                advisory['language']?.toString() ?? 'English';
            final String alertLabel = AdvisoryService.severityLabel(
              severity,
              language: language,
            );
            final Color alertColor = AdvisoryService.severityColor(severity);
            final List<String> advice =
                List<String>.from(advisory['advice'] as List<dynamic>);
            final List<String> prevention =
                List<String>.from(advisory['prevention'] as List<dynamic>);
            final List<String> contextNotes = List<String>.from(
              advisory['context_notes'] as List<dynamic>? ?? const <dynamic>[],
            );
            final displayName =
                advisory['display_name']?.toString() ?? widget.predictedClass;
            final bool canScheduleReminder =
                !isRejected &&
                !widget.predictedClass.contains('Offline_Field_Review');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.imageFile != null)
                  _LesionPreview(
                    imageFile: widget.imageFile!,
                    lesionBox: widget.lesionBox,
                  ),
                if (widget.imageFile != null) const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F3B26),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$confidenceLabel: $confidenceText',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF31563D),
                  ),
                ),
                if (resultContext.profile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Language: ${resultContext.profile!.language}  •  Soil: ${resultContext.profile!.soilType}  •  Stage: ${resultContext.profile!.cropStage}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF607D66),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (widget.confidenceMargin != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Confidence margin: ${widget.confidenceMargin!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF607D66),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(10),
                    color: alertColor,
                    backgroundColor: const Color(0xFFDDEDDD),
                  ),
                ),
                const SizedBox(height: 18),
                if (isOfflineEstimate ||
                    isProvisional ||
                    widget.syncPending ||
                    (widget.diagnosisNote?.trim().isNotEmpty ?? false)) ...[
                  _DiagnosisStatusCard(
                    diagnosisStatus: widget.diagnosisStatus,
                    diagnosisNote: widget.diagnosisNote,
                    syncPending: widget.syncPending,
                  ),
                  const SizedBox(height: 12),
                ],
                if (isRejected) ...[
                  _RejectionCard(
                    rejectionReason:
                        widget.rejectionReason ?? 'Diagnosis rejected for safety.',
                    rawPredictedClass: widget.rawPredictedClass,
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.scanQuality != null) ...[
                  _ScanQualityCard(scanQuality: widget.scanQuality!),
                  const SizedBox(height: 12),
                ],
                if (widget.reportInfo != null) ...[
                  _BlockchainCard(reportInfo: widget.reportInfo!),
                  const SizedBox(height: 12),
                ],
                _AlertCard(label: alertLabel, color: alertColor),
                if (contextNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _BulletCard(
                    title: language.toLowerCase().contains('hindi')
                        ? 'कस्टम सुझाव'
                        : 'Personalized Notes',
                    icon: Icons.tune,
                    color: const Color(0xFF5E35B1),
                    items: contextNotes,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: !canScheduleReminder
                      ? null
                      : () => _scheduleReminder(context, advisory),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    language.toLowerCase().contains('hindi')
                        ? 'उपचार रिमाइंडर सेट करें'
                        : 'Schedule Treatment Reminder',
                  ),
                ),
                const SizedBox(height: 12),
                _BulletCard(
                  title: language.toLowerCase().contains('hindi')
                      ? 'एआई सलाह'
                      : 'AI Advisory',
                  icon: Icons.lightbulb_outline,
                  color: const Color(0xFF2E7D32),
                  items: advice,
                ),
                const SizedBox(height: 12),
                _BulletCard(
                  title: language.toLowerCase().contains('hindi')
                      ? 'रोकथाम के उपाय'
                      : 'Preventive Measures',
                  icon: Icons.eco_outlined,
                  color: const Color(0xFF558B2F),
                  items: prevention,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultContextData {
  const _ResultContextData({
    this.profile,
    this.recentScans = const [],
  });

  final UserProfileModel? profile;
  final List<Map<String, dynamic>> recentScans;
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            'Alert: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisStatusCard extends StatelessWidget {
  const _DiagnosisStatusCard({
    required this.diagnosisStatus,
    required this.diagnosisNote,
    required this.syncPending,
  });

  final String diagnosisStatus;
  final String? diagnosisNote;
  final bool syncPending;

  @override
  Widget build(BuildContext context) {
    final bool isOffline = diagnosisStatus == 'offline_estimate';
    final bool isProvisional = diagnosisStatus == 'provisional';
    final Color color = isOffline
        ? const Color(0xFF1565C0)
        : isProvisional
            ? const Color(0xFFEF6C00)
            : const Color(0xFF2E7D32);
    final IconData icon = isOffline
        ? Icons.cloud_off_rounded
        : isProvisional
            ? Icons.rule_folder_outlined
            : Icons.check_circle_outline;
    final String title = isOffline
        ? 'Offline estimate mode'
        : isProvisional
            ? 'Provisional cloud result'
            : 'Diagnosis ready';
    final String note = diagnosisNote?.trim().isNotEmpty == true
        ? diagnosisNote!.trim()
        : syncPending
            ? 'This scan has been saved with a pending sync state.'
            : 'Diagnosis completed successfully.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF415447),
            ),
          ),
          if (syncPending) ...[
            const SizedBox(height: 8),
            const Text(
              'Pending sync: save this result and rescan later when the connection is stable for a fully verified backend diagnosis.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF64776A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({
    required this.rejectionReason,
    this.rawPredictedClass,
  });

  final String rejectionReason;
  final String? rawPredictedClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE57373), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFC62828)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Diagnosis rejected for safety',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rejectionReason,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF4A2A2A),
            ),
          ),
          if (rawPredictedClass != null && rawPredictedClass!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Top internal guess: $rawPredictedClass',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7B5555),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanQualityCard extends StatelessWidget {
  const _ScanQualityCard({required this.scanQuality});

  final Map<String, dynamic> scanQuality;

  @override
  Widget build(BuildContext context) {
    final score = (scanQuality['score'] as num?)?.toDouble() ?? 0;
    final label = scanQuality['label']?.toString() ?? 'unknown';
    final sharpness = scanQuality['sharpness'];
    final brightness = scanQuality['brightness'];

    final color = switch (label) {
      'good' => const Color(0xFF2E7D32),
      'moderate' => const Color(0xFFEF6C00),
      _ => const Color(0xFFC62828),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_enhance_outlined, color: color),
              const SizedBox(width: 8),
              Text(
                'Scan Quality: ${label.toUpperCase()}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            color: color,
            backgroundColor: const Color(0xFFE6EEE6),
          ),
          const SizedBox(height: 8),
          Text(
            'Quality Score: ${(score * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (sharpness != null || brightness != null) ...[
            const SizedBox(height: 4),
            Text(
              'Sharpness: ${sharpness ?? '-'}  •  Brightness: ${brightness ?? '-'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF607D66),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlockchainCard extends StatelessWidget {
  const _BlockchainCard({required this.reportInfo});

  final Map<String, dynamic> reportInfo;

  @override
  Widget build(BuildContext context) {
    return _BlockchainCardBody(reportInfo: reportInfo);
  }
}

class _BlockchainCardBody extends StatefulWidget {
  const _BlockchainCardBody({required this.reportInfo});

  final Map<String, dynamic> reportInfo;

  @override
  State<_BlockchainCardBody> createState() => _BlockchainCardBodyState();
}

class _BlockchainCardBodyState extends State<_BlockchainCardBody> {
  bool _verifying = false;
  String? _verifyStatus;
  Color _verifyColor = const Color(0xFF4A4166);

  Future<void> _verify() async {
    final uid = AuthService.currentUser()?.uid;
    final recordId = widget.reportInfo['record_id']?.toString();
    if (uid == null || recordId == null || recordId.isEmpty) {
      setState(() {
        _verifyStatus = 'Missing uid or record id';
        _verifyColor = const Color(0xFFC62828);
      });
      return;
    }

    setState(() {
      _verifying = true;
      _verifyStatus = null;
    });
    try {
      final result =
          await ApiService.verifyReportRecord(uid: uid, recordId: recordId);
      final ok = result['ok'] == true;
      setState(() {
        _verifyStatus = ok ? 'Record verified: intact' : 'Record failed verification';
        _verifyColor = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
      });
    } catch (e) {
      setState(() {
        _verifyStatus = e.toString().replaceFirst('Exception: ', '');
        _verifyColor = const Color(0xFFC62828);
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportInfo = widget.reportInfo;
    final recordId = reportInfo['record_id']?.toString() ?? '-';
    final blockIndex = reportInfo['block_index']?.toString() ?? '-';
    final currentHash = reportInfo['current_hash']?.toString() ?? '-';
    final shortHash =
        currentHash.length > 18 ? '${currentHash.substring(0, 18)}...' : currentHash;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB39DDB), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFF5E35B1)),
              SizedBox(width: 8),
              Text(
                'Secure Report Log',
                style: TextStyle(
                  color: Color(0xFF5E35B1),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Block Index: $blockIndex'),
          Text('Record ID: $recordId'),
          Text(
            'Hash: $shortHash',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF4A4166),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _verifying ? null : _verify,
            icon: _verifying
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified),
            label: Text(_verifying ? 'Verifying...' : 'Verify Record'),
          ),
          if (_verifyStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              _verifyStatus!,
              style: TextStyle(
                color: _verifyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF334B39),
                      ),
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
}
