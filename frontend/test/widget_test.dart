import 'package:flutter_test/flutter_test.dart';

import 'package:crop_disease_detector/main.dart';

void main() {
  testWidgets('App shows setup screen when Firebase is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CropDiagnosisApp(firebaseInitError: 'demo initialization error'),
    );

    expect(find.text('Firebase Setup Required'), findsOneWidget);
    expect(find.text('App could not initialize Firebase.'), findsOneWidget);
  });
}
