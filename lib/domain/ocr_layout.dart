import 'dart:math' as math;

/// ML Kit often returns a receipt's price column as a separate block.
/// Rejoin spatially aligned lines before applying text-only heuristics.
class OcrLine {
  const OcrLine(
    this.text, {
    required this.left,
    required this.top,
    required this.height,
  });
  final String text;
  final double left, top, height;
  double get centerY => top + height / 2;
}

String reconstructReceiptRows(List<OcrLine> input) {
  final sorted = [...input]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    if (rows.isEmpty) {
      rows.add([line]);
      continue;
    }
    final anchor = rows.last.first;
    final tolerance = math.min(anchor.height, line.height) * .65;
    if ((line.centerY - anchor.centerY).abs() <= tolerance) {
      rows.last.add(line);
    } else {
      rows.add([line]);
    }
  }
  return rows
      .map((row) {
        row.sort((a, b) => a.left.compareTo(b.left));
        return row.map((line) => line.text).join('  ');
      })
      .join('\n');
}
