import os
import re
import json
import hashlib
from difflib import SequenceMatcher
from datetime import datetime, timedelta, timezone

import numpy as np
import tensorflow as tf
from flask import Flask, jsonify, request
from PIL import Image
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
try:
    import cv2
except ImportError:  # optional dependency for lesion highlighting
    cv2 = None
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, messaging
except ImportError:  # optional dependency for push notifications
    firebase_admin = None
    credentials = None
    firestore = None
    messaging = None

from train_model import CLASS_MAP_PATH


MODEL_PATH = "crop_disease_model.h5"
LEAF_DETECTOR_MODEL_PATH = "leaf_detector_model.h5"
LEAF_DETECTOR_METADATA_PATH = "leaf_detector_metadata.json"
IMAGE_SIZE = (224, 224)
UNKNOWN_LABEL = "Unknown_or_Unsupported"
MIN_CONFIDENCE_THRESHOLD = 0.72
MIN_MARGIN_THRESHOLD = 0.18
MIN_LEAF_COVERAGE_THRESHOLD = 0.08
MIN_LEAF_SCORE_THRESHOLD = 0.42
MIN_LARGEST_LEAF_REGION_THRESHOLD = 0.04
MIN_FRAGMENT_FOCUS_THRESHOLD = 0.35
MIN_SCAN_QUALITY_FOR_DIAGNOSIS = 0.32
MIN_SCAN_QUALITY_FOR_HARD_REJECTION = 0.16
LEAF_DETECTOR_DEFAULT_MIN_LEAF_PROBABILITY = 0.70
CLASS_NAMES = []
HEALTHY_CLASS_NAMES = set()
VOICE_ADVISORY_MAP = {
    "Tomato_Early_blight": {
        "matched_keywords": ["early blight", "brown spots", "concentric rings"],
        "severity": "moderate",
        "advice": [
            "Remove infected lower leaves.",
            "Apply recommended fungicide at label dose.",
            "Avoid splashing water on leaves."
        ],
        "prevention": [
            "Keep plant spacing for airflow.",
            "Follow crop rotation after harvest."
        ],
    },
    "Tomato_Late_blight": {
        "matched_keywords": ["late blight", "water soaked", "white mold", "rapid spread"],
        "severity": "high",
        "advice": [
            "Isolate infected plants immediately.",
            "Spray targeted blight fungicide urgently.",
            "Remove heavily infected plant parts."
        ],
        "prevention": [
            "Avoid prolonged leaf wetness.",
            "Disinfect tools and field equipment."
        ],
    },
    "Potato___Early_blight": {
        "matched_keywords": ["potato early blight", "target spots", "brown lesions"],
        "severity": "moderate",
        "advice": [
            "Remove affected leaves.",
            "Start fungicide schedule quickly.",
            "Monitor nearby plants for new spots."
        ],
        "prevention": [
            "Use healthy seed tubers.",
            "Practice crop rotation."
        ],
    },
    "Tomato_healthy": {
        "matched_keywords": ["healthy", "no disease", "normal leaves"],
        "severity": "healthy",
        "advice": [
            "No major disease signs from voice description.",
            "Continue regular monitoring."
        ],
        "prevention": [
            "Maintain irrigation and nutrition balance."
        ],
    },
    "Potato___healthy": {
        "matched_keywords": ["healthy potato", "green leaves", "no spots"],
        "severity": "healthy",
        "advice": [
            "No major disease signs from voice description.",
            "Continue regular monitoring."
        ],
        "prevention": [
            "Maintain sanitation and balanced fertilization."
        ],
    },
}
VOICE_ENTITY_PATTERNS = {
    "crop": {
        "tomato": ["tomato", "tamatar", "टमाटर"],
        "potato": ["potato", "aloo", "आलू", "आलु"],
    },
    "part": {
        "leaf": ["leaf", "leaves", "patta", "patti", "पत्ता", "पत्ती"],
        "stem": ["stem", "तना"],
        "fruit": ["fruit", "फल"],
    },
    "spread_speed": {
        "fast": ["fast", "rapid", "quickly", "जल्दी", "तेजी"],
        "slow": ["slow", "धीरे"],
    },
    "symptoms": {
        "brown_spots": ["brown spot", "brown spots", "bhure dhabbe", "भूरे धब्बे"],
        "water_soaked": ["water soaked", "water-soaked", "गीला दाग", "पानी जैसा"],
        "white_mold": ["white mold", "white fungus", "सफेद फफूंदी"],
        "yellowing": ["yellow", "yellowing", "पीला", "पीले"],
        "drying": ["dry", "drying", "सूख", "मुरझा"],
    },
}
DiseaseCropHints = {
    "Tomato_Early_blight": "tomato",
    "Tomato_Late_blight": "tomato",
    "Tomato_healthy": "tomato",
    "Potato___Early_blight": "potato",
    "Potato___healthy": "potato",
}
VOICE_ADVISORY_MAP.update(
    {
        "Potato___Late_blight": {
            "matched_keywords": [
                "potato late blight",
                "water soaked",
                "dark lesions",
                "white mold",
            ],
            "severity": "high",
            "advice": [
                "Remove severely infected foliage immediately.",
                "Start a blight-specific fungicide schedule without delay.",
                "Separate healthy plants from infected plants where possible.",
            ],
            "prevention": [
                "Avoid standing moisture around the crop canopy.",
                "Improve airflow and field sanitation after irrigation.",
            ],
        },
        "Pepper__bell___Bacterial_spot": {
            "matched_keywords": [
                "bacterial spot",
                "pepper spots",
                "black spots",
                "water soaked lesions",
            ],
            "severity": "moderate",
            "advice": [
                "Remove infected leaves and avoid overhead irrigation.",
                "Use a copper-based spray if locally recommended.",
                "Keep workers from handling wet plants.",
            ],
            "prevention": [
                "Use clean seed and disease-free transplants.",
                "Disinfect tools and avoid working in wet fields.",
            ],
        },
        "Pepper__bell___healthy": {
            "matched_keywords": ["healthy pepper", "normal pepper leaves", "no pepper disease"],
            "severity": "healthy",
            "advice": [
                "No major disease symptoms were detected from the description.",
                "Continue field monitoring and balanced nutrition.",
            ],
            "prevention": [
                "Maintain regular scouting and avoid water stress.",
            ],
        },
        "Tomato_Bacterial_spot": {
            "matched_keywords": [
                "tomato bacterial spot",
                "black spots",
                "small dark spots",
                "water soaked lesions",
            ],
            "severity": "moderate",
            "advice": [
                "Remove infected leaves and limit leaf wetness.",
                "Use recommended bacterial disease management spray.",
                "Avoid handling plants when foliage is wet.",
            ],
            "prevention": [
                "Use clean seedlings and sanitize tools regularly.",
                "Improve drainage and airflow between plants.",
            ],
        },
        "Tomato_Leaf_Mold": {
            "matched_keywords": [
                "leaf mold",
                "yellow patches",
                "olive mold",
                "fuzzy growth",
            ],
            "severity": "moderate",
            "advice": [
                "Reduce humidity around the tomato canopy.",
                "Remove infected leaves from the lower canopy.",
                "Use a suitable fungicide if disease continues to spread.",
            ],
            "prevention": [
                "Increase spacing and ventilation in dense crop rows.",
                "Avoid late-evening irrigation that leaves foliage wet.",
            ],
        },
        "Tomato_Septoria_leaf_spot": {
            "matched_keywords": [
                "septoria",
                "many small spots",
                "tiny round spots",
                "spots on lower leaves",
            ],
            "severity": "moderate",
            "advice": [
                "Remove badly infected lower leaves first.",
                "Use a protective fungicide program if spotting is spreading.",
                "Keep foliage dry during irrigation.",
            ],
            "prevention": [
                "Rotate crops and remove crop debris after harvest.",
                "Use mulching to reduce splash spread from soil.",
            ],
        },
        "Tomato_Spider_mites_Two_spotted_spider_mite": {
            "matched_keywords": [
                "spider mites",
                "fine webbing",
                "tiny yellow spots",
                "underside mites",
            ],
            "severity": "moderate",
            "advice": [
                "Inspect the underside of leaves for mite colonies.",
                "Use a locally approved miticide or strong water wash if appropriate.",
                "Remove heavily infested leaves if infestation is localized.",
            ],
            "prevention": [
                "Reduce plant stress and keep fields clean of dusty buildup.",
                "Monitor mite-prone areas during hot dry periods.",
            ],
        },
        "Tomato__Target_Spot": {
            "matched_keywords": [
                "target spot",
                "ringed brown spots",
                "target-like lesions",
                "circular brown lesions",
            ],
            "severity": "moderate",
            "advice": [
                "Remove infected leaves and monitor disease spread daily.",
                "Begin protective fungicide sprays if lesions continue increasing.",
                "Improve canopy airflow to slow lesion expansion.",
            ],
            "prevention": [
                "Avoid long periods of leaf wetness.",
                "Rotate crops and clean up infected crop residue.",
            ],
        },
        "Tomato__Tomato_YellowLeaf__Curl_Virus": {
            "matched_keywords": [
                "yellow leaf curl",
                "curled leaves",
                "yellow curled leaves",
                "virus curl",
            ],
            "severity": "high",
            "advice": [
                "Remove severely infected plants to limit virus spread.",
                "Control whitefly populations urgently.",
                "Avoid moving from infected plants to healthy plants without cleaning hands and tools.",
            ],
            "prevention": [
                "Use resistant varieties when available.",
                "Use vector control and reflective mulches where practical.",
            ],
        },
        "Tomato__Tomato_mosaic_virus": {
            "matched_keywords": [
                "mosaic virus",
                "mosaic pattern",
                "mottled leaves",
                "patchy green yellow leaves",
            ],
            "severity": "high",
            "advice": [
                "Remove infected plants showing strong mosaic symptoms.",
                "Avoid handling healthy plants after touching infected ones.",
                "Disinfect tools and hands frequently during field work.",
            ],
            "prevention": [
                "Use clean seed and resistant cultivars when possible.",
                "Control mechanical spread through sanitation.",
            ],
        },
    }
)
VOICE_ENTITY_PATTERNS.update(
    {
        "severity_hint": {
            "severe": ["severe", "bahut", "zyada", "गंभीर", "बहुत ज्यादा"],
            "mild": ["mild", "slight", "थोड़ा", "कम"],
        }
    }
)
VOICE_ENTITY_PATTERNS["crop"].update(
    {
        "pepper": ["pepper", "bell pepper", "shimla mirch", "शिमला मिर्च"],
    }
)
VOICE_ENTITY_PATTERNS["symptoms"].update(
    {
        "black_spots": ["black spots", "dark spots", "काले धब्बे"],
        "leaf_curl": ["leaf curl", "curled leaves", "मुड़े पत्ते", "पत्ते मुड़ रहे"],
        "mosaic": ["mosaic", "mottled", "patchy", "चितकबरा", "धब्बेदार पैटर्न"],
        "webbing": ["webbing", "fine webs", "जाला", "जाले"],
        "mold_growth": ["mold", "fuzzy", "powdery", "फफूंदी", "रुई जैसा"],
        "tiny_spots": ["tiny spots", "small spots", "छोटे धब्बे"],
        "ringed_spots": ["rings", "ringed spots", "target spots", "गोल घेरा"],
    }
)
DiseaseCropHints.update(
    {
        "Potato___Late_blight": "potato",
        "Pepper__bell___Bacterial_spot": "pepper",
        "Pepper__bell___healthy": "pepper",
        "Tomato_Bacterial_spot": "tomato",
        "Tomato_Leaf_Mold": "tomato",
        "Tomato_Septoria_leaf_spot": "tomato",
        "Tomato_Spider_mites_Two_spotted_spider_mite": "tomato",
        "Tomato__Target_Spot": "tomato",
        "Tomato__Tomato_YellowLeaf__Curl_Virus": "tomato",
        "Tomato__Tomato_mosaic_virus": "tomato",
    }
)
TEXT_NORMALIZATION_REPLACEMENTS = {
    "tamatar": "tomato",
    "aloo": "potato",
    "shimla mirch": "pepper",
    "bhure dhabbe": "brown spots",
    "kale dhabbe": "black spots",
    "safed fafundi": "white mold",
    "jale": "webbing",
    "jhaala": "webbing",
    "murjha": "drying",
    "peele patte": "yellowing",
}
NEGATION_PATTERNS = [
    "no spot",
    "no spots",
    "no disease",
    "healthy",
    "normal leaf",
    "normal leaves",
    "koi disease nahi",
    "कोई बीमारी नहीं",
]
VOICE_DISEASE_RULES = {
    "Tomato_Early_blight": {"brown_spots": 1.2, "ringed_spots": 1.2, "yellowing": 0.5},
    "Tomato_Late_blight": {"water_soaked": 1.3, "white_mold": 1.2, "fast": 0.9},
    "Tomato_Bacterial_spot": {"black_spots": 1.2, "water_soaked": 0.8, "tiny_spots": 0.7},
    "Tomato_Leaf_Mold": {"mold_growth": 1.2, "yellowing": 0.8},
    "Tomato_Septoria_leaf_spot": {"tiny_spots": 1.2, "ringed_spots": 0.8, "yellowing": 0.5},
    "Tomato_Spider_mites_Two_spotted_spider_mite": {"webbing": 1.4, "tiny_spots": 0.9, "yellowing": 0.6},
    "Tomato__Target_Spot": {"ringed_spots": 1.3, "brown_spots": 0.8},
    "Tomato__Tomato_YellowLeaf__Curl_Virus": {"leaf_curl": 1.5, "yellowing": 0.8},
    "Tomato__Tomato_mosaic_virus": {"mosaic": 1.5, "yellowing": 0.5},
    "Tomato_healthy": {"healthy_hint": 1.2},
    "Potato___Early_blight": {"brown_spots": 1.2, "ringed_spots": 0.9, "yellowing": 0.4},
    "Potato___Late_blight": {"water_soaked": 1.3, "white_mold": 1.1, "fast": 0.8},
    "Potato___healthy": {"healthy_hint": 1.2},
    "Pepper__bell___Bacterial_spot": {"black_spots": 1.2, "water_soaked": 0.8, "tiny_spots": 0.7},
    "Pepper__bell___healthy": {"healthy_hint": 1.2},
}
SOIL_RISK_FACTORS = {
    "clay": 0.10,
    "silty": 0.08,
    "loam": 0.05,
    "black": 0.06,
    "red": 0.04,
    "sandy": -0.02,
}
FORECAST_DISEASE_BASELINES = {
    "healthy": 0.0,
    "moderate": 0.65,
    "high": 1.0,
}

