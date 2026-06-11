import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'control_screen.dart';
import 'dashboard_screen.dart';
import 'video_test_screen.dart';
import 'config/yolo_model_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("[SYSTEM] Primary engine starting.");
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Initialize YOLO model state (load saved settings)
  await YoloModelState().init();
  
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: YoloModelState()),
      ],
      child: MaterialApp(
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
          if (settings.name == '/video_test') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const VideoTestScreen(),
            );
          }
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const ControlScreen(),
          );
        },
        initialRoute: '/',
      ),
    );
  }
}
