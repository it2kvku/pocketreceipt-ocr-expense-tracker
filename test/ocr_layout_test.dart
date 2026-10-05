import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_receipt/domain/ocr_layout.dart';
import 'package:pocket_receipt/domain/receipt_parser.dart';

void main() {
  test('Rejoins shuffled merchant, label and amount blocks by geometry', () {
    final text = reconstructReceiptRows(const [
      OcrLine('TOTAL', left: 10, top: 150, height: 20),
      OcrLine('Cash', left: 10, top: 180, height: 20),
      OcrLine('GREEN MART', left: 10, top: 20, height: 30),
      OcrLine('200,000', left: 200, top: 181, height: 20),
      OcrLine('150,000 VND', left: 200, top: 152, height: 20),
    ]);
    final result = ReceiptParser().parse(text);
    expect(result.merchant, 'GREEN MART');
    expect(result.amount, 150000);
    expect(text.split('\n')[1], 'TOTAL  150,000 VND');
  });
  test('Preserves separate rows and empty OCR', () {
    expect(reconstructReceiptRows([]), '');
    expect(
      reconstructReceiptRows(const [
        OcrLine('TOTAL', left: 0, top: 0, height: 10),
        OcrLine('100,000', left: 0, top: 15, height: 10),
      ]),
      'TOTAL\n100,000',
    );
  });
}
