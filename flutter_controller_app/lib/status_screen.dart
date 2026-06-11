import 'package:flutter/material.dart';
import 'config/yolo_model_config.dart';
import 'config/yolo_model_state.dart';
import 'services/debug_log_service.dart';
import 'settings_screen.dart';

class StatusScreen extends StatelessWidget {
  final int displayCount;
  final bool isProjecting;
  final VoidCallback onRefreshDisplays;

  const StatusScreen({
    super.key,
    required this.displayCount,
    required this.isProjecting,
    required this.onRefreshDisplays,
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
      body: ListenableBuilder(
        listenable: YoloModelState(),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Status
                const Text(
                  "DISPLAY STATUS",
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold),
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
                        displayCount > 1
                            ? Icons.monitor
                            : Icons.monitor_weight_outlined,
                        color:
                            displayCount > 1 ? Colors.green : Colors.orange,
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
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 28),
                        onPressed: onRefreshDisplays,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // System Info
                const Text(
                  "SYSTEM INFO",
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold),
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
                      _infoRow("YOLO Model", YoloModelState().modelName),
                      const Divider(color: Colors.white24),
                      _infoRow("Model File",
                          YoloModelState().modelPath.split('/').last),
                      const Divider(color: Colors.white24),
                      _infoRow(
                          "Input Size",
                          "${YoloModelConfig.inputSize}"
                          "x${YoloModelConfig.inputSize}"),
                      const Divider(color: Colors.white24),
                      _infoRow("Displays Connected", "$displayCount"),
                      const Divider(color: Colors.white24),
                      _infoRow(
                          "Projection", isProjecting ? "Active" : "Inactive"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Video Test Mode
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.video_file, color: Colors.white),
                    label: const Text("Video Test Mode",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/video_test'),
                  ),
                ),

                const SizedBox(height: 16),

                // Settings
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text("Settings",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Debug Log
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "DEBUG LOG",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white70),
                      onPressed: () => DebugLogService().clear(),
                      tooltip: "Clear Logs",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListenableBuilder(
                    listenable: DebugLogService(),
                    builder: (context, _) {
                      final logs = DebugLogService().logs;
                      if (logs.isEmpty) {
                        return const Center(
                          child: Text("No logs yet",
                              style: TextStyle(color: Colors.white30)),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: logs.length,
                        itemBuilder: (context, i) {
                          final log = logs[i];
                          Color c = Colors.white70;
                          if (log.level == 'ERROR') c = Colors.redAccent;
                          if (log.level == 'WARN') c = Colors.orangeAccent;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 11),
                                children: [
                                  TextSpan(
                                    text: '[${log.formattedTime}] ',
                                    style: const TextStyle(
                                        color: Colors.white38),
                                  ),
                                  TextSpan(
                                    text: '${log.level}: ',
                                    style: TextStyle(
                                        color: c,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: log.message,
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                  if (log.error != null)
                                    TextSpan(
                                      text: '\n  ${log.error}',
                                      style: TextStyle(
                                          color: Colors.red.shade300),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
