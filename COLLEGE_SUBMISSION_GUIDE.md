# College Submission Guide

This guide is the shortest reliable path to present the project on Monday without
getting stuck in setup issues.

## 1. What You Should Show

For the college submission, focus on the parts that already work well:

1. Login / signup
2. Dashboard
3. Crop scan flow
4. Result screen with:
   - disease name
   - confidence
   - scan quality
   - alert level
   - AI advisory
   - preventive measures
   - secure report log
5. Voice assistant flow
6. Alerts and history
7. Outbreak risk screen
8. Report verification flow

Do not overpromise full AR, full blockchain, or advanced forecasting. Present
them as MVP-style modules implemented for a college-level integrated system.

## 2. Backend Run Commands

From the project root:

```bash
cd backend
source venv/bin/activate
export FIREBASE_SERVICE_ACCOUNT_JSON="$(pwd)/serviceAccountKey.json"
python app.py
```

Notes:
- The backend now starts with debug mode off by default to avoid Flask reloader
  duplicates during the demo.
- If you intentionally need debug mode, run:

```bash
FLASK_DEBUG=1 python app.py
```

## 3. Backend Health Check

Before opening the app, verify the backend in a second terminal:

```bash
curl http://127.0.0.1:5000/health
```

You should see JSON showing:
- `status: ok`
- `model_loaded: true`
- `supported_classes` greater than `0`

## 4. Frontend Run Commands

From the project root:

```bash
cd frontend
flutter pub get
flutter run
```

If using a real phone:
- make sure the phone and laptop are on the same Wi‑Fi
- keep the backend running on the laptop
- the app already has LAN fallback URLs configured

## 5. Submission Smoke Tests

Run these once before Monday:

### Backend smoke tests

```bash
cd backend
source venv/bin/activate
python -m unittest discover -s tests -p 'test_*.py'
```

### Flutter tests

```bash
cd frontend
flutter test
```

### Flutter analyzer

```bash
cd frontend
dart analyze
```

## 6. Demo Flow for Monday

Use this exact order:

1. Start backend
2. Run `/health` check
3. Open app on device/emulator
4. Log in
5. Go to scan screen
6. Capture a crop image
7. Show the result screen and explain:
   - model prediction
   - confidence
   - lesion highlight
   - scan quality
   - advisory
   - prevention
   - secure log
8. Open voice assistant and speak symptoms
9. Open alerts/history
10. Open outbreak risk
11. Open report verification if asked about security

## 7. Safe Explanation for Viva / Questions

Use this wording:

- "This is a working advanced MVP."
- "AR here means an AR-style guided scan overlay, not full 3D augmented reality."
- "Blockchain here is implemented as tamper-evident hash-chained report logging."
- "Outbreak prediction is currently a hybrid rule-based forecasting MVP using scan history and weather context."
- "The core disease diagnosis pipeline is fully working end-to-end."

## 8. If Something Fails During the Demo

If camera/network/backend gives trouble:

1. Keep the backend terminal visible and confirm `/health`
2. Retry the scan once
3. If the live scan is unstable, switch to showing:
   - voice assistant
   - history
   - alerts
   - outbreak risk
   - the already working result screen

Do not waste the demo fighting setup for too long. Move to the next feature and
keep control of the presentation.

## 9. Files That Support Submission

- `README.md`
- `backend/requirements.txt`
- `backend/tests/test_smoke.py`
- `frontend/test/widget_test.dart`
- `frontend/test/advisory_service_test.dart`
- `METHODOLOGY.txt`
- `LITERATURE_REVIEW.txt`
- `REFERENCES.txt`

## 10. Recommended Final Checklist for Sunday Night

- Backend starts successfully
- `/health` returns `ok`
- App launches on the device you will carry on Monday
- One sample scan works
- Voice advisory works
- Firebase login works
- You have at least 3 sample images ready
- Charger and cable are packed
- Hotspot is available as backup internet
- You have this guide open locally