app = Flask(__name__)

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")

model = tf.keras.models.load_model(MODEL_PATH)


def _load_metadata():
    if not os.path.exists(CLASS_MAP_PATH):
        raise FileNotFoundError(f"Model metadata not found: {CLASS_MAP_PATH}")
    with open(CLASS_MAP_PATH, "r", encoding="utf-8") as fh:
        metadata = json.load(fh)
    class_names = metadata.get("class_names") or []
    healthy_names = set(metadata.get("healthy_class_names") or [])
    if not class_names:
        raise ValueError("No class names found in model metadata.")
    return class_names, healthy_names


CLASS_NAMES, HEALTHY_CLASS_NAMES = _load_metadata()


def _load_leaf_detector():
    if not os.path.exists(LEAF_DETECTOR_MODEL_PATH):
        return None, {}
    if not os.path.exists(LEAF_DETECTOR_METADATA_PATH):
        app.logger.warning(
            "Leaf detector model exists but metadata is missing at %s",
            LEAF_DETECTOR_METADATA_PATH,
        )
        return None, {}

    try:
        with open(LEAF_DETECTOR_METADATA_PATH, "r", encoding="utf-8") as fh:
            metadata = json.load(fh)
        loaded_model = tf.keras.models.load_model(LEAF_DETECTOR_MODEL_PATH)
        return loaded_model, metadata
    except Exception as exc:
        app.logger.warning("Leaf detector could not be loaded: %s", exc)
        return None, {}


