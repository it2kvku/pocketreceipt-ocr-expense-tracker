import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image/image.dart' as img;

import '../domain/expense.dart';

class ExpenseStore {
  Database? _db;
  Future<Database> get database async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'pocket_receipt.db'),
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE expenses(id TEXT PRIMARY KEY, merchant TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0), date TEXT NOT NULL, category TEXT NOT NULL, receiptPath TEXT, rawText TEXT NOT NULL)',
    ),
  );
  Future<List<Expense>> load() async => (await (await database).query(
    'expenses',
    orderBy: 'date DESC',
  )).map(Expense.fromMap).toList();
  Future<void> save(Expense e) async => (await database).insert(
    'expenses',
    e.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<void> delete(Expense e) async {
    await (await database).delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [e.id],
    );
    if (e.receiptPath != null) {
      await discardReceipt(e.receiptPath!);
    }
  }

  Future<String> cacheReceipt(Uint8List bytes, String id) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '$id.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      await File('${file.path}.thumb.jpg').writeAsBytes(
        img.encodeJpg(img.copyResize(decoded, width: 160), quality: 75),
      );
    }
    return file.path;
  }

  Future<Uint8List?> receiptBytes(String? path) async {
    if (path == null) return null;
    final f = File(path);
    return await f.exists() ? f.readAsBytes() : null;
  }

  Future<void> discardReceipt(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
    final thumb = File('$path.thumb.jpg');
    if (await thumb.exists()) await thumb.delete();
  }
}
