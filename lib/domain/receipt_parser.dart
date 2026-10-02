import 'expense.dart';

class ParseResult {
  const ParseResult({
    this.merchant,
    this.amount,
    this.date,
    required this.category,
    required this.warnings,
  });
  final String? merchant;
  final int? amount;
  final DateTime? date;
  final Category category;
  final List<String> warnings;
}

/// Conservative VND parser: integer dong, grouped commas/dots/spaces.
/// Never substitutes an item price for an explicitly labelled grand total.
class ReceiptParser {
  static String normalize(String s) {
    const groups = [
      'àáạảãâầấậẩẫăằắặẳẵ',
      'èéẹẻẽêềếệểễ',
      'ìíịỉĩ',
      'òóọỏõôồốộổỗơờớợởỡ',
      'ùúụủũưừứựửữ',
      'ỳýỵỷỹ',
      'đ',
    ];
    const replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
    var result = s.toLowerCase();
    for (var i = 0; i < groups.length; i++) {
      for (final rune in groups[i].runes) {
        result = result.replaceAll(String.fromCharCode(rune), replacements[i]);
      }
    }
    return result;
  }

  static int? parseAmount(String input) {
    var s = normalize(input).replaceAll(RegExp(r'vnd|dong|₫|d'), '').trim();
    // Decimal fractions are accepted only when zero: VND has no fractional unit.
    s = s.replaceFirst(RegExp(r'[.,]00$'), '');
    if (!RegExp(r'^\d{1,3}([., ]\d{3})+$|^\d+$').hasMatch(s)) return null;
    final value = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    return value != null && value > 0 && value <= 999999999999 ? value : null;
  }

  ParseResult parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    String? merchant;
    DateTime? date;
    int? total;
    var bestScore = -1;
    final warnings = <String>[];
    final amounts = <int>{};
    final datePattern = RegExp(
      r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2})\b',
    );
    final amountPattern = RegExp(
      r'\d{1,3}(?:[., ]\d{3})+(?:[.,]00)?|\d+(?:[.,]00)?',
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final n = normalize(line);
      final dm = datePattern.firstMatch(line);
      if (dm != null && date == null) {
        final d = int.parse(dm[1]!);
        final m = int.parse(dm[2]!);
        var y = int.parse(dm[3]!);
        if (y < 100) y += 2000;
        final candidate = DateTime(y, m, d);
        if (candidate.year == y &&
            candidate.month == m &&
            candidate.day == d &&
            y >= 2000 &&
            y <= 2100) {
          date = candidate;
        }
      }
      if (merchant == null &&
          i < 6 &&
          RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line) &&
          !RegExp(
            r'hoa don|receipt|invoice|dia chi|address|tel|phone|mst|tax|date|ngay|www\.|http',
          ).hasMatch(n) &&
          !RegExp(r'^\d').hasMatch(line) &&
          line.length >= 3) {
        merchant = line;
      }
      if (RegExp(
        r'subtotal|sub total|tam tinh|tien thua|change|cash|tien khach|khach dua|discount|giam gia|vat|thue',
      ).hasMatch(n)) {
        continue;
      }
      final score =
          RegExp(r'grand total|tong cong|thanh toan|amount due|tong thanh toan')
              .hasMatch(n)
          ? 3
          : RegExp(r'\btotal\b|\btong\b').hasMatch(n)
          ? 2
          : -1;
      if (score < 0) continue;
      final matches = amountPattern.allMatches(line).toList();
      int? amount;
      if (matches.isNotEmpty) amount = parseAmount(matches.last[0]!);
      if (amount == null &&
          i + 1 < lines.length &&
          RegExp(r'^[\d\s.,₫đVNDvnd]+$').hasMatch(lines[i + 1])) {
        amount = parseAmount(lines[i + 1]);
      }
      if (amount != null) {
        amounts.add(amount);
        if (score >= bestScore) {
          total = amount;
          bestScore = score;
        }
      }
    }
    if (merchant == null) {
      warnings.add('Merchant not found. Enter it manually.');
    }
    if (total == null) {
      warnings.add(
        'No labelled total found. Check the receipt and enter the amount.',
      );
    }
    if (date == null) {
      warnings.add('Valid receipt date not found. Today is suggested.');
    }
    if (amounts.length > 1) {
      warnings.add('Multiple totals found. Verify the selected amount.');
    }
    final n = normalize(text);
    final category =
        RegExp(r'book|sach|stationery|school|university').hasMatch(n)
        ? Category.study
        : RegExp(r'grab|taxi|bus|train|petrol|xang').hasMatch(n)
        ? Category.travel
        : RegExp(r'cinema|movie|netflix|game').hasMatch(n)
        ? Category.entertainment
        : RegExp(r'electronic|headphone|laptop|gear').hasMatch(n)
        ? Category.gear
        : Category.food;
    return ParseResult(
      merchant: merchant,
      amount: total,
      date: date,
      category: category,
      warnings: warnings,
    );
  }
}

const sampleReceipt =
    'GREEN MART\n12 Nguyen Van Linh, Da Nang\nDate: 07/10/2026\nMilk          35,000\nBread         25,000\nFruit         90,000\nSubtotal     150,000\nTOTAL        150.000 đ\nCash         200,000\nChange        50,000\nThank you!';
