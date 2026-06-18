import 'package:crop_disease_detector/models/user_profile_model.dart';
import 'package:crop_disease_detector/services/advisory_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvisoryService', () {
    test('returns Hindi advisory content for Hindi user profile', () {
      const profile = UserProfileModel(
        uid: 'demo-user',
        name: 'Farmer',
        phone: '9999999999',
        cropType: 'Tomato',
        location: 'Lucknow',
        language: 'Hindi',
        soilType: 'Loam',
        cropStage: 'Fruiting',
      );

      final advisory = AdvisoryService.getAdvisory(
        'Tomato_Late_blight',
        profile: profile,
        recentScans: const [
          {'predictedClass': 'Tomato_Late_blight'},
          {'predictedClass': 'Tomato_Late_blight'},
        ],
      );

      expect(advisory['severity'], 'high');
      expect(advisory['display_name'], 'टमाटर लेट ब्लाइट');
      expect((advisory['advice'] as List<String>).isNotEmpty, isTrue);
      expect(AdvisoryService.severityLabel('high', language: 'Hindi'), 'उच्च जोखिम');
    });

    test('falls back cleanly for unknown disease classes', () {
      final advisory = AdvisoryService.getAdvisory('Unknown_Custom_Class');

      expect(advisory['severity'], 'moderate');
      expect(advisory['display_name'], 'Unknown Custom Class');
      expect((advisory['prevention'] as List<String>).isNotEmpty, isTrue);
    });
  });
}
