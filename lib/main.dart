import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { cameras = await availableCameras(); } catch (_) {}
  await AudioService().preloadAll();
  runApp(const SatinSakhiApp());
}

class SatinSakhiApp extends StatelessWidget {
  const SatinSakhiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satin Sakhi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE53935)),
        fontFamily: 'NotoSansDevanagari',
      ),
      home: const HomeScreen(),
    );
  }
}