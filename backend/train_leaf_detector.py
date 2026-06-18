import json
import os
import random
import shutil

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing.image import ImageDataGenerator

from train_model import (
    BATCH_SIZE,
    IMAGE_SIZE,
    KERAS_CACHE_DIR,
    LOCAL_IMAGENET_WEIGHTS,
    SEED,
    STAGE1_EPOCHS,
    STAGE2_EPOCHS,
    SUPPORTED_IMAGE_EXTENSIONS,
    VAL_SPLIT,
    collect_dataset_roots,
    configured_dataset_dirs,
    discover_class_sources,
)


NEGATIVE_DATASET_DIRS = [
    "../dataset/leaf_detector/non_leaf",
    "../dataset/non_leaf",
    "../dataset/NonLeaf",
]
LEAF_DETECTOR_MODEL_PATH = "leaf_detector_model.h5"
LEAF_DETECTOR_METADATA_PATH = "leaf_detector_metadata.json"
LEAF_DETECTOR_CHECKPOINT_PATH = "leaf_detector_checkpoint.keras"
LEAF_BINARY_DATASET_DIR = os.path.join(
    os.path.dirname(__file__), ".cache", "leaf_detector_dataset"
)
BINARY_CLASS_ORDER = ["non_leaf", "leaf"]
DEFAULT_LEAF_THRESHOLD = 0.70


def configured_negative_dataset_dirs():
    env_value = os.getenv("NON_LEAF_DATASET_DIRS")
    if env_value:
        raw_dirs = [item.strip() for item in env_value.split(os.pathsep) if item.strip()]
        if raw_dirs:
            return raw_dirs
    return NEGATIVE_DATASET_DIRS


def _iter_image_paths_recursive(root_dir):
    for current_root, _, files in os.walk(root_dir):
        for file_name in sorted(files):
            _, ext = os.path.splitext(file_name)
            if ext.lower() not in SUPPORTED_IMAGE_EXTENSIONS:
                continue
            yield os.path.abspath(os.path.join(current_root, file_name))


def collect_positive_leaf_images():
    dataset_roots = collect_dataset_roots(configured_dataset_dirs())
    class_sources = discover_class_sources(dataset_roots)

    image_paths = []
    seen = set()
    for source_dirs in class_sources.values():
        for source_dir in source_dirs:
            for image_path in _iter_image_paths_recursive(source_dir):
                if image_path in seen:
                    continue
                seen.add(image_path)
                image_paths.append(image_path)

    if not image_paths:
        raise FileNotFoundError("No positive leaf images were discovered.")

    return dataset_roots, image_paths


def collect_negative_images():
    negative_roots = []
    negative_images = []
    seen = set()

    for dataset_dir in configured_negative_dataset_dirs():
        if not os.path.isdir(dataset_dir):
            continue
        abs_root = os.path.abspath(dataset_dir)
        negative_roots.append(abs_root)
        for image_path in _iter_image_paths_recursive(abs_root):
            if image_path in seen:
                continue
            seen.add(image_path)
            negative_images.append(image_path)

    if not negative_images:
        raise FileNotFoundError(
            "No non-leaf images were found. Create a folder such as "
            "../dataset/leaf_detector/non_leaf and add random non-leaf photos "
            "(soil, hands, tools, sky, room objects, phone camera mistakes, etc.)."
        )

    return negative_roots, negative_images


def _balanced_sample(image_paths, target_count, rng):
    if len(image_paths) <= target_count:
        return list(image_paths)
    return rng.sample(image_paths, target_count)


def build_leaf_binary_dataset():
    dataset_roots, positive_images = collect_positive_leaf_images()
    negative_roots, negative_images = collect_negative_images()

    rng = random.Random(SEED)
    target_count = min(len(positive_images), len(negative_images))
    positive_sample = _balanced_sample(positive_images, target_count, rng)
    negative_sample = _balanced_sample(negative_images, target_count, rng)

    if os.path.isdir(LEAF_BINARY_DATASET_DIR):
        shutil.rmtree(LEAF_BINARY_DATASET_DIR)
    os.makedirs(LEAF_BINARY_DATASET_DIR, exist_ok=True)

    label_to_images = {
        "leaf": positive_sample,
        "non_leaf": negative_sample,
    }
    for label, image_paths in label_to_images.items():
        label_dir = os.path.join(LEAF_BINARY_DATASET_DIR, label)
        os.makedirs(label_dir, exist_ok=True)
        for index, image_path in enumerate(image_paths):
            _, ext = os.path.splitext(image_path)
            link_name = f"{index:06d}{ext.lower()}"
            os.symlink(image_path, os.path.join(label_dir, link_name))

    dataset_info = {
        "training_root": LEAF_BINARY_DATASET_DIR,
        "plant_disease_roots": dataset_roots,
        "negative_roots": negative_roots,
        "leaf_image_count": len(positive_sample),
        "non_leaf_image_count": len(negative_sample),
    }
    return dataset_info


