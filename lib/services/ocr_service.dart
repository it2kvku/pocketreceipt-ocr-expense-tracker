import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult(this.text, this.milliseconds);
  final String text;
  final int milliseconds;
}

class OcrService {
  Future<OcrResult> recognize(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final timer = Stopwatch()..start();
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      timer.stop();
      return OcrResult(result.text, timer.elapsedMilliseconds);
    } finally {
      await recognizer.close();
    }
  }
}