LEAF_DETECTOR_MODEL, LEAF_DETECTOR_METADATA = _load_leaf_detector()
LEAF_DETECTOR_MIN_LEAF_PROBABILITY = float(
    LEAF_DETECTOR_METADATA.get(
        "min_leaf_probability",
        LEAF_DETECTOR_DEFAULT_MIN_LEAF_PROBABILITY,
    )
)


def _init_firebase_admin():
    if firebase_admin is None:
        app.logger.warning(
            "firebase_admin not installed. FCM push notifications are disabled."
        )
        return None

    if firebase_admin._apps:
        return firestore.client()

    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if not service_account_path:
        app.logger.warning(
            "FIREBASE_SERVICE_ACCOUNT_JSON not set. FCM push notifications are disabled."
        )
        return None
    if not os.path.exists(service_account_path):
        app.logger.warning(
            "Firebase service account file not found at %s", service_account_path
        )
        return None

    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()


db = _init_firebase_admin()
if cv2 is None:
    app.logger.warning(
        "opencv-python not installed. Lesion overlay detection is disabled."
    )
if LEAF_DETECTOR_MODEL is None:
    app.logger.warning(
        "Dedicated leaf detector model not loaded. Falling back to heuristic leaf checks."
    )


def prepare_image(image_bytes):
    image = Image.open(image_bytes).convert("RGB")
    image = image.resize(IMAGE_SIZE)
    image_array = np.array(image, dtype=np.float32)
    image_array = np.expand_dims(image_array, axis=0)
    return preprocess_input(image_array)


def _leaf_detector_metrics(image_bytes):
    if LEAF_DETECTOR_MODEL is None:
        return {
            "available": False,
            "is_leaf_like": None,
            "leaf_probability": None,
            "non_leaf_probability": None,
            "threshold": round(LEAF_DETECTOR_MIN_LEAF_PROBABILITY, 2),
            "reason": "leaf_detector_unavailable",
        }

    try:
        processed_image = prepare_image(image_bytes)
        raw_output = LEAF_DETECTOR_MODEL.predict(processed_image, verbose=0)
        leaf_probability = float(np.asarray(raw_output).reshape(-1)[0])
        leaf_probability = max(0.0, min(1.0, leaf_probability))
        is_leaf_like = leaf_probability >= LEAF_DETECTOR_MIN_LEAF_PROBABILITY
        return {
            "available": True,
            "is_leaf_like": is_leaf_like,
            "leaf_probability": round(leaf_probability, 4),
            "non_leaf_probability": round(1.0 - leaf_probability, 4),
            "threshold": round(LEAF_DETECTOR_MIN_LEAF_PROBABILITY, 2),
            "reason": (
                "leaf_detected"
                if is_leaf_like
                else "dedicated_leaf_detector_rejected"
            ),
        }
    except Exception as exc:
        app.logger.warning("Leaf detector inference failed: %s", exc)
        return {
            "available": False,
            "is_leaf_like": None,
            "leaf_probability": None,
            "non_leaf_probability": None,
            "threshold": round(LEAF_DETECTOR_MIN_LEAF_PROBABILITY, 2),
            "reason": "leaf_detector_inference_failed",
        }


def _utc_now_iso():
    return datetime.now(timezone.utc).isoformat()


def _canonical_json(data):
    return json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def _compute_block_hash(block_index, prev_hash, block_time, payload):
    seed = f"{block_index}|{prev_hash}|{block_time}|{_canonical_json(payload)}"
    return hashlib.sha256(seed.encode("utf-8")).hexdigest()


