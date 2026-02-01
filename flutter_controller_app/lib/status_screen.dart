import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  final bool isVoiceEnabled;
  final String voiceStatus;
  final int displayCount;
  final bool isProjecting;
  final VoidCallback onToggleVoice;
  final VoidCallback onRefreshDisplays;
  final VoidCallback onNavigateToObjectTracker;
  final VoidCallback onNavigateToVehicleTracker;

  const StatusScreen({
    super.key,
    required this.isVoiceEnabled,
    required this.voiceStatus,
    required this.displayCount,
    required this.isProjecting,
    required this.onToggleVoice,
    required this.onRefreshDisplays,
    required this.onNavigateToObjectTracker,
    required this.onNavigateToVehicleTracker,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("STATUS", style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Control Status
            const Text(
              "VOICE CONTROL",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isVoiceEnabled ? Colors.green.shade900 : Colors.red.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isVoiceEnabled ? Icons.graphic_eq : Icons.mic_off,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice: $voiceStatus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Commands: "Swish start object tracking", "Swish car tracking"',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isVoiceEnabled ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: onToggleVoice,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Display Status
            const Text(
              "DISPLAY STATUS",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    displayCount > 1 ? Icons.monitor : Icons.monitor_weight_outlined,
                    color: displayCount > 1 ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayCount > 1
                              ? "Secondary Display Detected"
                              : "No External Display Found",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isProjecting
                              ? "Currently projecting to external display"
                              : "Connect HDMI to project dashboard",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                    onPressed: onRefreshDisplays,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // System Info
            const Text(
              "SYSTEM INFO",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow("Displays Connected", "$displayCount"),
                  const Divider(color: Colors.white24),
                  _buildInfoRow("Voice Service", isVoiceEnabled ? "Active" : "Inactive"),
                  const Divider(color: Colors.white24),
                  _buildInfoRow("Projection", isProjecting ? "Active" : "Inactive"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Developer Tools (Object/Vehicle Tracker)
            const Text(
              "DEVELOPER TOOLS",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.view_in_ar, color: Colors.white),
                    label: const Text("Object Tracker", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onNavigateToObjectTracker,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions_car, color: Colors.white),
                    label: const Text("Vehicle Tracker", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onNavigateToVehicleTracker,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
