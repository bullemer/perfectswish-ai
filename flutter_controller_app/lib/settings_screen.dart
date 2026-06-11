import 'package:flutter/material.dart';
import 'config/yolo_model_state.dart';

/// Settings screen for configuring YOLO model and debug options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final YoloModelState _modelState = YoloModelState();
  String _selectedModel = '';
  bool _debugMode = false;
  bool _showAiVision = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _selectedModel = _modelState.modelPath;
      _debugMode = _modelState.debugMode;
      _showAiVision = _modelState.showAiVision;
    });
  }

  void _applyChanges() async {
    // Apply model change
    if (_selectedModel != _modelState.modelPath) {
      await _modelState.setModel(_selectedModel);
    }
    
    // Apply debug settings
    await _modelState.setDebugMode(_debugMode);
    await _modelState.setShowAiVision(_showAiVision);
    
    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved. Model: ${_modelState.modelName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SETTINGS", style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.blueGrey.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _applyChanges,
              child: const Text(
                "APPLY",
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YOLO Model Selection
            const Text(
              "YOLO MODEL",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedModel,
                isExpanded: true,
                dropdownColor: Colors.blueGrey.shade800,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: YoloModelState.availableModels.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModel = value;
                      _hasChanges = true;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Current: $_selectedModel",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const SizedBox(height: 30),

            // Debug Mode
            const Text(
              "DEBUG OPTIONS",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: "Debug Mode",
              subtitle: "Show detection boxes with confidence scores",
              value: _debugMode,
              icon: Icons.bug_report,
              color: Colors.green,
              onChanged: (value) {
                setState(() {
                  _debugMode = value;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: "AI Vision Display",
              subtitle: "Show preprocessed camera feed (what AI sees)",
              value: _showAiVision,
              icon: Icons.visibility,
              color: Colors.purple,
              enabled: _debugMode, // Only enable if debug mode is on
              onChanged: (value) {
                setState(() {
                  _showAiVision = value;
                  _hasChanges = true;
                });
              },
            ),

            const SizedBox(height: 30),

            // Model Info
            const Text(
              "MODEL INFO",
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
                  _buildInfoRow("Model Name", _getModelName(_selectedModel)),
                  const Divider(color: Colors.white24),
                  _buildInfoRow("Labels", YoloModelState.modelLabels[_selectedModel] ?? 'Unknown'),
                  const Divider(color: Colors.white24),
                  _buildInfoRow("Type", _selectedModel.contains('int8') ? 'Quantized (Int8)' : 'Float32'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Apply Button (if changes exist)
            if (_hasChanges)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _applyChanges,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "APPLY CHANGES",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getModelName(String path) {
    return YoloModelState.availableModels.entries
        .firstWhere((e) => e.value == path, orElse: () => const MapEntry('Unknown', ''))
        .key;
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? Colors.blueGrey.shade800 : Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? color : Colors.grey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: enabled ? Colors.white70 : Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: color,
          ),
        ],
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