def _create_blockchain_record(uid, event_type, payload):
    if not uid or db is None:
        return None

    chain_ref = db.collection("users").document(uid).collection("blockchain_reports")
    latest = (
        chain_ref.order_by("blockIndex", direction=firestore.Query.DESCENDING)
        .limit(1)
        .stream()
    )
    latest_doc = next(latest, None)

    if latest_doc is None:
        block_index = 1
        prev_hash = "GENESIS"
    else:
        latest_data = latest_doc.to_dict()
        block_index = int(latest_data.get("blockIndex", 0)) + 1
        prev_hash = str(latest_data.get("currentHash", "GENESIS"))

    block_time = _utc_now_iso()
    current_hash = _compute_block_hash(block_index, prev_hash, block_time, payload)
    doc_ref = chain_ref.document()
    doc_ref.set(
        {
            "blockIndex": block_index,
            "eventType": event_type,
            "payload": payload,
            "prevHash": prev_hash,
            "currentHash": current_hash,
            "blockTime": block_time,
            "createdAt": firestore.SERVER_TIMESTAMP,
        }
    )

    return {
        "record_id": doc_ref.id,
        "block_index": block_index,
        "current_hash": current_hash,
        "prev_hash": prev_hash,
        "block_time": block_time,
    }


def _verify_record(uid, record_id):
    if db is None:
        return {"ok": False, "reason": "Firestore unavailable"}
    if not uid or not record_id:
        return {"ok": False, "reason": "uid and record_id are required"}

    doc_ref = (
        db.collection("users")
        .document(uid)
        .collection("blockchain_reports")
        .document(record_id)
    )
    doc = doc_ref.get()
    if not doc.exists:
        return {"ok": False, "reason": "record not found"}

    data = doc.to_dict()
    expected = _compute_block_hash(
        int(data.get("blockIndex", 0)),
        str(data.get("prevHash", "")),
        str(data.get("blockTime", "")),
        data.get("payload", {}),
    )
    stored = str(data.get("currentHash", ""))
    return {
        "ok": expected == stored,
        "expected_hash": expected,
        "stored_hash": stored,
        "block_index": data.get("blockIndex"),
        "event_type": data.get("eventType"),
    }


def _scan_quality_metrics(image_bytes):
    if cv2 is None:
        return {
            "score": 0.0,
            "sharpness": None,
            "brightness": None,
            "label": "opencv_unavailable",
        }

    image_array = np.frombuffer(image_bytes.getvalue(), dtype=np.uint8)
    bgr = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
    if bgr is None:
        return {
            "score": 0.0,
            "sharpness": None,
            "brightness": None,
            "label": "invalid_image",
        }

    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    brightness = float(gray.mean())

    sharpness_score = min(1.0, max(0.0, sharpness / 140.0))
    bright_center = 140.0
    brightness_score = max(0.0, 1.0 - abs(brightness - bright_center) / 110.0)
    score = round((0.65 * sharpness_score) + (0.35 * brightness_score), 2)

    if score >= 0.75:
        label = "good"
    elif score >= 0.45:
        label = "moderate"
    else:
        label = "poor"

    return {
        "score": score,
        "sharpness": round(sharpness, 2),
        "brightness": round(brightness, 2),
        "label": label,
    }


def _decode_bgr_image(image_bytes):
    if cv2 is None:
        return None
    image_array = np.frombuffer(image_bytes.getvalue(), dtype=np.uint8)
    return cv2.imdecode(image_array, cv2.IMREAD_COLOR)


def _leaf_validity_metrics(image_bytes):
    if cv2 is None:
        return {
            "is_leaf_like": True,
            "leaf_score": None,
            "leaf_coverage": None,
            "largest_leaf_region": None,
            "fragment_focus": None,
            "saturation_mean": None,
            "reason": "opencv_unavailable",
        }

    bgr = _decode_bgr_image(image_bytes)
    if bgr is None:
        return {
            "is_leaf_like": False,
            "leaf_score": 0.0,
            "leaf_coverage": 0.0,
            "largest_leaf_region": 0.0,
            "fragment_focus": 0.0,
            "saturation_mean": 0.0,
            "reason": "invalid_image",
        }

    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    green_mask = cv2.inRange(hsv, (18, 25, 20), (100, 255, 255))
    brown_yellow_mask = cv2.inRange(hsv, (5, 15, 15), (40, 255, 255))
    leaf_like_mask = cv2.bitwise_or(green_mask, brown_yellow_mask)

    kernel = np.ones((5, 5), np.uint8)
    leaf_like_mask = cv2.morphologyEx(leaf_like_mask, cv2.MORPH_OPEN, kernel)
    leaf_like_mask = cv2.morphologyEx(leaf_like_mask, cv2.MORPH_CLOSE, kernel)

    total_pixels = float(leaf_like_mask.size)
    mask_pixels = float(np.count_nonzero(leaf_like_mask))
    coverage = mask_pixels / total_pixels if total_pixels else 0.0

    contours, _ = cv2.findContours(
        leaf_like_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )
    if not contours:
        return {
            "is_leaf_like": False,
            "leaf_score": round(min(0.3, coverage), 4),
            "leaf_coverage": round(coverage, 4),
            "largest_leaf_region": 0.0,
            "fragment_focus": 0.0,
            "saturation_mean": 0.0,
            "reason": "no_leaf_like_region_detected",
        }

    largest_contour = max(contours, key=cv2.contourArea)
    largest_area = float(cv2.contourArea(largest_contour))
    largest_ratio = largest_area / total_pixels if total_pixels else 0.0
    fragment_focus = largest_area / mask_pixels if mask_pixels else 0.0

    sat_channel = hsv[:, :, 1]
    masked_saturation = sat_channel[leaf_like_mask > 0]
    saturation_mean = float(masked_saturation.mean()) if masked_saturation.size else 0.0

    coverage_score = min(1.0, coverage / 0.28)
    largest_region_score = min(1.0, largest_ratio / 0.18)
    focus_score = min(1.0, fragment_focus / 0.8)
    saturation_score = min(1.0, saturation_mean / 90.0)
    leaf_score = round(
        (0.35 * coverage_score)
        + (0.3 * largest_region_score)
        + (0.2 * focus_score)
        + (0.15 * saturation_score),
        4,
    )

    reasons = []
    if coverage < MIN_LEAF_COVERAGE_THRESHOLD:
        reasons.append("too_little_leaf_area")
    if largest_ratio < MIN_LARGEST_LEAF_REGION_THRESHOLD:
        reasons.append("no_clear_leaf_region")
    if fragment_focus < MIN_FRAGMENT_FOCUS_THRESHOLD:
        reasons.append("leaf_pixels_too_fragmented")
    if saturation_mean < 28.0:
        reasons.append("leaf_colors_too_weak")
    if leaf_score < MIN_LEAF_SCORE_THRESHOLD:
        reasons.append("overall_leaf_score_too_low")

    if not reasons:
        reason = "leaf_detected"
        is_leaf_like = True
    else:
        reason = reasons[0]
        is_leaf_like = False

    return {
        "is_leaf_like": is_leaf_like,
        "leaf_score": leaf_score,
        "leaf_coverage": round(coverage, 4),
        "largest_leaf_region": round(largest_ratio, 4),
        "fragment_focus": round(fragment_focus, 4),
        "saturation_mean": round(saturation_mean, 2),
        "reason": reason,
    }


