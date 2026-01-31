import 'package:flutter/material.dart';
import 'pose_tracking_screen.dart';
import 'shot_tracker_screen.dart';

class SwishTrainerScreen extends StatefulWidget {
  const SwishTrainerScreen({super.key});

  @override
  State<SwishTrainerScreen> createState() => _SwishTrainerScreenState();
}

class _SwishTrainerScreenState extends State<SwishTrainerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SWISH TRAINER", style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.deepOrange.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange.shade800, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sports_basketball, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Basketball Shot Trainer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Track your shots and improve your game",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Training Mode Buttons
            const Text(
              "TRAINING MODES",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildTrainingModeButton(
              "Free Throw Practice",
              Colors.green.shade700,
              Icons.sports_basketball,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PoseTrackingScreen(
                      title: "Free Throw Practice",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _buildTrainingModeButton(
              "Three-Point Trainer",
              Colors.blue.shade700,
              Icons.track_changes,
              () {
                // TODO: Implement three-point trainer
                _showComingSoon("Three-Point Trainer");
              },
            ),

            const SizedBox(height: 15),

            _buildTrainingModeButton(
              "Shot Tracker",
              Colors.purple.shade700,
              Icons.sports_basketball_outlined,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShotTrackerScreen(
                      title: "Shot Tracker",
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _buildTrainingModeButton(
              "Session History",
              Colors.blueGrey.shade700,
              Icons.history,
              () {
                // TODO: Implement session history
                _showComingSoon("Session History");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingModeButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature - Coming Soon!"),
        backgroundColor: Colors.deepOrange.shade700,
      ),
    );
  }
}
