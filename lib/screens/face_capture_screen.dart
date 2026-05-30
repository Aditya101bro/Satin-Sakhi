import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:vibration/vibration.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../services/face_analyzer.dart';
import '../widgets/camera_overlay.dart';
import 'face_review_screen.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});
  @override State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cam; final _audio = AudioService(); final _face = FaceAnalyzer();
  GuideState _guide = GuideState.scanning;
  String _hint = 'चेहरा फ्रेम में लाएँ';
  bool _busy = false, _captured = false; int _skip = 0, _confirm = 0; double _ring = 0;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    final c = CameraController(front, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
    try { await c.initialize(); await c.startImageStream(_onFrame); _cam = c; if (mounted) setState((){}); _audio.play('selfie_instruction'); }
    catch (_) { if (mounted) setState(() => _hint = 'कैमरा शुरू नहीं हो पाया'); }
  }

  void _onFrame(CameraImage image) async {
    if (_busy||_captured||!mounted) return;
    _skip=(_skip+1)%3; if (_skip!=0) return; _busy=true;
    final input = _toInputImage(image);
    if (input != null) {
      final r = await _face.analyzeFace(input, (image.width*image.height).toDouble());
      _audio.play(r.audioKey);
      if (r.readyToCapture) {
        _confirm++;
        setState(() { _hint='बिलकुल सही, रुकें'; _ring=(_confirm/3).clamp(0,1); _guide=_confirm>=3?GuideState.ready:GuideState.confirming; });
        if (_confirm>=3) _capture();
      } else {
        _confirm=0;
        setState(() { _hint=_hintFor(r.audioKey); _ring=0; _guide=GuideState.error; });
      }
    }
    _busy=false;
  }

  String _hintFor(String k) => {'no_face':'चेहरा फ्रेम में लाएँ','face_too_far':'थोड़ा पास आएँ','face_too_close':'थोड़ा दूर हों','face_left':'थोड़ा दाएँ घूमें','face_right':'थोड़ा बाएँ घूमें','face_up':'थोड़ा ऊपर करें','face_down':'थोड़ा नीचे झुकें','eyes_closed':'आँखें खुली रखें','multiple_faces':'सिर्फ़ एक चेहरा रखें','blink_prompt':'एक बार आँखें झपकाएँ'}[k] ?? 'सीधा कैमरे में देखें';

  Future<void> _capture() async {
    if (_captured||_cam==null) return; _captured=true;
    try {
      await _cam!.stopImageStream(); final file = await _cam!.takePicture();
      _audio.play('face_captured');
      if (await Vibration.hasVibrator()??false) Vibration.vibrate(duration:120);
      if (mounted) {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => FaceReviewScreen(imagePath: file.path)));
        if (result == null) { _captured=false; _confirm=0; _face.reset(); _cam?.startImageStream(_onFrame); setState((){_guide=GuideState.scanning;_hint='चेहरा फ्रेम में लाएँ';}); }
        else if (mounted) { Navigator.pop(context, result); }
      }
    } catch (_) { _captured=false; }
  }

  InputImage? _toInputImage(CameraImage image) {
    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    try {
      final camera = _cam!.description;
      final sensor = camera.sensorOrientation;
      int? rot = orientations[_cam!.value.deviceOrientation];
      if (rot == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rot = (sensor + rot) % 360;
      } else {
        rot = (sensor - rot + 360) % 360;
      }
      final rotation = InputImageRotationValue.fromRawValue(rot);
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (rotation == null || format == null) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }
