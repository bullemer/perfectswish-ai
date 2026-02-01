
import os
from ultralytics import YOLO

# 1. Setup Data Path (User Downloaded Dataset)
# --------------------------------------------
# Dataset: Basketball and Hoop Detection.v1i.yolov8
DATA_DIR = "/home/carsten2/DEVPROJECTS/PERFECTSWISH-AI/Basketball and Hoop Detection.v1i.yolov8"
DATA_YAML_PATH = os.path.join(DATA_DIR, "data.yaml")

if not os.path.exists(DATA_YAML_PATH):
    print(f"Error: data.yaml not found at {DATA_YAML_PATH}")
    exit(1)

# 2. Train
# --------
print("Starting Training (Nano model, 50 epochs) on 'Basketball and Hoop' dataset...")
print("Classes: Basketball, Net (Rim), etc.")
try:
    model = YOLO('yolov8n.pt')
    results = model.train(
        data=DATA_YAML_PATH,
        epochs=10, # Reduced to 10 for faster local training (was 50)
        imgsz=640,
        batch=8, 
        name='basketball_net_custom'
    )
except Exception as e:
    print(f"Training failed: {e}")
    exit(1)

# 3. Export
# ---------
print("Exporting to TFLite (Int8)...")
try:
    model.export(
        format='tflite',
        int8=True,
        imgsz=640,
        data=DATA_YAML_PATH
    )
    print("Export Complete!")
except Exception as e:
    print(f"Export failed: {e}")
