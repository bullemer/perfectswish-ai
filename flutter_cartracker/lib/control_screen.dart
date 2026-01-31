import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'car_tracking_screen.dart';
import 'status_screen.dart';
import 'swish_trainer_screen.dart';
import 'voice_command_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final DisplayManager _displayManager = DisplayManager();
  final VoiceCommandService _voiceService = VoiceCommandService();
  
  List<Display> _displays = [];
  bool _isProjecting = false;
  bool _isVoiceEnabled = false;
  String _voiceStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkDisplays();
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      try {
        await _voiceService.initialize();
        _startVoiceListening();
        setState(() {
          _voiceStatus = 'Listening...';
          _isVoiceEnabled = true;
        });
      } catch (e) {
        setState(() {
          _voiceStatus = 'Init failed: $e';
        });
      }
    } else {
      setState(() {
        _voiceStatus = 'Mic permission denied';
      });
    }
  }

  void _startVoiceListening() {
    _voiceService.startListening((command) {
      debugPrint('[VOICE] Received command: $command');
      _handleVoiceCommand(command);
    });
  }

  void _handleVoiceCommand(String command) {
    switch (command) {
      case VoiceCommand.startObjectTracking:
      case VoiceCommand.objectTracking:
        _navigateToObjectTracker();
        break;
      case VoiceCommand.startCarTracking:
      case VoiceCommand.carTracking:
        _navigateToVehicleTracker();
        break;
      case VoiceCommand.stopObjectTracking:
      case VoiceCommand.stopCarTracking:
        // If we're on a tracking screen, this will pop back
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;
    }
  }

  void _navigateToObjectTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarTrackingScreen(
          title: "Object Tracker",
          classFilter: null,
          displayManager: _displayManager,
        ),
      ),
    );
  }

  void _navigateToVehicleTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarTrackingScreen(
          title: "Vehicle Tracker",
          classFilter: const ['car', 'truck', 'bus', 'bicycle', 'motorcycle'],
          displayManager: _displayManager,
        ),
      ),
    );
  }

  void _navigateToSwishTrainer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SwishTrainerScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _checkDisplays() async {
    final displays = await _displayManager.getDisplays();
    debugPrint("[CONTROL] Detected displays: ${displays?.length ?? 0}");
    if (displays != null) {
      for (var d in displays) {
        debugPrint("[CONTROL] Display: ID=${d.displayId}, Name=${d.name}");
      }
    }
    setState(() {
      _displays = displays ?? [];
    });
    
    // Automatically project if a secondary display is found
    if (_displays.length > 1 && !_isProjecting) {
      _showDashboard();
    }
  }

  void _showDashboard() {
    if (_displays.length > 1) {
      final targetDisplay = _displays.firstWhere(
        (display) => (display.displayId ?? 0) != 0,
        orElse: () => _displays[1]
      );
      
      final int displayId = targetDisplay.displayId ?? 1;
      debugPrint("[CONTROL] Projecting to Display ID: $displayId (Name: ${targetDisplay.name})");
      
      _displayManager.showSecondaryDisplay(displayId: displayId, routerName: 'presentation');
      setState(() {
        _isProjecting = true;
      });
    } else {
      debugPrint("[CONTROL] Cannot project: No secondary display found.");
    }
  }

  void _navigateToStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusScreen(
          isVoiceEnabled: _isVoiceEnabled,
          voiceStatus: _voiceStatus,
          displayCount: _displays.length,
          isProjecting: _isProjecting,
          onToggleVoice: _toggleVoiceListening,
          onRefreshDisplays: _checkDisplays,
        ),
      ),
    );
  }

  void _toggleVoiceListening() {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
      setState(() {
        _voiceStatus = 'Paused';
        _isVoiceEnabled = false;
      });
    } else {
      _startVoiceListening();
      setState(() {
        _voiceStatus = 'Listening...';
        _isVoiceEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("PERFECT SWISH CONTROL", style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Tracker Selection
            const Text(
              "TRACKING MODES",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context, 
              "Object Tracker", 
              Colors.blueAccent,
              Icons.view_in_ar,
              _navigateToObjectTracker,
            ),
            const SizedBox(height: 15),
            _buildMenuButton(
              context, 
              "Vehicle Tracker", 
              Colors.orangeAccent,
              Icons.directions_car,
              _navigateToVehicleTracker,
            ),
            const SizedBox(height: 15),
            _buildMenuButton(
              context, 
              "Swish Trainer", 
              Colors.deepOrange,
              Icons.sports_basketball,
              _navigateToSwishTrainer,
            ),
            
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            
            // System
            const Text(
              "SYSTEM",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context, 
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

  Widget _buildMenuButton(BuildContext context, String label, Color color, IconData icon, VoidCallback onTap) {
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
}
