# AI-Based Mobile Portal for Crop Disease Diagnosis

This project is a mobile crop disease diagnosis system built with a Flutter frontend and a Python Flask backend. In simple words, the app lets a farmer log in, scan a crop image, get an AI-based disease prediction, receive treatment advice, speak symptoms using voice input, view alerts and history, and store reports securely.

The project is currently at an advanced MVP stage. Most core modules are working end-to-end, and the remaining work is mainly refinement and deeper versions of some advanced modules.

## What We Have Built So Far

### 1. Mobile App

The Flutter app currently includes:

- Login and signup
- Profile setup and profile edit
- Dashboard screen
- Crop scan screen
- Diagnosis result screen
- Alerts screen
- Scan history screen
- Voice assistant screen
- About project screen

The app is connected to Firebase for authentication, storage, and notifications.

### 2. AI Disease Detection

We trained an image classification model using TensorFlow/Keras with MobileNetV2 transfer learning.

The model:

- uses image size `224x224`
- trains on a selected subset of PlantVillage classes
- uses two-stage transfer learning
- saves as `crop_disease_model.h5`

The backend loads this trained model and uses it to predict disease name and confidence score for a scanned image.

### 3. AR-Style Scanning Experience

We added a guided scan screen in the app using the live camera preview. This is not full 3D AR, but it gives an AR-like guided experience.

It includes:

- live camera feed
- scan frame / guide box
- moving scan line
- better crop positioning before capture
- lesion highlight after prediction

In simple words:

- before capture, the app helps the user place the leaf properly
- after capture, the app shows the suspected infected region on the image

### 4. Result and Advisory System

After a scan, the result screen shows:

- disease name
- confidence percentage
- visual confidence bar
- alert level
- AI advisory
- preventive measures
- scan quality score
- secure report log data

The scan quality score is based on image sharpness and brightness so the app can indicate whether the captured image is good, moderate, or poor for diagnosis.

### 5. Voice Assistant + NLP

The app includes a voice assistant module.

The frontend can:

- capture speech
- convert speech to text
- switch between English and Hindi voice locale

The backend can:

- process voice or typed symptom text
- extract useful symptom entities such as crop, affected part, spread speed, and symptom type
- match those symptoms to likely diseases
- return advice and prevention steps

This NLP module currently works using a rule-based and weighted matching approach. It is functional, but it is not yet using spaCy or Hugging Face models.

### 6. Alerts, History, and Notifications

We implemented:

- scan history storage in Firestore
- alert records in Firestore
- Firebase Cloud Messaging (FCM) push notifications
- outbreak alerts screen

When a risky disease is detected, the app can store an alert and trigger notification flow.

### 7. Predictive Outbreak Analytics MVP

We built an outbreak risk module.

The backend:

- reads recent scan history
- checks disease severity trends
- computes a risk level
- adjusts score using simple weather inputs

The frontend shows:

- outbreak risk level
- risk score
- reason list
- recent stats

This is currently an MVP forecasting system, not a full machine learning forecasting pipeline.

### 8. Secure Report Logging (Blockchain-Style MVP)

We added a blockchain-style secure logging system.

What it currently does:

- creates a hash-chained report record for image diagnosis
- creates a hash-chained report record for voice advisory
- stores previous hash and current hash
- allows record verification

This means reports are stored in a tamper-evident way.

Important:

- this is a blockchain-style MVP
- it is not yet a full Hyperledger Fabric or Ethereum deployment

## Technology Used

### Frontend

- Flutter
- Dart
- Camera package
- Speech-to-Text package
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Messaging
- HTTP package

### Backend

- Python
- Flask
- TensorFlow / Keras
- MobileNetV2
- OpenCV
- Pillow
- Firebase Admin SDK

### Data / Model

- PlantVillage dataset
- Transfer learning with MobileNetV2
- Preprocessing with `preprocess_input`

## How the System Works

### Image Diagnosis Flow

