import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("[SYSTEM] Primary engine starting.");
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const VisionTestApp());
}

// CRITICAL: The presentation_displays plugin hardcodes this entry point name
@pragma('vm:entry-point')
void secondaryDisplayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("[SYSTEM] Secondary engine starting.");
  
  // For the secondary display, we start directly with DashboardScreen
  // or a MaterialApp that defaults to it.
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DashboardScreen(),
  ));
}

class VisionTestApp extends StatelessWidget {
  const VisionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MagicShot AI',
      theme: ThemeData.dark(),
      onGenerateRoute: (settings) {
        debugPrint("[SYSTEM] Navigating to route: ${settings.name}");
        if (settings.name == 'presentation') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const DashboardScreen(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ControlScreen(),
        );
      },
      initialRoute: '/',
    );
  }
}
