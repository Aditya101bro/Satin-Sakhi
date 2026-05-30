import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/analysis_result.dart';

class FaceAnalysisResult {
  final FaceIssue issue;
  final bool readyToCapture, blinkDetected;
  final String audioKey;
  final double confidence;
  const FaceAnalysisResult(this.issue, this.readyToCapture, this.blinkDetected, this.audioKey, this.confidence);
}

class FaceAnalyzer {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, enableTracking: true,
      performanceMode: FaceDetectorMode.fast, minFaceSize: 0.15,
    ),
  );
  bool _wasOpen = false, _sawClose = false;
  bool blinkConfirmed = false;

  Future<FaceAnalysisResult> analyzeFace(InputImage image, double frameArea) async {
    List<Face> faces;
    try { faces = await _detector.processImage(image); }
    catch (_) { return const FaceAnalysisResult(FaceIssue.noFace, false, false, 'no_face', 0); }

    if (faces.isEmpty) return const FaceAnalysisResult(FaceIssue.noFace, false, false, 'no_face', 0);
    if (faces.length > 1) return const FaceAnalysisResult(FaceIssue.multipleFaces, false, false, 'multiple_faces', 0);

    final f = faces.first;
    final coverage = (f.boundingBox.width * f.boundingBox.height) / frameArea;
    if (coverage < 0.25) return const FaceAnalysisResult(FaceIssue.tooFar, false, false, 'face_too_far', 0.3);
    if (coverage > 0.70) return const FaceAnalysisResult(FaceIssue.tooClose, false, false, 'face_too_close', 0.3);

    final yaw = f.headEulerAngleY ?? 0, pitch = f.headEulerAngleX ?? 0;
    if (yaw.abs() > 15) return FaceAnalysisResult(FaceIssue.notStraight, false, false, yaw > 0 ? 'face_left' : 'face_right', 0.4);
    if (pitch.abs() > 15) return FaceAnalysisResult(FaceIssue.notStraight, false, false, pitch > 0 ? 'face_down' : 'face_up', 0.4);

    final le = f.leftEyeOpenProbability ?? 1.0, re = f.rightEyeOpenProbability ?? 1.0;
    if (le > 0.8 && re > 0.8) { if (_sawClose && _wasOpen) blinkConfirmed = true; _wasOpen = true; }
    else if (le < 0.4 && re < 0.4) { if (_wasOpen) _sawClose = true; }

    if (!blinkConfirmed) return const FaceAnalysisResult(FaceIssue.none, false, false, 'blink_prompt', 0.6);
    if (le < 0.6 || re < 0.6) return const FaceAnalysisResult(FaceIssue.eyesClosed, false, false, 'eyes_closed', 0.6);
    return const FaceAnalysisResult(FaceIssue.none, true, true, 'face_good', 0.95);
  }

  void reset() { _wasOpen = false; _sawClose = false; blinkConfirmed = false; }
  void dispose() => _detector.close();
}