import 'dart:math';

class BoxTracker {
  List<TrackedObject> tracks = [];
  final int persistenceThreshold = 5; // Keep for 5 frames if lost
  final int confidenceThreshold = 2; // Show only after 2 consecutive frames

  List<Map<String, dynamic>> process(List<Map<String, dynamic>> detections) {
    // 1. Predict (Update missing count)
    for (var track in tracks) {
      track.isDetectedThisFrame = false;
      track.framesSinceLastDetection++;
    }

    // 2. Update (Match new detections to tracks)
    for (var detection in detections) {
      final box = detection['box']; // [x1, y1, x2, y2, score]
      
      TrackedObject? bestMatch;
      double bestIoU = 0.0;

      for (var track in tracks) {
        double iou = calculateIoU(box, track.lastBox);
        if (iou > 0.3 && iou > bestIoU) {
          bestIoU = iou;
          bestMatch = track;
        }
      }

      if (bestMatch != null) {
        // Match found
        bestMatch.lastBox = box;
        bestMatch.tag = detection['tag'];
        bestMatch.isDetectedThisFrame = true;
        bestMatch.framesSinceLastDetection = 0;
        bestMatch.consecutiveDetections++;
      } else {
        // New object
        tracks.add(TrackedObject(
          lastBox: box,
          tag: detection['tag'],
          framesSinceLastDetection: 0,
          consecutiveDetections: 1,
          isDetectedThisFrame: true,
        ));
      }
    }

    // 3. Cleanup and Filter
    tracks.removeWhere((t) => t.framesSinceLastDetection > persistenceThreshold);

    // Return visible tracks (formatted for flutter_vision)
    return tracks
        .where((t) => t.consecutiveDetections >= confidenceThreshold)
        .map((t) => {
              'box': t.lastBox,
              'tag': t.tag,
              // Add a 'faded' flag or score purely for UI if needed
            })
        .toList();
  }

  double calculateIoU(List<dynamic> box1, List<dynamic> box2) {
    double x1 = max(box1[0], box2[0]);
    double y1 = max(box1[1], box2[1]);
    double x2 = min(box1[2], box2[2]);
    double y2 = min(box1[3], box2[3]);

    if (x1 >= x2 || y1 >= y2) return 0.0;

    double intersection = (x2 - x1) * (y2 - y1);
    double area1 = (box1[2] - box1[0]) * (box1[3] - box1[1]);
    double area2 = (box2[2] - box2[0]) * (box2[3] - box2[1]);

    return intersection / (area1 + area2 - intersection);
  }
}

class TrackedObject {
  List<dynamic> lastBox;
  String tag;
  int framesSinceLastDetection;
  int consecutiveDetections;
  bool isDetectedThisFrame;

  TrackedObject({
    required this.lastBox,
    required this.tag,
    required this.framesSinceLastDetection,
    required this.consecutiveDetections,
    required this.isDetectedThisFrame,
  });
}
