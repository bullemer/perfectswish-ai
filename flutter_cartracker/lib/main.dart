import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'car_tracking_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const VisionTestApp());
}

class VisionTestApp extends StatelessWidget {
  const VisionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text(
               "MAGICSHOT AI",
               style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
             ),
             const SizedBox(height: 40),
             
             // Button 1: Object Tracker (General)
             _buildMenuButton(
               context, 
               "Object Tracker", 
               Colors.blueAccent,
               Icons.view_in_ar,
               () => Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const CarTrackingScreen(
                   title: "Object Tracker",
                   classFilter: null, // No filter = Detect Everything
                 ))
               )
             ),
             
             const SizedBox(height: 20),

             // Button 2: Vehicle Tracker (Filtered)
             _buildMenuButton(
               context, 
               "Vehicle Tracker", 
               Colors.orangeAccent,
               Icons.directions_car,
               () => Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const CarTrackingScreen(
                   title: "Vehicle Tracker",
                   classFilter: ['car', 'truck', 'bus', 'bicycle', 'motorcycle'],
                 ))
               )
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 250,
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