def _detect_lesion_box(image_bytes):
    if cv2 is None:
        return None

    bgr = _decode_bgr_image(image_bytes)
    if bgr is None:
        return None

    h, w = bgr.shape[:2]
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)

    leaf_mask = cv2.inRange(hsv, (15, 30, 20), (110, 255, 255))
    brown_yellow = cv2.inRange(hsv, (5, 40, 20), (35, 255, 255))
    dark_spots = cv2.inRange(hsv, (0, 0, 0), (180, 255, 80))
    lesion_mask = cv2.bitwise_or(brown_yellow, dark_spots)
    lesion_mask = cv2.bitwise_and(lesion_mask, leaf_mask)

    kernel = np.ones((5, 5), np.uint8)
    lesion_mask = cv2.morphologyEx(lesion_mask, cv2.MORPH_OPEN, kernel)
    lesion_mask = cv2.morphologyEx(lesion_mask, cv2.MORPH_DILATE, kernel)

    contours, _ = cv2.findContours(
        lesion_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )
    if not contours:
        return None

    contour = max(contours, key=cv2.contourArea)
    area = cv2.contourArea(contour)
    if area < (h * w * 0.01):
        return None

    x, y, box_w, box_h = cv2.boundingRect(contour)
    return {
        "x": round(x / w, 4),
        "y": round(y / h, 4),
        "w": round(box_w / w, 4),
        "h": round(box_h / h, 4),
    }


def _severity_for_class(predicted_class):
    if not predicted_class or predicted_class == UNKNOWN_LABEL:
        return "moderate"
    if predicted_class in HEALTHY_CLASS_NAMES:
        return "healthy"
    if "late_blight" in predicted_class.lower():
        return "high"
    return "moderate"


def _send_fcm_if_needed(uid, predicted_class, confidence):
    if not uid or db is None or messaging is None:
        return

    severity = _severity_for_class(predicted_class)
    if severity not in {"high", "moderate"}:
        return

    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        return

    token = user_doc.to_dict().get("fcmToken")
    if not token:
        return

    title = (
        "High Risk Alert"
        if severity == "high"
        else "Moderate Risk Alert"
    )
    body = (
        f"{predicted_class} detected "
        f"({confidence * 100:.2f}%). Check treatment advice."
    )
    message = messaging.Message(
        token=token,
        notification=messaging.Notification(title=title, body=body),
        data={
            "predicted_class": predicted_class,
            "confidence": f"{confidence:.6f}",
            "severity": severity,
        },
    )
    messaging.send(message)


def _normalize_text(text):
    lowered = text.lower()
    for source, target in TEXT_NORMALIZATION_REPLACEMENTS.items():
        lowered = lowered.replace(source, target)
    # Keep English + Devanagari for multilingual symptom queries.
    cleaned = re.sub(r"[^a-zA-Z0-9\u0900-\u097F\s]", " ", lowered)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def _fuzzy_contains(text, phrase):
    if phrase in text:
        return True
    tokens = text.split()
    if len(tokens) < 2:
        return False
    for i in range(len(tokens) - 1):
        chunk = f"{tokens[i]} {tokens[i + 1]}"
        if SequenceMatcher(None, chunk, phrase).ratio() >= 0.82:
            return True
    return False


def _extract_entities(text):
    entities = {
        "crop": [],
        "part": [],
        "spread_speed": [],
        "symptoms": [],
        "severity_hint": [],
    }
    for group, pattern_map in VOICE_ENTITY_PATTERNS.items():
        for label, aliases in pattern_map.items():
            if any(_fuzzy_contains(text, alias) for alias in aliases):
                entities[group].append(label)
    for key, values in entities.items():
        entities[key] = sorted(set(values))
    return entities


def _normalize_crop_name(value):
    normalized = _normalize_text(value or "")
    if "tomato" in normalized:
        return "tomato"
    if "potato" in normalized:
        return "potato"
    if "pepper" in normalized:
        return "pepper"
    return ""


def _normalize_soil_type(value):
    normalized = _normalize_text(value or "")
    for soil_name in SOIL_RISK_FACTORS.keys():
        if soil_name in normalized:
            return soil_name
    return normalized.strip()


def _load_user_profile_context(uid):
    if not uid or db is None:
        return {}
    try:
        doc = db.collection("users").document(uid).get()
        if not doc.exists:
            return {}
        data = doc.to_dict() or {}
        return {
            "crop_type": data.get("cropType", "") or "",
            "location": data.get("location", "") or "",
            "language": data.get("language", "") or "",
            "soil_type": data.get("soilType", "") or "",
            "normalized_crop": _normalize_crop_name(data.get("cropType", "") or ""),
            "normalized_soil": _normalize_soil_type(data.get("soilType", "") or ""),
        }
    except Exception as exc:
        app.logger.warning("Could not load user profile context: %s", exc)
        return {}


