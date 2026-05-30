enum CaptureStatus { notReady, ready, captured }
enum DocumentIssue { blur, veryBlur, lowLight, glare, tooBright, tooFar, tooClose, partial, tilted, occluded, wrongDocument, none }
enum FaceIssue { noFace, tooFar, tooClose, notStraight, eyesClosed, masked, multipleFaces, badBackground, unevenLight, faceBlur, none }

class AnalysisResult {
  final CaptureStatus status;
  final DocumentIssue documentIssue;
  final FaceIssue faceIssue;
  final double confidence;
  final String message;
  final String audioKey;
  const AnalysisResult({
    this.status = CaptureStatus.notReady,
    this.documentIssue = DocumentIssue.none,
    this.faceIssue = FaceIssue.none,
    this.confidence = 0.0,
    this.message = '',
    this.audioKey = '',
  });
  bool get isReady => status == CaptureStatus.ready;
}