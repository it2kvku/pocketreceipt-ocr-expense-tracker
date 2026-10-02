import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pocket_receipt/data/store_native.dart';
import 'package:pocket_receipt/domain/expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SQLite insert, update, reload and delete persist correctly', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('pocket_receipt_test_');
    await databaseFactory.setDatabasesPath(dir.path);
    final store = ExpenseStore();
    const id = 'test';
    await store.save(
      Expense(
        id: id,
        merchant: 'Bookshop',
        amount: 85000,
        date: DateTime(2026, 10, 7),
        category: Category.study,
      ),
    );
    expect((await store.load()).single.amount, 85000);
    await store.save(
      Expense(
        id: id,
        merchant: 'Bookshop',
        amount: 90000,
        date: DateTime(2026, 10, 7),
        category: Category.study,
      ),
    );
    await (await store.database).close();
    final reopened = ExpenseStore();
    final all = await reopened.load();
    expect(all.length, 1);
    expect(all.single.amount, 90000);
    await reopened.delete(all.single);
    expect(await reopened.load(), isEmpty);
    await (await reopened.database).close();
    await dir.delete(recursive: true);
  });
}