def _voice_advisory_from_text(raw_text, profile_context=None):
    text = _normalize_text(raw_text)
    entities = _extract_entities(text)
    profile_context = profile_context or {}
    profile_crop = profile_context.get("normalized_crop", "")
    negation_present = any(_fuzzy_contains(text, phrase) for phrase in NEGATION_PATTERNS)

    if not text:
        return {
            "predicted_class": None,
            "severity": "moderate",
            "advice": ["Please describe crop symptoms in more detail."],
            "prevention": ["Capture a clear crop image for accurate diagnosis."],
            "confidence": 0.0,
            "matched_keywords": [],
            "entities": entities,
            "profile_context": profile_context,
            "evidence": [],
        }

    best_class = None
    best_matches = []
    best_score = -1.0
    best_evidence = []
    for disease_class, payload in VOICE_ADVISORY_MAP.items():
        hits = [
            k for k in payload["matched_keywords"] if _fuzzy_contains(text, k)
        ]
        score = float(len(hits)) * 1.15
        evidence = [f"Matched phrase: {phrase}" for phrase in hits]

        crop_hint = DiseaseCropHints.get(disease_class)
        if crop_hint and crop_hint in entities["crop"]:
            score += 1.3
            evidence.append(f"Crop in transcript matches {crop_hint}.")
        elif crop_hint and profile_crop and crop_hint == profile_crop:
            score += 0.8
            evidence.append(f"Profile crop context favors {crop_hint}.")

        disease_rules = VOICE_DISEASE_RULES.get(disease_class, {})
        for symptom_label, weight in disease_rules.items():
            if symptom_label == "healthy_hint":
                if negation_present or "healthy" in text or "normal" in text:
                    score += weight
                    evidence.append("Healthy/no-disease language detected.")
                continue

            if symptom_label in entities["symptoms"]:
                score += weight
                evidence.append(f"Symptom '{symptom_label}' supports this disease.")
            if symptom_label == "fast" and "fast" in entities["spread_speed"]:
                score += weight
                evidence.append("Rapid spread increases likelihood.")

        if disease_class.endswith("Late_blight") and (
            "water_soaked" in entities["symptoms"]
            or "white_mold" in entities["symptoms"]
            or "fast" in entities["spread_speed"]
        ):
            score += 1.2
        if disease_class.endswith("Early_blight") and (
            "brown_spots" in entities["symptoms"]
            or "yellowing" in entities["symptoms"]
        ):
            score += 0.9
        if "healthy" in disease_class.lower() and (
            "brown_spots" in entities["symptoms"]
            or "water_soaked" in entities["symptoms"]
            or "white_mold" in entities["symptoms"]
        ):
            score -= 1.0
        if negation_present and "healthy" not in disease_class.lower():
            score -= 0.8
        if (
            "severity_hint" in entities
            and "severe" in entities["severity_hint"]
            and "healthy" in disease_class.lower()
        ):
            score -= 0.8

        if score > best_score:
            best_score = score
            best_matches = hits
            best_class = disease_class
            best_evidence = evidence

    if best_class is None or best_score <= 0:
        return {
            "predicted_class": None,
            "severity": "moderate",
            "advice": [
                "Could not map symptoms to a known disease confidently.",
                "Please capture image scan for better diagnosis.",
            ],
            "prevention": [
                "Observe spots, leaf color, and spread pattern daily."
            ],
            "confidence": 0.25,
            "matched_keywords": [],
            "entities": entities,
            "profile_context": profile_context,
            "evidence": [
                "Transcript did not match disease patterns strongly enough."
            ],
        }

    result = VOICE_ADVISORY_MAP[best_class]
    confidence = min(
        0.97,
        0.34 + (0.10 * len(best_matches)) + (0.07 * best_score),
    )
    return {
        "predicted_class": best_class,
        "severity": result["severity"],
        "advice": result["advice"],
        "prevention": result["prevention"],
        "confidence": round(confidence, 2),
        "matched_keywords": best_matches,
        "entities": entities,
        "profile_context": profile_context,
        "evidence": best_evidence[:6],
    }


