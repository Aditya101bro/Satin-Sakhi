import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vibration/vibration.dart';
import '../main.dart';
import '../models/analysis_result.dart';
import '../models/document_type.dart';
import '../services/audio_service.dart';
import '../services/document_analyzer.dart';
import '../services/frame_analyzer.dart';
import '../widgets/camera_overlay.dart';
import 'document_review_screen.dart';

class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});
  @override State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  CameraController? _cam;
  final _audio = AudioService();
  final _docAnalyzer = DocumentAnalyzer();
  DocumentType _type = DocumentType.aadhaar;
  GuideState _guide = GuideState.scanning;
  String _hint = 'दस्तावेज़ को फ्रेम में लाएँ';
  bool _busy = false, _captured = false;
  int _frameSkip = 0, _ocrSkip = 0, _confirm = 0;
  bool _typeOk = false;
  String? _extractedNumber;

  @override void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
    final c = CameraController(back, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
    try {
      await c.initialize(); await c.startImageStream(_onFrame); _cam = c;
      if (mounted) setState(() {}); _audio.play(_type.placeAudioKey);
    } catch (_) { if (mounted) setState(() => _hint = 'कैमरा शुरू नहीं हो पाया'); }
  }

  void _onFrame(CameraImage image) async {
    if (_busy || _captured || !mounted) return;
    _frameSkip = (_frameSkip+1)%3; if (_frameSkip != 0) return;
    _busy = true;
    final yp = image.planes[0];
    final s = await compute(analyzeFrame, FramePayload(yp.bytes, image.width, image.height, yp.bytesPerRow));
    _ocrSkip = (_ocrSkip+1)%2;
    if (_ocrSkip == 0 && s.blurVariance > 120 && s.brightness > 60) {
      final input = _toInputImage(image);
      if (input != null) {
        final v = await _docAnalyzer.verifyDocument(input, _type);
        _typeOk = v.isCorrectDocument;
        _extractedNumber = v.extractedNumber ?? _extractedNumber;
      }
    }
    final result = _evaluate(s);
    if (mounted) _applyResult(result);
    _busy = false;
  }

  AnalysisResult _evaluate(FrameStats s) {
    if (!_typeOk) return AnalysisResult(documentIssue: DocumentIssue.wrongDocument, message: '${_type.displayName} नहीं दिख रहा', audioKey: _type.notFoundAudioKey);
    if (s.blurVariance < 80) return const AnalysisResult(documentIssue: DocumentIssue.veryBlur, message: 'फ़ोटो धुंधली है', audioKey: 'very_blur');
    if (s.brightness < 50) return const AnalysisResult(documentIssue: DocumentIssue.lowLight, message: 'रोशनी कम है', audioKey: 'low_light');
    if (s.brightness > 230) return const AnalysisResult(documentIssue: DocumentIssue.tooBright, message: 'बहुत ज़्यादा रोशनी', audioKey: 'too_bright');
    if (s.glareRatio > 0.20) return const AnalysisResult(documentIssue: DocumentIssue.glare, message: 'चमक आ रही है', audioKey: 'glare');
    if (s.blurVariance < 200) return const AnalysisResult(documentIssue: DocumentIssue.blur, message: 'थोड़ा स्थिर रखें', audioKey: 'blur');
    if (s.coverage < 0.30) return const AnalysisResult(documentIssue: DocumentIssue.tooFar, message: 'थोड़ा पास लाएँ', audioKey: 'too_far');
    if (s.coverage > 0.88) return const AnalysisResult(documentIssue: DocumentIssue.tooClose, message: 'थोड़ा दूर करें', audioKey: 'too_close');
    if (s.tiltDegrees > 20) return const AnalysisResult(documentIssue: DocumentIssue.tilted, message: 'कार्ड सीधा रखें', audioKey: 'tilt');
    return const AnalysisResult(status: CaptureStatus.ready, message: 'अब ठीक है', audioKey: 'doc_good', confidence: 0.95);
  }

  void _applyResult(AnalysisResult r) {
    _audio.play(r.audioKey);
    if (r.isReady) {
      _confirm++;
      setState(() { _hint = r.message; _guide = _confirm >= 3 ? GuideState.ready : GuideState.confirming; });
      if (_confirm >= 3) _capture();
    } else {
      _confirm = 0;
      setState(() { _hint = r.message; _guide = GuideState.error; });
    }
  }

  Future<void> _capture() async {
    if (_captured || _cam == null) return; _captured = true;
    try {
      await _cam!.stopImageStream();
      final file = await _cam!.takePicture();
      _audio.play('doc_captured');
      if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 120);
      if (mounted) _showResult(file.path);
    } catch (_) { _captured = false; }
  }

  void _showResult(String path) async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DocumentReviewScreen(imagePath: path, docName: _type.displayName, extractedNumber: _extractedNumber),
    ));
    if (result == null) { _retry(); }
    else if (mounted) { Navigator.pop(context, result); }
  }

  void _retry() {
    _captured = false; _confirm = 0; _typeOk = false; _extractedNumber = null;
    _cam?.startImageStream(_onFrame);
    setState(() { _guide = GuideState.scanning; _hint = 'दस्तावेज़ फ्रेम में लाएँ'; });
  }

  InputImage? _toInputImage(CameraImage image) {
    try {
      final bytes = WriteBuffer(); for (final p in image.planes) bytes.putUint8List(p.bytes);
      final rotation = InputImageRotationValue.fromRawValue(_cam!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
      return InputImage.fromBytes(bytes: bytes.done().buffer.asUint8List(), metadata: InputImageMetadata(size: Size(image.width.toDouble(), image.height.toDouble()), rotation: rotation, format: InputImageFormat.nv21, bytesPerRow: image.planes[0].bytesPerRow));
    } catch (_) { return null; }
  }

  @override void dispose() { _cam?.dispose(); _docAnalyzer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_cam == null || !_cam!.value.isInitialized) return const Scaffold(backgroundColor: Color(0xFF0A0A0A), body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))));
    return Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      Positioned.fill(child: CameraPreview(_cam!)),
      Positioned.fill(child: CustomPaint(painter: DocOverlayPainter(_guide))),
      Positioned(top: 40, left: 0, right: 0, child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 56), child: Row(children: DocumentType.values.map((t) { final sel = t==_type; return Padding(padding: const EdgeInsets.symmetric(horizontal:4), child: ChoiceChip(label: Text(t.displayName), selected: sel, selectedColor: const Color(0xFFE53935), backgroundColor: Colors.black54, labelStyle: TextStyle(color: sel?Colors.white:Colors.white70), onSelected: (_) { setState(() { _type=t; _typeOk=false; _confirm=0; }); _audio.play(t.placeAudioKey); })); }).toList()))),
      Positioned(top: 40, left: 8, child: const BackButton(color: Colors.white)),
      Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical:18, horizontal:20), color: const Color(0xCC000000), child: Row(children: [Icon(_guide==GuideState.ready?Icons.check_circle:_guide==GuideState.error?Icons.error:Icons.hourglass_top, color: _guide==GuideState.ready?const Color(0xFF00C853):_guide==GuideState.error?const Color(0xFFFF3D00):const Color(0xFFFFD600)), const SizedBox(width:12), Expanded(child: Text(_hint, style: const TextStyle(color: Colors.white, fontSize: 17)))]))),
    ]));
  }
}