import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for performing OCR on receipt images using ML Kit
class TextRecognitionService {
  final TextRecognizer _textRecognizer;

  TextRecognitionService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return recognizedText.text;
  }

  /// Extract text with confidence score
  Future<RecognizedTextResult> extractTextWithDetails(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Confidence is not available in this version of ML Kit
    // Return a default confidence based on whether we got text
    final confidence = recognizedText.text.isNotEmpty ? 0.85 : 0.0;

    return RecognizedTextResult(
      text: recognizedText.text,
      confidence: confidence,
    );
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of text recognition with confidence score
class RecognizedTextResult {
  final String text;
  final double confidence;

  RecognizedTextResult({
    required this.text,
    required this.confidence,
  });
}
