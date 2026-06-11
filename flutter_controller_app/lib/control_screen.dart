import 'package:flutter/material.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'shot_tracker_screen.dart';
import 'status_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final DisplayManager _displayManager = DisplayManager();

  List<Display> _displays = [];
  bool _isProjecting = false;

  @override
  void initState() {
    super.initState();
    _checkDisplays();
  }

  Future<void> _checkDisplays() async {
    final displays = await _displayManager.getDisplays();
    if (mounted) {
      setState(() => _displays = displays ?? []);
    }
    if ((_displays.length > 1) && !_isProjecting) {
      _showDashboard();
    }
  }

  void _showDashboard() {
    if (_displays.length > 1) {
      final target = _displays.firstWhere(
        (d) => (d.displayId ?? 0) != 0,
        orElse: () => _displays[1],
      );
      _displayManager.showSecondaryDisplay(
          displayId: target.displayId ?? 1, routerName: 'presentation');
      setState(() => _isProjecting = true);
    }
  }

  void _navigateToShotTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShotTrackerScreen(title: "Shot Tracker"),
      ),
    );
  }

  void _navigateToStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusScreen(
          displayCount: _displays.length,
          isProjecting: _isProjecting,
          onRefreshDisplays: _checkDisplays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("PERFECT SWISH",
            style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildButton(
              "Shot Tracker",
              Colors.deepOrange,
              Icons.sports_basketball,
              _navigateToShotTracker,
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            _buildButton(
              "Status",
              Colors.blueGrey,
              Icons.info_outline,
              _navigateToStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(label,
            style: const TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
