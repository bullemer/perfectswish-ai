# perfectswish-ai
This is all about the perfect swish (shot) in Basketball - Android first, Iphone later


# 🏀 PerfectSwish AI

**Turn your smartphone into a Pro Basketball Analytics Kiosk.**

![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Status](https://img.shields.io/badge/status-Prototype-orange.svg) ![Platform](https://img.shields.io/badge/platform-Android-green.svg)

## 📖 Overview
**PerfectSwish AI** is a mobile-first computer vision system designed to analyze basketball shots in real-time. Unlike expensive server-based solutions, this runs **100% locally on the device** (Edge AI), making it privacy-focused, offline-capable, and lag-free.

The system is designed as a **"Smart Gym Kiosk"**:
1.  **The Controller:** A high-end Android phone (e.g., Samsung S25 Ultra) runs the AI, mounted on a tripod and connected to a TV via HDMI.
2.  **The Client:** A remote control app for coaches/players to manage the session without touching the main device.

---

## 🏗 System Architecture

### 1. 🟢 The Controller (Core App)
* **Role:** The Brain. Runs on the main device.
* **Hardware Target:** High-end Android (Pixel 9 / S25 Ultra) with NPU acceleration.
* **Key Responsibilities:**
    * **Vision Engine:** Runs **YOLOv8** (Ball tracking) and **MediaPipe** (Pose estimation) concurrently.
    * **TV Output:** Renders a "Broadcast View" dashboard via USB-C to HDMI.
    * **Logic:** Calculates release angles, shot curve, and Make/Miss logic.
    * **Local Server:** Acts as a WebSocket host/Hotspot for the Client App.

### 2. 🟡 The Client (Remote App)
* **Role:** The Remote. Runs on any standard phone (Coach or Player's pocket).
* **Key Responsibilities:**
    * **Session Management:** Start/Stop recording, tag shots, manage players.
    * **Live Dashboard:** Displays real-time stats (Shooting %, Heatmap) received from Controller.
    * **Network Discovery:** Automatically finds the Controller on the local network (mDNS/Hotspot).

### 3. ☁️ The Portal (Future Scope)
* **Role:** Long-term analytics.
* **Function:** Syncs session data (JSON) when Wi-Fi is available for detailed web-based analysis.

---

## 🛠 Tech Stack

| Component | Technology | Reasoning |
| :--- | :--- | :--- |
| **Framework** | **Flutter** (Dart) | Single codebase for UI and Logic. High performance on Android. |
| **AI Engine** | **TFLite / MediaPipe** | Offline inference optimized for mobile NPUs. |
| **Object Detection**| **YOLOv8 Nano** | Best balance of speed/accuracy for ball tracking. |
| **Connectivity** | **WebSockets** | Low-latency bi-directional communication between Controller & Client. |
| **Database** | **Isar (NoSQL)** | Ultra-fast local storage for high-frequency shot data. |

---

## 🚧 Project Status: "Proof of Concept"
We are currently in the **Vehicle Tracker Prototype** phase to validate the hardware capabilities of the Samsung S25 Ultra (NPU performance + Thermal management).

### Immediate Roadmap
- [ ] **Phase 1:** Validate YOLOv8n performance on Android (Project "CarTracker").
- [ ] **Phase 2:** Build the "Controller" skeleton with CameraX + TFLite.
- [ ] **Phase 3:** Implement "Shot Logic" (Math for curve detection).
- [ ] **Phase 4:** Develop the WebSocket "Handshake" between Controller and Client.

---

## 🤝 How to Contribute
We are looking for collaborators with experience in:
* **Flutter / Dart** (State management, Isolate threading)
* **Computer Vision** (OpenCV, TFLite models)
* **Math/Physics** (Trajectory calculation)

*Project maintained by [Your Name]*