def _safe_float(value):
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _history_risk_from_docs(scan_docs, weather=None, profile_context=None):
    now = datetime.now(timezone.utc)
    last_14_days = now - timedelta(days=14)
    last_7_days = now - timedelta(days=7)
    profile_context = profile_context or {}

    total_scans = 0
    high_count = 0
    moderate_count = 0
    week_recent = 0
    week_previous = 0
    weighted_pressure = 0.0
    recent_pressure = 0.0
    previous_pressure = 0.0
    crop_match_scans = 0
    distinct_diseases = set()

    for doc in scan_docs:
        data = doc.to_dict()
        predicted_class = str(data.get("predictedClass", ""))
        scanned_at = data.get("scannedAt")
        if not scanned_at:
            continue
        if isinstance(scanned_at, datetime):
            dt = scanned_at
        elif hasattr(scanned_at, "to_datetime"):
            dt = scanned_at.to_datetime()
        else:
            continue
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)

        if dt < last_14_days:
            continue

        total_scans += 1
        severity = _severity_for_class(predicted_class)
        confidence = _safe_float(data.get("confidence")) or 0.55
        recency_days = max(0.0, (now - dt).total_seconds() / 86400.0)
        recency_weight = max(0.35, 1.0 - (recency_days / 14.0))
        pressure = FORECAST_DISEASE_BASELINES.get(severity, 0.6) * confidence * recency_weight
        weighted_pressure += pressure
        if severity != "healthy":
            distinct_diseases.add(predicted_class)
        profile_crop = profile_context.get("normalized_crop", "")
        if profile_crop and profile_crop in predicted_class.lower():
            crop_match_scans += 1
        if severity == "high":
            high_count += 1
        elif severity == "moderate":
            moderate_count += 1

        if dt >= last_7_days:
            week_recent += 1
            recent_pressure += pressure
        else:
            week_previous += 1
            previous_pressure += pressure

    weather = weather or {}
    temperature = _safe_float(weather.get("temperature_c"))
    humidity = _safe_float(weather.get("humidity_pct"))
    rainfall = _safe_float(weather.get("rainfall_mm"))
    leaf_wetness = _safe_float(weather.get("leaf_wetness_hours"))
    soil_type = _normalize_soil_type(
        weather.get("soil_type")
        or profile_context.get("soil_type")
        or profile_context.get("normalized_soil")
        or ""
    )

    if total_scans == 0:
        base_score = 0.18
        if isinstance(humidity, float) and humidity >= 85:
            base_score += 0.08
        if isinstance(rainfall, float) and rainfall >= 10:
            base_score += 0.06
        if soil_type in SOIL_RISK_FACTORS:
            base_score += max(0.0, SOIL_RISK_FACTORS[soil_type] * 0.5)
        return {
            "risk_level": "low",
            "risk_score": round(min(0.38, base_score), 2),
            "reasons": [
                "No scans found in last 14 days.",
                "Add regular scans to activate forecast quality.",
            ],
            "stats": {
                "total_scans_14d": 0,
                "high_cases_14d": 0,
                "moderate_cases_14d": 0,
                "recent_week_scans": 0,
                "previous_week_scans": 0,
            },
            "feature_breakdown": {
                "history_pressure": 0.0,
                "trend_pressure": 0.0,
                "weather_pressure": round(base_score - 0.18, 2),
                "soil_pressure": round(max(0.0, SOIL_RISK_FACTORS.get(soil_type, 0.0) * 0.5), 2),
            },
            "weather_context": {
                "temperature_c": temperature,
                "humidity_pct": humidity,
                "rainfall_mm": rainfall,
                "leaf_wetness_hours": leaf_wetness,
                "soil_type": soil_type or None,
            },
            "profile_context": profile_context,
            "recommended_actions": [
                "Capture regular crop scans to build a stronger outbreak forecast.",
            ],
        }

    history_pressure = min(0.52, weighted_pressure / max(1.0, total_scans * 0.72))
    trend_delta = recent_pressure - previous_pressure
    trend_pressure = 0.0
    if trend_delta > 0.20:
        trend_pressure += min(0.18, trend_delta * 0.35)
    elif trend_delta < -0.12:
        trend_pressure -= 0.07
    if week_recent > week_previous and week_recent >= 3:
        trend_pressure += 0.06
    elif week_recent == 0 and week_previous > 0:
        trend_pressure -= 0.05

    weather_reasons = []
    weather_pressure = 0.0
    if isinstance(humidity, float) and humidity >= 80:
        weather_pressure += 0.06
        weather_reasons.append("High humidity may accelerate fungal spread.")
    if isinstance(rainfall, float) and rainfall >= 8:
        weather_pressure += 0.05
        weather_reasons.append("Recent rainfall increases leaf wetness risk.")
    if isinstance(temperature, float) and 18 <= temperature <= 27:
        weather_pressure += 0.03
        weather_reasons.append("Temperature range favors common blight activity.")
    if isinstance(leaf_wetness, float) and leaf_wetness >= 7:
        weather_pressure += 0.04
        weather_reasons.append("Long leaf wetness duration raises infection pressure.")

    soil_pressure = SOIL_RISK_FACTORS.get(soil_type, 0.0)
    if soil_pressure > 0:
        weather_reasons.append(f"{soil_type.title()} soil may retain moisture and sustain disease pressure.")

    crop_alignment_pressure = 0.0
    if profile_context.get("normalized_crop") and total_scans > 0:
        crop_alignment_pressure = min(0.06, (crop_match_scans / total_scans) * 0.06)

    diversity_pressure = min(0.08, len(distinct_diseases) * 0.02)
    score = 0.12 + history_pressure + trend_pressure + weather_pressure + soil_pressure + crop_alignment_pressure + diversity_pressure
    score = max(0.05, min(0.98, score))

    if score >= 0.68:
        risk_level = "high"
    elif score >= 0.38:
        risk_level = "moderate"
    else:
        risk_level = "low"

    reasons = []
    if high_count > 0:
        reasons.append(f"{high_count} high-risk case(s) in last 14 days.")
    if moderate_count > 0:
        reasons.append(f"{moderate_count} moderate-risk case(s) in last 14 days.")
    if week_recent > week_previous and week_recent >= 3:
        reasons.append("Scan activity increased in the last week.")
    if len(distinct_diseases) >= 2:
        reasons.append("Multiple disease patterns are appearing across recent scans.")
    if not reasons:
        reasons.append("Most recent scans show lower disease severity.")
    reasons.extend(weather_reasons)

    recommended_actions = []
    if risk_level == "high":
        recommended_actions.append("Inspect the field immediately and isolate heavily infected plants.")
        recommended_actions.append("Apply crop-specific disease control measures without delay.")
    elif risk_level == "moderate":
        recommended_actions.append("Increase scouting frequency and compare new scans daily.")
        recommended_actions.append("Improve canopy airflow and reduce leaf wetness.")
    else:
        recommended_actions.append("Continue routine monitoring and preventive hygiene.")
    if not soil_type:
        recommended_actions.append("Add soil type in profile to improve forecast quality.")

    return {
        "risk_level": risk_level,
        "risk_score": round(score, 2),
        "reasons": reasons,
        "stats": {
            "total_scans_14d": total_scans,
            "high_cases_14d": high_count,
                "moderate_cases_14d": moderate_count,
                "recent_week_scans": week_recent,
                "previous_week_scans": week_previous,
            },
        "feature_breakdown": {
            "history_pressure": round(history_pressure, 2),
            "trend_pressure": round(trend_pressure, 2),
            "weather_pressure": round(weather_pressure, 2),
            "soil_pressure": round(soil_pressure, 2),
            "crop_alignment_pressure": round(crop_alignment_pressure, 2),
            "diversity_pressure": round(diversity_pressure, 2),
        },
        "weather_context": {
            "temperature_c": temperature,
            "humidity_pct": humidity,
            "rainfall_mm": rainfall,
            "leaf_wetness_hours": leaf_wetness,
            "soil_type": soil_type or None,
        },
        "profile_context": profile_context,
        "recommended_actions": recommended_actions,
        "model_type": "hybrid_feature_forecast_v2",
    }


@app.get("/health")
def health():
    return jsonify(
        {
            "status": "ok",
            "timestamp_utc": _utc_now_iso(),
            "model_loaded": model is not None,
            "supported_classes": len(CLASS_NAMES),
            "leaf_detector_loaded": LEAF_DETECTOR_MODEL is not None,
            "opencv_available": cv2 is not None,
            "firestore_available": db is not None,
        }
    )