1. User logs into the app.
2. User opens the scan screen.
3. The camera preview shows a scan guide box.
4. User captures a crop image.
5. Flutter sends the image to Flask.
6. Flask preprocesses the image and runs the TensorFlow model.
7. The model returns disease class and confidence.
8. OpenCV tries to find the suspected infected area.
9. The app shows the final result with advisory, prevention, quality score, and report log.

### Voice Advisory Flow

1. User opens the voice assistant screen.
2. User speaks symptoms.
3. Speech is converted into text.
4. Text is sent to the backend.
5. Backend extracts symptom meaning and matches likely disease pattern.
6. Backend returns disease suggestion, severity, advice, and prevention.
7. The query is stored in Firestore and also logged in secure report format.

### Outbreak Risk Flow

1. Backend reads recent scan history from Firestore.
2. It checks how many high-risk and moderate-risk cases happened recently.
3. It combines severity trend and optional weather context.
4. It returns a simple forecast level such as low, moderate, or high.
5. The app displays this in the alerts module.

## Project Structure

```text
crop_disease_project/
├── backend/
│   ├── app.py
│   ├── train_model.py
│   └── crop_disease_model.h5
├── frontend/
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   └── models/
│   ├── android/
│   └── pubspec.yaml
└── README.md
```

## Current Progress

The practical implementation is currently around:

- `80% to 85% complete`

Most core features are working. The remaining work is mainly advanced improvements and polishing.

## What Is Still Left

The major pending or partially finished areas are:

### 1. Stronger NLP

Current NLP works well as an MVP, but can still be improved by:

- using spaCy or Transformers
- improving multilingual support further
- handling more local symptom phrases
- improving confidence scoring

### 2. Stronger Predictive Analytics

Current forecasting is rule-based MVP. A more complete version would include:

- real weather API integration
- soil data integration
- larger historical dataset
- trained prediction models using Pandas / Scikit-learn

### 3. Full Blockchain Integration

Current secure reporting is blockchain-style hash chaining. A complete version would include:

- Ethereum or Hyperledger integration
- smart contracts
- fully verifiable distributed storage

### 4. Advanced AR

Current AR is guided camera overlay. A more advanced version would include:

- stronger real-time diseased region marking
- on-device inference using TensorFlow Lite
- more interactive AR feedback

### 5. Final Testing and Deployment Polish

- more device testing
- performance tuning
- better error handling for all network conditions
- release build cleanup

## Setup Summary

### Backend

From the `backend` folder:

```bash
source venv/bin/activate
python app.py
```

If Firebase Admin features are needed:

```bash
export FIREBASE_SERVICE_ACCOUNT_JSON="/absolute/path/to/serviceAccountKey.json"
python app.py
```

### Frontend

From the `frontend` folder:

```bash
flutter pub get
flutter run
```

For emulator:

- backend URL uses `10.0.2.2` path fallback through the app networking logic

For physical Android device:

- app can also use LAN fallback
- USB reverse can be used when needed

## Submission Readiness

For the Monday college demo, use the dedicated run and demo instructions in:

- `COLLEGE_SUBMISSION_GUIDE.md`

Quick verification commands:

### Backend

```bash
cd backend
source venv/bin/activate
export FIREBASE_SERVICE_ACCOUNT_JSON="$(pwd)/serviceAccountKey.json"
python app.py
```

In a second terminal:

```bash
curl http://127.0.0.1:5000/health
```

### Smoke tests

```bash
cd backend
source venv/bin/activate
python -m unittest discover -s tests -p 'test_*.py'
```

```bash
cd frontend
flutter test
dart analyze
```

## Simple Project Summary

This project is now a working AI crop advisory mobile system.

It can:

- detect crop disease from image
- highlight suspected infected area
- give advice and preventive steps
- accept voice symptoms
- understand symptoms in a simple NLP pipeline
- show outbreak risk
- store alerts and history
- log reports in a tamper-evident secure format

The main work left is to make the advanced modules deeper and more production-ready.
