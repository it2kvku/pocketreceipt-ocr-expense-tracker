import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr_layout.dart';

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
      final text = reconstructReceiptRows([
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              height: line.boundingBox.height,
            ),
      ]);
      return OcrResult(text, timer.elapsedMilliseconds);
    } finally {
      await recognizer.close();
    }
  }
}
