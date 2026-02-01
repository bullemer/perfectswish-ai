# PerfectSwish AI - Flutter Demo App Summary

A Flutter-based object detection and tracking application with advanced voice control, TTS feedback, and dual-screen support.

---

## 🎯 Core Features

### 1. Real-Time Object Detection (YOLOv8)
- **Model**: YOLOv8 TFLite running on-device via `flutter_vision`
- **Modes**: General Object Tracker & Vehicle-specific Tracker
- **Performance**: ~15-20 FPS on Samsung S25 Ultra
- **Box Persistence**: Custom `BoxTracker` smooths bounding boxes across frames

### 2. Offline Voice Commands (Vosk)
| Command | Action |
|---------|--------|
| "Swish start object tracking" | Opens Object Tracker |
| "Swish object tracking" | Shortcut for above |
| "Swish start car tracking" | Opens Vehicle Tracker |
| "Swish car tracking" | Shortcut for above |
| "Swish stop [object/car] tracking" | Returns to home |

- **Engine**: `vosk_flutter` with grammar-restricted recognition
- **Model**: `vosk-model-small-en-us-0.15` (~40MB)
- **Continuous**: Always listening, no wake word delay

### 3. Text-to-Speech Announcements
- **Engine**: `flutter_tts` 
- **Behavior**: Announces detected objects with 5-second debounce
- **Example**: "Person detected" when a person enters frame

### 4. Dual-Screen Support (HDMI)
- **Plugin**: `presentation_displays`
- **Dashboard**: Premium stats UI on external monitor
- **Live Sync**: Real-time object counts pushed to secondary display

---

## 📁 Project Structure

```
flutter_cartracker/
├── lib/
│   ├── main.dart                 # Entry points (primary + secondary display)
│   ├── control_screen.dart       # Home screen with voice control
│   ├── car_tracking_screen.dart  # Camera + YOLO detection
│   ├── dashboard_screen.dart     # External display UI
│   ├── voice_command_service.dart# Vosk integration
│   ├── voice_announcer.dart      # TTS wrapper
│   ├── box_painter.dart          # Bounding box renderer
│   └── utils/
│       ├── image_utils.dart      # YUV→RGB conversion
│       └── box_tracker.dart      # Smoothing algorithm
├── assets/
│   ├── models/
│   │   └── vosk-model-small-en-us-0.15.zip
│   ├── yolov8n.tflite
│   ├── yolov8s.tflite
│   └── labels.txt
└── android/
    ├── app/
    │   ├── build.gradle          # SDK 36, Java 11
    │   └── proguard-rules.pro    # JNA keep rules
    ├── build.gradle              # Namespace injection for AGP 8.1+
    └── settings.gradle           # Kotlin 2.0.21
```

---

## 🔧 Technical Highlights

### Build Configuration
- **Target SDK**: 36 (Android 16)
- **Min SDK**: 24
- **AGP**: 8.1.0
- **Kotlin**: 2.0.21
- **Java Target**: 11
- **Rendering**: Impeller (Vulkan)

### Key Fixes Implemented
| Issue | Solution |
|-------|----------|
| AGP 8.0+ namespace errors | Namespace injection in `build.gradle` |
| Kotlin metadata version mismatch | Upgraded to Kotlin 2.0.21 |
| JVM target conflicts | `kotlin.jvm.target.validation.mode=warning` |
| Impeller camera crash | Safe disposal with stream stop + delay |
| Vosk model loading | Must use `.zip` file, not extracted folder |

---

## 📱 Target Device
- **Device**: Samsung Galaxy S25 Ultra (SM-S938B)
- **Connection**: Wireless ADB debugging
- **External Display**: HDMI via USB-C adapter

---

## 🚀 Running the App

```bash
# Connect device
adb connect 192.168.188.80:34563

# Run
cd flutter_cartracker
flutter run -d 192.168.188.80:34563
```

**Permissions Required**:
- Camera
- Microphone (for voice commands)

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_vision` | 2.0.0 | YOLOv8 inference |
| `vosk_flutter` | 0.3.48 | Offline speech recognition |
| `flutter_tts` | 4.0.2 | Text-to-speech |
| `presentation_displays` | 1.0.0 | Dual-screen support |
| `camera` | 0.11.2 | Camera access |
| `permission_handler` | 10.2.0 | Runtime permissions |

---

*Last updated: January 30, 2026*
