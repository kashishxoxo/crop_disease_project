
import os
import json
import shutil
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input


DATASET_DIRS = ["../dataset/PlantVillage"]
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
VAL_SPLIT = 0.2
STAGE1_EPOCHS = 2
STAGE2_EPOCHS = 3
MODEL_PATH = "crop_disease_model.h5"
CLASS_MAP_PATH = "model_metadata.json"
KERAS_CACHE_DIR = os.path.join(os.path.dirname(__file__), ".keras")
LOCAL_IMAGENET_WEIGHTS = os.path.join(
    KERAS_CACHE_DIR,
    "models",
    "mobilenet_v2_weights_tf_dim_ordering_tf_kernels_1.0_224_no_top.h5",
)
CHECKPOINT_PATH = "crop_disease_model_checkpoint.keras"
MERGED_DATASET_DIR = os.path.join(os.path.dirname(__file__), ".cache", "merged_dataset")
SEED = 42
IGNORED_DIR_NAMES = {"PlantVillage"}
SUPPORTED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def configured_dataset_dirs():
    env_value = os.getenv("DATASET_DIRS")
    if env_value:
        raw_dirs = [item.strip() for item in env_value.split(os.pathsep) if item.strip()]
        if raw_dirs:
            return raw_dirs
    return DATASET_DIRS


def collect_dataset_roots(dataset_dirs):
    dataset_roots = []
    for dataset_dir in dataset_dirs:
        if not os.path.isdir(dataset_dir):
            continue
        dataset_roots.append(os.path.abspath(dataset_dir))
    if not dataset_roots:
        raise FileNotFoundError("No valid dataset directories were found.")
    return dataset_roots


def discover_class_sources(dataset_roots):
    class_sources = {}
    for dataset_root in dataset_roots:
        for entry in sorted(os.listdir(dataset_root)):
            full_path = os.path.join(dataset_root, entry)
            if not os.path.isdir(full_path):
                continue
            if entry in IGNORED_DIR_NAMES:
                continue
            class_sources.setdefault(entry, []).append(full_path)
    if not class_sources:
        raise FileNotFoundError("No valid class folders found in configured dataset roots.")
    return class_sources


def _iter_image_files(source_dir):
    for file_name in sorted(os.listdir(source_dir)):
        _, ext = os.path.splitext(file_name)
        if ext.lower() not in SUPPORTED_IMAGE_EXTENSIONS:
            continue
        yield file_name


def build_training_root(class_sources):
    if len(class_sources) == 0:
        raise FileNotFoundError("No training classes were discovered.")

    if all(len(source_dirs) == 1 for source_dirs in class_sources.values()):
        only_roots = {os.path.dirname(source_dirs[0]) for source_dirs in class_sources.values()}
        if len(only_roots) == 1:
            return next(iter(only_roots))

    if os.path.isdir(MERGED_DATASET_DIR):
        shutil.rmtree(MERGED_DATASET_DIR)
    os.makedirs(MERGED_DATASET_DIR, exist_ok=True)

    for class_name, source_dirs in sorted(class_sources.items()):
        class_dir = os.path.join(MERGED_DATASET_DIR, class_name)
        os.makedirs(class_dir, exist_ok=True)
        seen_names = set()
        for source_index, source_dir in enumerate(sorted(source_dirs)):
            for file_name in _iter_image_files(source_dir):
                candidate_name = file_name
                if candidate_name in seen_names:
                    candidate_name = f"{source_index}_{candidate_name}"
                seen_names.add(candidate_name)
                src_path = os.path.abspath(os.path.join(source_dir, file_name))
                dst_path = os.path.join(class_dir, candidate_name)
                os.symlink(src_path, dst_path)

    return MERGED_DATASET_DIR


def build_model(num_classes):
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
            layers.Dense(128, activation="relu"),
            layers.Dropout(0.3),
            layers.Dense(num_classes, activation="softmax"),
        ]
    )
    return model, base_model


def save_metadata(class_names, dataset_roots, training_root, path=CLASS_MAP_PATH):
    metadata = {
        "class_names": class_names,
        "healthy_class_names": [name for name in class_names if "healthy" in name.lower()],
        "image_size": list(IMAGE_SIZE),
        "num_classes": len(class_names),
        "dataset_roots": dataset_roots,
        "training_root": training_root,
        "class_to_index": {name: idx for idx, name in enumerate(class_names)},
    }
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(metadata, fh, indent=2)


def main():
    os.environ.setdefault("KERAS_HOME", KERAS_CACHE_DIR)

    dataset_roots = collect_dataset_roots(configured_dataset_dirs())
    class_sources = discover_class_sources(dataset_roots)
    selected_classes = sorted(class_sources.keys())
    training_root = build_training_root(class_sources)

    print("Using dataset roots:")
    for dataset_root in dataset_roots:
        print(f" - {dataset_root}")
    print(f"Training root: {training_root}")
    print(f"Training on {len(selected_classes)} classes")
    for class_name in selected_classes:
        print(f" - {class_name} ({len(class_sources[class_name])} source dir(s))")

    datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        validation_split=VAL_SPLIT,
        rotation_range=20,
        width_shift_range=0.15,
        height_shift_range=0.15,
        zoom_range=0.15,
        horizontal_flip=True,
        fill_mode="nearest",
    )

    train_generator = datagen.flow_from_directory(
        training_root,
        classes=selected_classes,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        subset="training",
        shuffle=True,
        seed=SEED,
    )

    val_generator = datagen.flow_from_directory(
        training_root,
        classes=selected_classes,
        target_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
        class_mode="categorical",
        subset="validation",
        shuffle=False,
        seed=SEED,
    )

    num_classes = train_generator.num_classes

    model, base_model = build_model(num_classes)
    checkpoint_callback = tf.keras.callbacks.ModelCheckpoint(
        filepath=CHECKPOINT_PATH,
        monitor="val_accuracy",
        mode="max",
        save_best_only=True,
    )

    model.compile(
        optimizer="adam",
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    print("Stage 1: Training classifier head...")
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
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=STAGE1_EPOCHS + STAGE2_EPOCHS,
        initial_epoch=STAGE1_EPOCHS,
        callbacks=[checkpoint_callback],
    )

    model.save(MODEL_PATH)
    save_metadata(selected_classes, dataset_roots, training_root)
    print(f"Model saved to: {MODEL_PATH}")
    print(f"Best checkpoint saved to: {CHECKPOINT_PATH}")
    print(f"Metadata saved to: {CLASS_MAP_PATH}")


if __name__ == "__main__":
    main()
