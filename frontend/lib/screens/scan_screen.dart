import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/prediction_model.dart';
import '../models/user_profile_model.dart';
import '../services/advisory_service.dart';
import '../services/alert_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_diagnosis_service.dart';
import '../services/user_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  static const String _unknownLabel = 'Unknown_or_Unsupported';
  static const Duration _unsupportedCaptureCooldown =
      Duration(milliseconds: 800);
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;
  XFile? _capturedImage;
  String? _cameraError;
  bool _isLoading = false;
  DateTime? _captureDisabledUntil;
  late final AnimationController _lineAnimationController;

  @override
  void initState() {
    super.initState();
    _lineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _initializeCameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera available on this device.';
        });
        return;
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to initialize camera.';
      });
    }
  }

  Future<void> _captureAndPredict() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isLoading) {
      return;
    }
    final disabledUntil = _captureDisabledUntil;
    if (disabledUntil != null && DateTime.now().isBefore(disabledUntil)) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile image = await controller.takePicture();
      final File imageFile = File(image.path);
      setState(() {
        _capturedImage = image;
      });

      final uid = AuthService.currentUser()?.uid;
      PredictionModel prediction;
      try {
        prediction = _normalizePredictionForDisplay(
          await ApiService.predictDisease(imageFile, uid: uid),
        );
      } on SocketException {
        prediction = await _buildOfflinePrediction(
          uid: uid,
          reason:
              'Network or backend is unreachable, so the app switched to offline estimate mode.',
        );
      } on TimeoutException {
        prediction = await _buildOfflinePrediction(
          uid: uid,
          reason:
              'The network is too slow for a stable backend response, so the app switched to offline estimate mode.',
        );
      } on HttpException {
        prediction = await _buildOfflinePrediction(
          uid: uid,
          reason:
              'The backend could not finish the diagnosis right now, so the app switched to offline estimate mode.',
        );
      } on FormatException {
        prediction = await _buildOfflinePrediction(
          uid: uid,
          reason:
              'The backend response was incomplete, so the app switched to offline estimate mode.',
        );
      }

      if (_shouldTreatAsUnsupported(prediction)) {
        if (!mounted) return;
        await _showUnsupportedImageDialog(
          _friendlyUnknownMessage(prediction),
        );
        if (!mounted) return;
        setState(() {
          _capturedImage = null;
          _captureDisabledUntil =
              DateTime.now().add(_unsupportedCaptureCooldown);
        });
        return;
      }

      if (uid != null) {
        await _persistPrediction(uid: uid, prediction: prediction);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            predictedClass: prediction.predictedClass,
            confidence: prediction.confidence,
            imageFile: imageFile,
            lesionBox: prediction.lesionBox,
            scanQuality: prediction.scanQuality,
            reportInfo: prediction.reportInfo,
            rejectionReason: prediction.rejectionReason,
            rawPredictedClass: prediction.rawPredictedClass,
            confidenceMargin: prediction.confidenceMargin,
            diagnosisStatus: prediction.diagnosisStatus,
            diagnosisNote: prediction.diagnosisNote,
            predictionSource: prediction.predictionSource,
            syncPending: prediction.syncPending,
          ),
        ),
      );
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<PredictionModel> _buildOfflinePrediction({
    required String? uid,
    required String reason,
  }) async {
    UserProfileModel? profile;
    List<Map<String, dynamic>> recentScans = const [];

    if (uid != null) {
      try {
        profile = await UserService.getProfile(uid);
      } catch (_) {}
      try {
        recentScans = await UserService.getRecentScanHistory(uid, limit: 8);
      } catch (_) {}
    }

    return OfflineDiagnosisService.buildEstimate(
      profile: profile,
      recentScans: recentScans,
      reason: reason,
    );
  }

  Future<void> _persistPrediction({
    required String uid,
    required PredictionModel prediction,
  }) async {
    try {
      await UserService.addScanHistory(
        uid: uid,
        predictedClass: prediction.predictedClass,
        confidence: prediction.confidence,
        scannedAt: DateTime.now(),
        predictionSource: prediction.predictionSource,
        diagnosisStatus: prediction.diagnosisStatus,
        syncPending: prediction.syncPending,
        diagnosisNote: prediction.diagnosisNote,
      );
    } catch (_) {}

    final advisory = AdvisoryService.getAdvisory(prediction.predictedClass);
    final severity = advisory['severity'] as String;
    final isGenericOfflineReview =
        prediction.predictedClass.contains('Offline_Field_Review');

    if ((severity == 'high' || severity == 'moderate') &&
        !isGenericOfflineReview) {
      try {
        await AlertService.addUserAlert(
          uid: uid,
          level: AdvisoryService.severityLabel(severity),
          title: prediction.isOfflineEstimate
              ? 'Offline estimate: ${prediction.predictedClass}'
              : 'New diagnosis: ${prediction.predictedClass}',
          detail:
              'Confidence ${(prediction.confidence * 100).toStringAsFixed(2)}%. Review treatment advice now.',
        );
      } catch (_) {}
    }
  }

  Future<void> _showUnsupportedImageDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB26A00),
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text('Unsupported Image'),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  bool _shouldTreatAsUnsupported(PredictionModel prediction) {
    if (prediction.isRejected && !_canUseProvisionalDiagnosis(prediction)) {
      return true;
    }
    if (prediction.predictedClass == _unknownLabel &&
        !_canUseProvisionalDiagnosis(prediction)) {
      return true;
    }

    final leafDetector = prediction.leafDetector;
    final leafCheck = prediction.leafCheck;
    final detectorAvailable = leafDetector?['available'] == true;
    final detectorRejected = detectorAvailable &&
        leafDetector?['is_leaf_like'] == false;
    if (detectorRejected) {
      return true;
    }

    final leafScore = (leafCheck?['leaf_score'] as num?)?.toDouble();
    final largestLeafRegion =
        (leafCheck?['largest_leaf_region'] as num?)?.toDouble();
    final leafLike = leafCheck?['is_leaf_like'] == true;

    if (!leafLike) {
      return true;
    }
    if (leafScore != null && leafScore < 0.55) {
      return true;
    }
    if (largestLeafRegion != null && largestLeafRegion < 0.06) {
      return true;
    }
    return false;
  }

  PredictionModel _normalizePredictionForDisplay(PredictionModel prediction) {
    if (!prediction.isRejected && prediction.predictedClass != _unknownLabel) {
      return prediction;
    }

    if (_canUseProvisionalDiagnosis(prediction) &&
        prediction.rawPredictedClass != null &&
        prediction.rawPredictedClass!.trim().isNotEmpty) {
      return prediction.copyWith(
        predictedClass: prediction.rawPredictedClass!.trim(),
        diagnosisStatus: 'provisional',
        diagnosisNote: prediction.rejectionReason ??
            'Cloud diagnosis is provisional because scan quality or confidence was weak.',
      );
    }

    return prediction;
  }

  bool _canUseProvisionalDiagnosis(PredictionModel prediction) {
    final rawClass = prediction.rawPredictedClass?.trim() ?? '';
    if (rawClass.isEmpty) return false;
    final reason = (prediction.rejectionReason ?? '').toLowerCase();
    return reason.contains('quality') ||
        reason.contains('confidence') ||
        reason.contains('uncertain') ||
        reason.contains('top classes') ||
        reason.contains('too close');
  }

  String _friendlyUnknownMessage(PredictionModel prediction) {
    final reason = prediction.rejectionReason?.trim();
    if (reason == null || reason.isEmpty) {
      final leafScore =
          (prediction.leafCheck?['leaf_score'] as num?)?.toDouble();
      if (leafScore != null && leafScore < 0.55) {
        return 'This image does not contain a strong clear leaf area. Please bring the leaf closer, keep it centered, and try again.';
      }
      return 'This image is not a supported crop leaf. Please capture a clear leaf image and try again.';
    }

    if (reason.toLowerCase().contains('leaf')) {
      return 'This does not look like a clear leaf image. Please place the leaf inside the guide frame and scan again.';
    }

    if (reason.toLowerCase().contains('quality')) {
      return 'The image is too blurry or dark for diagnosis. Please capture a clearer leaf image and try again.';
    }

    return '$reason Please capture a clear supported leaf image and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanning Crop')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildCameraSurface(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Align infected leaf area inside the guide frame.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF44604C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _captureAndPredict,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Capture & Diagnose'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraSurface() {
    if (_cameraError != null) {
      return _framedContainer(
        child: Center(
          child: Text(
            _cameraError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A2E2E)),
          ),
        ),
      );
    }

    if (_capturedImage != null && _isLoading) {
      return _framedContainer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeCameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            _cameraController == null ||
            !_cameraController!.value.isInitialized) {
          return _framedContainer(
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return _framedContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _lineAnimationController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ScanOverlayPainter(
                          linePosition: _lineAnimationController.value,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _framedContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5E6D5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({required this.linePosition});

  final double linePosition;

  @override
  void paint(Canvas canvas, Size size) {
    final darkenPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRect(Offset.zero & size, darkenPaint);

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.height * 0.5,
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black54);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(18)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF7DFF99);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(18)),
      borderPaint,
    );

    final lineY = scanRect.top + (scanRect.height * linePosition);
    final linePaint = Paint()
      ..color = const Color(0xAA8BFF9A)
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(scanRect.left + 8, lineY),
      Offset(scanRect.right - 8, lineY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.linePosition != linePosition;
  }
}
