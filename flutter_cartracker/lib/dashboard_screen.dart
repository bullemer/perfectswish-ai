import 'package:flutter/material.dart';
import 'package:presentation_displays/secondary_display.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _message = "System Online";
  Map<String, int> _counts = {};
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint("[DASHBOARD] Premium Dashboard initialized");
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryDisplay(
      callback: (data) {
        debugPrint("[DASHBOARD] Received data: $data");
        if (data is Map) {
          setState(() {
            if (data.containsKey('message')) {
              _message = data['message'].toString();
            }
            if (data.containsKey('stats')) {
              _counts = Map<String, int>.from(data['stats']);
              _totalCount = _counts.values.fold(0, (sum, count) => sum + count);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep midnight blue
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                Colors.blue.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "LIVE TELEMETRY",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "MAGICSYNC ACTIVE",
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  "DASHBOARD MONITOR",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Divider(color: Colors.white10, thickness: 1, height: 60),
                
                // Message Card
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SYSTEM NOTIFICATION",
                        style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Stats Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Tracked Objects",
                      style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "$_totalCount TOTAL",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Grid/Table Area
                Expanded(
                  child: _counts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insights, size: 64, color: Colors.white.withOpacity(0.05)),
                              const SizedBox(height: 20),
                              const Text(
                                "Waiting for object detection stream...",
                                style: TextStyle(color: Colors.white24, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: _counts.entries.map((entry) => _buildStatCard(entry.key, entry.value)).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "DETECTED",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