def build_leaf_detector():
    weights_source = LOCAL_IMAGENET_WEIGHTS if os.path.isfile(LOCAL_IMAGENET_WEIGHTS) else "imagenet"
    base_model = MobileNetV2(
        weights=weights_source,
        include_top=False,
        input_shape=(224, 224, 3),
    )
    base_model.trainable = False

    model = models.Sequential(
        [
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(64, activation="relu"),
            layers.Dropout(0.3),
            layers.Dense(1, activation="sigmoid"),
        ]
    )
    return model, base_model


def save_leaf_metadata(dataset_info):
    metadata = {
        "class_names": BINARY_CLASS_ORDER,
        "positive_class": "leaf",
        "negative_class": "non_leaf",
        "output_mode": "sigmoid_leaf_probability",
        "min_leaf_probability": DEFAULT_LEAF_THRESHOLD,
        "image_size": list(IMAGE_SIZE),
        "plant_disease_roots": dataset_info["plant_disease_roots"],
        "negative_roots": dataset_info["negative_roots"],
        "training_root": dataset_info["training_root"],
        "leaf_image_count": dataset_info["leaf_image_count"],
        "non_leaf_image_count": dataset_info["non_leaf_image_count"],
    }
    with open(LEAF_DETECTOR_METADATA_PATH, "w", encoding="utf-8") as fh:
        json.dump(metadata, fh, indent=2)


def main():
    os.environ.setdefault("KERAS_HOME", KERAS_CACHE_DIR)

    dataset_info = build_leaf_binary_dataset()
    print("Leaf detector training root:", dataset_info["training_root"])
    print("Positive leaf images:", dataset_info["leaf_image_count"])
    print("Negative non-leaf images:", dataset_info["non_leaf_image_count"])
    print("Negative dataset roots:")
    for root in dataset_info["negative_roots"]:
        print(f" - {root}")

    datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        validation_split=VAL_SPLIT,
        rotation_range=15,
        width_shift_range=0.12,
        height_shift_range=0.12,
        zoom_range=0.12,
        horizontal_flip=True,
        fill_mode="nearest",
    )

    train_generator = datagen.flow_from_directory(
        dataset_info["training_root"],
        classes=BINARY_CLASS_ORDER,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="binary",
        subset="training",
        shuffle=True,
        seed=SEED,
    )

    val_generator = datagen.flow_from_directory(
        dataset_info["training_root"],
        classes=BINARY_CLASS_ORDER,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="binary",
        subset="validation",
        shuffle=False,
        seed=SEED,
    )

    model, base_model = build_leaf_detector()
    checkpoint_callback = tf.keras.callbacks.ModelCheckpoint(
        filepath=LEAF_DETECTOR_CHECKPOINT_PATH,
        monitor="val_accuracy",
        mode="max",
        save_best_only=True,
    )

    model.compile(
        optimizer="adam",
        loss="binary_crossentropy",
        metrics=["accuracy"],
    )

    print("Stage 1: Training leaf detector head...")
    model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=STAGE1_EPOCHS,
        callbacks=[checkpoint_callback],
    )

    print("Stage 2: Fine-tuning last 20 layers...")
    base_model.trainable = True
    for layer in base_model.layers[:-20]:
        layer.trainable = False
    for layer in base_model.layers[-20:]:
        layer.trainable = True

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss="binary_crossentropy",
        metrics=["accuracy"],
    )

    model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=STAGE1_EPOCHS + STAGE2_EPOCHS,
        initial_epoch=STAGE1_EPOCHS,
        callbacks=[checkpoint_callback],
    )

    model.save(LEAF_DETECTOR_MODEL_PATH)
    save_leaf_metadata(dataset_info)
    print(f"Leaf detector saved to: {LEAF_DETECTOR_MODEL_PATH}")
    print(f"Leaf detector checkpoint saved to: {LEAF_DETECTOR_CHECKPOINT_PATH}")
    print(f"Leaf detector metadata saved to: {LEAF_DETECTOR_METADATA_PATH}")


if __name__ == "__main__":
    main()
