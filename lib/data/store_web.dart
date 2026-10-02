import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/expense.dart';

/// Browser companion only. Android always uses SQLite and app-private files.
class ExpenseStore {
  static const key = 'pocket_receipt_v1';
  Future<List<Expense>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (jsonDecode(prefs.getString(key) ?? '[]') as List)
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> save(Expense e) async {
    final all = await load();
    all.removeWhere((x) => x.id == e.id);
    all.add(e);
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(all.map((x) => x.toMap()).toList()),
    );
  }

  Future<void> delete(Expense e) async {
    final all = await load();
    all.removeWhere((x) => x.id == e.id);
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(all.map((x) => x.toMap()).toList()),
    );
  }

  Future<String> cacheReceipt(Uint8List bytes, String id) async =>
      throw UnsupportedError('Use Android for OCR');
  Future<Uint8List?> receiptBytes(String? path) async => null;
  Future<void> discardReceipt(String path) async {}
}
