import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_receipt/domain/receipt_parser.dart';
import 'package:pocket_receipt/domain/expense.dart';

void main() {
  final parser = ReceiptParser();
  for (final input in [
    '150,000',
    '150.000',
    '150 000',
    '150000',
    '150,000 VND',
    '150.000 đ',
    '150000 ₫',
    '150,000.00',
  ]) {
    test(
      'VND amount $input',
      () => expect(ReceiptParser.parseAmount(input), 150000),
    );
  }
  for (final input in ['0', '-100', '1.25', 'abc', '12,34', '9999999999999']) {
    test(
      'Reject invalid amount $input',
      () => expect(ReceiptParser.parseAmount(input), isNull),
    );
  }
  test('Parses complete receipt, excludes cash/change/subtotal', () {
    final r = parser.parse(sampleReceipt);
    expect(r.merchant, 'GREEN MART');
    expect(r.amount, 150000);
    expect(r.date, DateTime(2026, 10, 7));
    expect(r.warnings, isEmpty);
  });
  test('Vietnamese grand total has priority', () {
    expect(
      parser
          .parse(
            'SIÊU THỊ ABC\nTạm tính 100.000\nVAT 10.000\nTỔNG CỘNG: 110.000 đ\nTiền khách đưa 200.000\nTiền thừa 90.000',
          )
          .amount,
      110000,
    );
  });
  test('Finds total on next line', () {
    expect(parser.parse('ABC MART\nTOTAL\n150,000 VND').amount, 150000);
  });
  test('Warns on ambiguous totals', () {
    final r = parser.parse('SHOP\nTOTAL 90,000\nGRAND TOTAL 100,000');
    expect(r.amount, 100000);
    expect(r.warnings.any((s) => s.contains('Multiple')), isTrue);
  });
  test('Does not invent total from line items', () {
    expect(parser.parse('SHOP\nMilk 50,000\nBread 30,000').amount, isNull);
  });
  test('Rejects impossible calendar dates', () {
    expect(parser.parse('SHOP\n31/02/2026\nTOTAL 50000').date, isNull);
  });
  test('Accepts leap day and two digit year', () {
    expect(parser.parse('SHOP\n29/02/24').date, DateTime(2024, 2, 29));
  });
  test('Categorizes bookshop', () {
    expect(
      parser.parse('Campus Bookshop\nTOTAL 80000').category,
      Category.study,
    );
  });
  test('Empty OCR produces review warnings', () {
    final r = parser.parse('');
    expect(r.amount, isNull);
    expect(r.merchant, isNull);
    expect(r.warnings.length, 3);
  });
}
