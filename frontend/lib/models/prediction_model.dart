class PredictionModel {
  const PredictionModel({
    required this.predictedClass,
    required this.confidence,
    this.lesionBox,
    this.scanQuality,
    this.reportInfo,
    this.leafCheck,
    this.leafDetector,
    this.topPredictions,
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
  final Map<String, double>? lesionBox;
  final Map<String, dynamic>? scanQuality;
  final Map<String, dynamic>? reportInfo;
  final Map<String, dynamic>? leafCheck;
  final Map<String, dynamic>? leafDetector;
  final List<Map<String, dynamic>>? topPredictions;
  final String? rejectionReason;
  final String? rawPredictedClass;
  final double? confidenceMargin;
  final String diagnosisStatus;
  final String? diagnosisNote;
  final String predictionSource;
  final bool syncPending;

  bool get isRejected => diagnosisStatus == 'rejected';
  bool get isProvisional => diagnosisStatus == 'provisional';
  bool get isOfflineEstimate => predictionSource == 'offline';

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    final String? predictedClass = json['predicted_class']?.toString();
    final double? confidence = (json['confidence'] as num?)?.toDouble();
    final Map<String, dynamic>? rawLesionBox =
        json['lesion_box'] as Map<String, dynamic>?;
    final Map<String, dynamic>? scanQuality =
        json['scan_quality'] as Map<String, dynamic>?;
    final Map<String, dynamic>? reportInfo =
        json['report_info'] as Map<String, dynamic>?;
    final Map<String, dynamic>? leafCheck =
        json['leaf_check'] as Map<String, dynamic>?;
    final Map<String, dynamic>? leafDetector =
        json['leaf_detector'] as Map<String, dynamic>?;
    final List<dynamic>? rawTopPredictions =
        json['top_predictions'] as List<dynamic>?;
    final String? rejectionReason = json['rejection_reason']?.toString();
    final String? rawPredictedClass = json['raw_predicted_class']?.toString();
    final double? confidenceMargin =
        (json['confidence_margin'] as num?)?.toDouble();
    final String diagnosisStatus =
        json['diagnosis_status']?.toString() ?? 'accepted';
    final String? diagnosisNote = json['diagnosis_note']?.toString();
    final String predictionSource =
        json['prediction_source']?.toString() ?? 'cloud';
    final bool syncPending = json['sync_pending'] == true;

    if (predictedClass == null || confidence == null) {
      throw const FormatException('Invalid prediction response.');
    }

    Map<String, double>? lesionBox;
    if (rawLesionBox != null) {
      final x = (rawLesionBox['x'] as num?)?.toDouble();
      final y = (rawLesionBox['y'] as num?)?.toDouble();
      final w = (rawLesionBox['w'] as num?)?.toDouble();
      final h = (rawLesionBox['h'] as num?)?.toDouble();
      if (x != null && y != null && w != null && h != null) {
        lesionBox = {'x': x, 'y': y, 'w': w, 'h': h};
      }
    }

    List<Map<String, dynamic>>? topPredictions;
    if (rawTopPredictions != null) {
      topPredictions = rawTopPredictions
          .whereType<Map>()
          .map((item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ))
          .toList();
    }

    return PredictionModel(
      predictedClass: predictedClass,
      confidence: confidence,
      lesionBox: lesionBox,
      scanQuality: scanQuality,
      reportInfo: reportInfo,
      leafCheck: leafCheck,
      leafDetector: leafDetector,
      topPredictions: topPredictions,
      rejectionReason: rejectionReason,
      rawPredictedClass: rawPredictedClass,
      confidenceMargin: confidenceMargin,
      diagnosisStatus: diagnosisStatus,
      diagnosisNote: diagnosisNote,
      predictionSource: predictionSource,
      syncPending: syncPending,
    );
  }

  PredictionModel copyWith({
    String? predictedClass,
    double? confidence,
    Map<String, double>? lesionBox,
    Map<String, dynamic>? scanQuality,
    Map<String, dynamic>? reportInfo,
    Map<String, dynamic>? leafCheck,
    Map<String, dynamic>? leafDetector,
    List<Map<String, dynamic>>? topPredictions,
    String? rejectionReason,
    String? rawPredictedClass,
    double? confidenceMargin,
    String? diagnosisStatus,
    String? diagnosisNote,
    String? predictionSource,
    bool? syncPending,
  }) {
    return PredictionModel(
      predictedClass: predictedClass ?? this.predictedClass,
      confidence: confidence ?? this.confidence,
      lesionBox: lesionBox ?? this.lesionBox,
      scanQuality: scanQuality ?? this.scanQuality,
      reportInfo: reportInfo ?? this.reportInfo,
      leafCheck: leafCheck ?? this.leafCheck,
      leafDetector: leafDetector ?? this.leafDetector,
      topPredictions: topPredictions ?? this.topPredictions,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rawPredictedClass: rawPredictedClass ?? this.rawPredictedClass,
      confidenceMargin: confidenceMargin ?? this.confidenceMargin,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      diagnosisNote: diagnosisNote ?? this.diagnosisNote,
      predictionSource: predictionSource ?? this.predictionSource,
      syncPending: syncPending ?? this.syncPending,
    );
  }
}
