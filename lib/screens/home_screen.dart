import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'document_capture_screen.dart';
import 'face_capture_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  Future<bool> _ensureCamera(BuildContext c) async {
    final st = await Permission.camera.request();
    if (st.isGranted) return true;
    if (c.mounted) showDialog(context: c, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('कैमरा अनुमति चाहिए', style: TextStyle(color: Colors.white)),
      content: const Text('दस्तावेज़ और फ़ोटो लेने के लिए कैमरे की अनुमति ज़रूरी है।', style: TextStyle(color: Colors.white70)),
      actions: [TextButton(onPressed: () => openAppSettings(), child: const Text('सेटिंग्स खोलें'))],
    ));
    return false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 24),
        const Text('सतीन सखी', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
        const Text('Satin Creditcare — KYC सहायक', style: TextStyle(color: Color(0xFFE53935), fontSize: 15)),
        const SizedBox(height: 36),
        _card(context,'दस्तावेज़ जमा करें','आधार • पैन • पासबुक • वोटर आईडी • DL',Icons.badge_outlined, () async { if (await _ensureCamera(context) && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentCaptureScreen())); }),
        const SizedBox(height: 18),
        _card(context,'फ़ोटो लें (सेल्फी)','RBI मानक के अनुसार लाइव फ़ोटो',Icons.person_outline, () async { if (await _ensureCamera(context) && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceCaptureScreen())); }),
      ]))),
    );
  }
  Widget _card(BuildContext c, String t, String s, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE53935), width: 1.2)), child: Row(children: [Icon(icon, color: const Color(0xFFE53935), size: 44), const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(s, style: const TextStyle(color: Colors.white54, fontSize: 13))])), const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 18)])));
}