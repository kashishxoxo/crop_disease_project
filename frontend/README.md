# Crop Disease Detector Frontend

This folder contains the Flutter mobile application for the project.

The app currently supports:

- Firebase login and signup
- profile setup
- crop scanning
- diagnosis result display
- alerts and history
- voice assistant
- outbreak analytics display
- secure report verification

For the full project explanation, current progress, technology stack, and pending work, see the main project README:

- [Project README](/Users/kashishsrivastava/Desktop/crop_disease_project/README.md)

## Main Flutter Technologies

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- `camera`
- `speech_to_text`
- `http`

## Run the App

From this folder:

```bash
flutter pub get
flutter run
```

## Notes

- Android cleartext traffic is enabled for local backend development.
- Camera and microphone permissions are already configured in the Android manifest.
- Backend communication is handled through the service layer in `lib/services/`.
