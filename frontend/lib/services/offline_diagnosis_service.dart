import '../models/prediction_model.dart';
import '../models/user_profile_model.dart';

class OfflineDiagnosisService {
  static PredictionModel buildEstimate({
    UserProfileModel? profile,
    List<Map<String, dynamic>> recentScans = const [],
    String reason = 'Network is unavailable. This is a provisional offline review.',
  }) {
    final cropType = profile?.cropType.trim() ?? '';
    final normalizedCrop = cropType.toLowerCase();
    final cropClasses = _matchingCropClasses(
      normalizedCrop,
      recentScans,
    );
    final diseaseCounts = <String, int>{};
    for (final disease in cropClasses) {
      diseaseCounts.update(disease, (value) => value + 1, ifAbsent: () => 1);
    }

    String predictedClass;
    double confidence;
    List<Map<String, dynamic>> topPredictions = const [];
    String diagnosisNote = reason;

    if (diseaseCounts.isNotEmpty) {
      final sorted = diseaseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final strongest = sorted.first;
      if (strongest.value >= 2 || sorted.length == 1) {
        predictedClass = strongest.key;
        confidence = (0.44 + (strongest.value * 0.08)).clamp(0.0, 0.68);
        diagnosisNote =
            '$reason The estimate is leaning on recent similar scan history for this crop.';
        topPredictions = sorted
            .take(3)
            .map(
              (entry) => {
                'class_name': entry.key,
                'confidence': (0.34 + (entry.value * 0.07)).clamp(0.0, 0.66),
              },
            )
            .toList();
      } else {
        predictedClass = _offlineReviewLabel(cropType);
        confidence = 0.36;
        diagnosisNote =
            '$reason No repeated recent pattern was strong enough, so the app is showing a generic offline field review.';
      }
    } else {
      predictedClass = _offlineReviewLabel(cropType);
      confidence = 0.34;
      diagnosisNote =
          '$reason There is no recent diagnosis history available for this crop yet.';
    }

    return PredictionModel(
      predictedClass: predictedClass,
      confidence: confidence,
      topPredictions: topPredictions,
      diagnosisStatus: 'offline_estimate',
      diagnosisNote: diagnosisNote,
      predictionSource: 'offline',
      syncPending: true,
    );
  }

  static List<String> _matchingCropClasses(
    String normalizedCrop,
    List<Map<String, dynamic>> recentScans,
  ) {
    final diseases = recentScans
        .map((scan) => scan['predictedClass']?.toString() ?? '')
        .where((disease) => disease.isNotEmpty)
        .where((disease) => !disease.contains('Offline_Field_Review'))
        .toList();

    if (normalizedCrop.isEmpty) {
      return diseases.where((disease) => !disease.toLowerCase().contains('healthy')).toList();
    }

    return diseases.where((disease) {
      final lower = disease.toLowerCase();
      if (lower.contains('healthy')) return false;
      if (normalizedCrop.contains('tomato')) return lower.contains('tomato');
      if (normalizedCrop.contains('potato')) return lower.contains('potato');
      if (normalizedCrop.contains('pepper') ||
          normalizedCrop.contains('bell')) {
        return lower.contains('pepper');
      }
      return true;
    }).toList();
  }

  static String _offlineReviewLabel(String cropType) {
    final trimmed = cropType.trim();
    if (trimmed.isEmpty) return 'Offline_Field_Review';
    final compact = trimmed.replaceAll(RegExp(r'\s+'), '_');
    return '${compact}_Offline_Field_Review';
  }
}