@app.post("/predict")
def predict():
    if "image" in request.files:
        image_file = request.files["image"]
    elif request.files:
        image_file = next(iter(request.files.values()))
    else:
        return jsonify({"error": "No image file provided."}), 400

    if image_file.filename == "":
        return jsonify({"error": "Empty filename provided."}), 400

    try:
        from io import BytesIO

        raw_bytes = image_file.read()
        image_bytes_for_model = BytesIO(raw_bytes)
        image_bytes_for_leaf_detector = BytesIO(raw_bytes)
        image_bytes_for_cv = BytesIO(raw_bytes)
        image_bytes_for_quality = BytesIO(raw_bytes)
        image_bytes_for_leaf_check = BytesIO(raw_bytes)

        leaf_detector = _leaf_detector_metrics(image_bytes_for_leaf_detector)
        scan_quality = _scan_quality_metrics(image_bytes_for_quality)
        leaf_check = _leaf_validity_metrics(image_bytes_for_leaf_check)

        processed_image = prepare_image(image_bytes_for_model)
        predictions = model.predict(processed_image, verbose=0)[0]
        predicted_index = int(np.argmax(predictions))
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = float(predictions[predicted_index])
        sorted_indices = np.argsort(predictions)[::-1]
        sorted_predictions = predictions[sorted_indices]
        second_best = float(sorted_predictions[1]) if len(sorted_predictions) > 1 else 0.0
        confidence_margin = float(confidence - second_best)
        top_predictions = [
            {
                "class_name": CLASS_NAMES[int(index)],
                "confidence": round(float(predictions[int(index)]), 4),
            }
            for index in sorted_indices[:3]
        ]
        lesion_box = _detect_lesion_box(image_bytes_for_cv)
        uid = request.form.get("uid")

        rejection_reason = None
        diagnosis_status = "accepted"
        diagnosis_note = None
        if leaf_detector["available"] and not leaf_detector["is_leaf_like"]:
            rejection_reason = (
                "Dedicated leaf detector did not recognize a supported leaf image."
            )
        elif (
            leaf_detector["available"]
            and not leaf_check["is_leaf_like"]
            and (leaf_detector["leaf_probability"] or 0.0) < 0.82
        ):
            rejection_reason = "Image does not appear to contain a clear leaf."
        elif not leaf_detector["available"] and not leaf_check["is_leaf_like"]:
            rejection_reason = "Image does not appear to contain a clear leaf."
        elif (
            scan_quality.get("score", 0.0) < MIN_SCAN_QUALITY_FOR_HARD_REJECTION
            and confidence < 0.68
        ):
            rejection_reason = "Image quality is far too poor for even a provisional diagnosis."
        elif scan_quality.get("score", 0.0) < MIN_SCAN_QUALITY_FOR_DIAGNOSIS:
            diagnosis_status = "provisional"
            diagnosis_note = (
                "Scan quality is weak, so this result should be treated as provisional until the leaf is rescanned more clearly."
            )
        elif confidence < MIN_CONFIDENCE_THRESHOLD:
            diagnosis_status = "provisional"
            diagnosis_note = (
                "Model confidence is lower than normal, so this result is a best-effort estimate rather than a fully trusted diagnosis."
            )
        elif confidence_margin < MIN_MARGIN_THRESHOLD:
            diagnosis_status = "provisional"
            diagnosis_note = (
                "Top prediction classes were too close together, so this result should be treated as provisional."
            )

        final_class = predicted_class
        final_confidence = confidence
        final_lesion_box = lesion_box
        if rejection_reason is not None:
            diagnosis_status = "rejected"
            diagnosis_note = rejection_reason
            final_class = UNKNOWN_LABEL
            final_confidence = confidence
            final_lesion_box = None

        report_info = None
        if uid:
            try:
                report_info = _create_blockchain_record(
                    uid=uid,
                    event_type="image_prediction",
                    payload={
                        "predicted_class": final_class,
                        "raw_predicted_class": predicted_class,
                        "confidence": round(final_confidence, 6),
                        "confidence_margin": round(confidence_margin, 6),
                        "lesion_box": final_lesion_box,
                        "scan_quality": scan_quality,
                        "leaf_check": leaf_check,
                        "leaf_detector": leaf_detector,
                        "diagnosis_status": diagnosis_status,
                        "diagnosis_note": diagnosis_note,
                        "rejection_reason": rejection_reason,
                    },
                )
            except Exception as chain_exc:
                app.logger.warning("Blockchain report save failed: %s", chain_exc)

        try:
            _send_fcm_if_needed(uid, final_class, final_confidence)
        except Exception as notify_exc:
            app.logger.warning("FCM send failed: %s", notify_exc)

        return jsonify(
            {
                "predicted_class": final_class,
                "confidence": final_confidence,
                "raw_predicted_class": predicted_class,
                "confidence_margin": round(confidence_margin, 4),
                "rejection_reason": rejection_reason,
                "lesion_box": final_lesion_box,
                "scan_quality": scan_quality,
                "leaf_check": leaf_check,
                "leaf_detector": leaf_detector,
                "top_predictions": top_predictions,
                "report_info": report_info,
                "supported_classes": len(CLASS_NAMES),
                "diagnosis_status": diagnosis_status,
                "diagnosis_note": diagnosis_note,
                "prediction_source": "cloud",
                "sync_pending": False,
            }
        )
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.post("/voice-advisory")
def voice_advisory():
    try:
        payload = request.get_json(silent=True) or {}
        transcript = (payload.get("transcript") or "").strip()
        uid = payload.get("uid")
        profile_context = _load_user_profile_context(uid)
        advisory = _voice_advisory_from_text(
            transcript,
            profile_context=profile_context,
        )

        if uid:
            try:
                advisory["report_info"] = _create_blockchain_record(
                    uid=uid,
                    event_type="voice_advisory",
                    payload={
                        "transcript": transcript,
                        "predicted_class": advisory.get("predicted_class"),
                        "severity": advisory.get("severity"),
                        "confidence": advisory.get("confidence"),
                        "entities": advisory.get("entities"),
                        "profile_context": advisory.get("profile_context"),
                    },
                )
            except Exception as chain_exc:
                app.logger.warning("Blockchain report save failed: %s", chain_exc)

        if uid and db is not None:
            db.collection("users").document(uid).collection("voice_queries").add(
                {
                    "transcript": transcript,
                    "predictedClass": advisory["predicted_class"],
                    "severity": advisory["severity"],
                    "confidence": advisory["confidence"],
                    "createdAt": firestore.SERVER_TIMESTAMP,
                }
            )

        return jsonify(advisory)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@app.post("/outbreak-risk")
def outbreak_risk():
    try:
        payload = request.get_json(silent=True) or {}
        uid = (payload.get("uid") or "").strip()
        weather = payload.get("weather") or {}
        soil_type = payload.get("soil_type")
        if not uid:
            return jsonify({"error": "uid is required"}), 400
        if db is None:
            return jsonify({"error": "Firestore unavailable"}), 500
        profile_context = _load_user_profile_context(uid)
        if soil_type and not weather.get("soil_type"):
            weather["soil_type"] = soil_type

        scans = (
            db.collection("users")
            .document(uid)
            .collection("scan_history")
            .order_by("scannedAt", direction=firestore.Query.DESCENDING)
            .limit(200)
            .stream()
        )
        risk_data = _history_risk_from_docs(
            scans,
            weather=weather,
            profile_context=profile_context,
        )
        risk_data["uid"] = uid
        return jsonify(risk_data)
    except Exception as exc:
        app.logger.exception("Outbreak risk error")
        return jsonify({"error": str(exc)}), 500


@app.post("/verify-record")
def verify_record():
    try:
        payload = request.get_json(silent=True) or {}
        uid = (payload.get("uid") or "").strip()
        record_id = (payload.get("record_id") or "").strip()
        verification = _verify_record(uid, record_id)
        status = 200 if verification.get("ok") else 400
        return jsonify(verification), status
    except Exception as exc:
        app.logger.exception("Verify record error")
        return jsonify({"error": str(exc)}), 500


if __name__ == "__main__":
    debug_enabled = os.getenv("FLASK_DEBUG", "").strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=debug_enabled)
