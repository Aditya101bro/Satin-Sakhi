import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/document_type.dart';

class DocumentVerificationResult {
  final bool isCorrectDocument;
  final double confidence;
  final String? extractedNumber;
  const DocumentVerificationResult(this.isCorrectDocument, this.confidence, this.extractedNumber);
}

class DocumentAnalyzer {
  final TextRecognizer _latin = TextRecognizer(script: TextRecognitionScript.latin);

  Future<DocumentVerificationResult> verifyDocument(InputImage image, DocumentType expected) async {
    String text = '';
    try {
      final r = await _latin.processImage(image);
      text += ' ${r.text}';
    } catch (_) {}

    final lower = text.toLowerCase();
    final kws = expected.keywords;
    int hits = 0;
    for (final k in kws) {
      if (lower.contains(k.toLowerCase())) hits++;
    }
    final confidence = kws.isEmpty ? 0.0 : hits / kws.length;
    final ok = confidence >= 0.25 || hits >= 1;
    return DocumentVerificationResult(ok, confidence.toDouble(), _extractNumber(text, expected));
  }

  String? _extractNumber(String text, DocumentType type) {
    final clean = text.replaceAll('\n', ' ');
    switch (type) {
      case DocumentType.aadhaar:
        final m = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b').firstMatch(clean);
        return m?.group(0)?.replaceAll(' ', '');
      case DocumentType.pan:
        final m = RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b').firstMatch(clean.toUpperCase());
        return m?.group(0);
      default:
        return null;
    }
  }

  void dispose() {
    _latin.close();
  }
}
