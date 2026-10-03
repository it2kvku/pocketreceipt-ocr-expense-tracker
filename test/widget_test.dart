import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_receipt/ui/review_screen.dart';
import 'package:pocket_receipt/ui/charts.dart';
import 'package:pocket_receipt/domain/receipt_parser.dart';

void main() {
  testWidgets('Review pre-fills extracted fields and rejects zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: ReviewScreen(rawText: sampleReceipt)),
    );
    expect(find.text('GREEN MART'), findsOneWidget);
    expect(find.text('150000'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await tester.pump();
    expect(find.text('Enter a positive whole VND amount'), findsOneWidget);
  });
  testWidgets('Empty charts render without NaN or division by zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SpendingCharts(expenses: [])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MONTHLY TOTAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
