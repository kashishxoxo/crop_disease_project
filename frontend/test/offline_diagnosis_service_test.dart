import 'package:crop_disease_detector/models/prediction_model.dart';
import 'package:crop_disease_detector/models/user_profile_model.dart';
import 'package:crop_disease_detector/services/offline_diagnosis_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfflineDiagnosisService', () {
    test('uses recurring crop history when building offline estimate', () {
      const profile = UserProfileModel(
        uid: 'demo-user',
        name: 'Farmer',
        phone: '9999999999',
        cropType: 'Tomato',
        location: 'Lucknow',
        language: 'English',
        soilType: 'Loam',
        cropStage: 'Vegetative',
      );

      final prediction = OfflineDiagnosisService.buildEstimate(
        profile: profile,
        recentScans: const [
          {'predictedClass': 'Tomato_Late_blight'},
          {'predictedClass': 'Tomato_Late_blight'},
          {'predictedClass': 'Tomato_Early_blight'},
        ],
        reason: 'Backend unavailable.',
      );

      expect(prediction.predictedClass, 'Tomato_Late_blight');
      expect(prediction.isOfflineEstimate, isTrue);
      expect(prediction.syncPending, isTrue);
      expect(prediction.diagnosisStatus, 'offline_estimate');
      expect(prediction.diagnosisNote, contains('Backend unavailable.'));
    });

    test('falls back to generic offline review when history is weak', () {
      const profile = UserProfileModel(
        uid: 'demo-user',
        name: 'Farmer',
        phone: '9999999999',
        cropType: 'Potato',
        location: 'Lucknow',
        language: 'English',
        soilType: 'Loam',
        cropStage: 'Vegetative',
      );

      final prediction = OfflineDiagnosisService.buildEstimate(
        profile: profile,
        recentScans: const [],
      );

      expect(prediction.predictedClass, 'Potato_Offline_Field_Review');
      expect(prediction.isOfflineEstimate, isTrue);
      expect(prediction.confidence, lessThan(0.4));
    });
  });

  group('PredictionModel', () {
    test('parses status metadata from backend response', () {
      final prediction = PredictionModel.fromJson({
        'predicted_class': 'Tomato_Early_blight',
        'confidence': 0.74,
        'diagnosis_status': 'provisional',
        'diagnosis_note': 'Weak focus in the captured leaf.',
        'prediction_source': 'cloud',
        'sync_pending': false,
      });

      expect(prediction.isProvisional, isTrue);
      expect(prediction.predictionSource, 'cloud');
      expect(prediction.diagnosisNote, contains('Weak focus'));
    });
  });
}
