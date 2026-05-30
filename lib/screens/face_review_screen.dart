import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FaceReviewScreen extends StatefulWidget {
  final String imagePath;
  const FaceReviewScreen({super.key, required this.imagePath});
  @override State<FaceReviewScreen> createState() => _FaceReviewScreenState();
}

class _FaceReviewScreenState extends State<FaceReviewScreen> {
  double? _brightness; double? _sharpness;

  @override void initState() { super.initState(); _analyze(); }

  Future<void> _analyze() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 200);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return;
      final px = data.buffer.asUint8List();
      final w = frame.image.width, h = frame.image.height;
      double sum = 0; final lum = Float32List(w*h);
      for (int i=0,p=0; i<px.length; i+=4,p++) { final l=0.299*px[i]+0.587*px[i+1]+0.114*px[i+2]; lum[p]=l; sum+=l; }
      final brightness = sum/(w*h);
      double gSum=0,gSqSum=0; int n=0;
      for (int y=0; y<h; y++) for (int x=1; x<w; x++) { final g=(lum[y*w+x]-lum[y*w+x-1]).abs(); gSum+=g; gSqSum+=g*g; n++; }
      final mean=gSum/n; final sharpness=(gSqSum/n)-(mean*mean);
      if (mounted) setState(() { _brightness=brightness; _sharpness=sharpness; });
    } catch (_) { if (mounted) setState(() { _brightness=0; _sharpness=0; }); }
  }

  Widget _chip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),
    decoration: BoxDecoration(color: color.withValues(alpha:0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size:10, color:color), const SizedBox(width:8), Text('$label: $value', style: const TextStyle(color: Colors.white, fontSize:14))]),
  );

  @override
  Widget build(BuildContext context) {
    final b=_brightness, s=_sharpness;
    final bc=b==null?Colors.grey:(b>=80&&b<=200)?const Color(0xFF00C853):const Color(0xFFFFD600);
    final bt=b==null?'...':(b>=80&&b<=200)?'अच्छी':(b<80?'कम':'ज़्यादा');
    final sc=s==null?Colors.grey:s>=200?const Color(0xFF00C853):const Color(0xFFFFD600);
    final st2=s==null?'...':s>=200?'साफ़':'धुंधली';
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('फ़ोटो जाँचें', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(child: Column(children: [
        Expanded(child: Padding(padding: const EdgeInsets.all(20), child: ClipOval(child: Image.file(File(widget.imagePath), fit: BoxFit.cover)))),
        Wrap(spacing:12, runSpacing:8, alignment: WrapAlignment.center, children: [_chip('रोशनी',bt,bc), _chip('साफ़ता',st2,sc)]),
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: ()=>Navigator.pop(context,null), icon: const Icon(Icons.refresh,color:Colors.white), label: const Text('दोबारा',style:TextStyle(color:Colors.white)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical:16), side: const BorderSide(color:Colors.white54)))),
          const SizedBox(width:12),
          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), padding: const EdgeInsets.symmetric(vertical:16)), onPressed: ()=>Navigator.pop(context,widget.imagePath), icon: const Icon(Icons.check), label: const Text('पुष्टि करें'))),
        ])),
      ])),
    );
  }
}