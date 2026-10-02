import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum Category {
  food('Food', Icons.restaurant_rounded, Color(0xFFF4B860)),
  study('Study', Icons.auto_stories_rounded, Color(0xFF82B4FF)),
  travel('Travel', Icons.train_rounded, Color(0xFF95D5B2)),
  gear('Gear', Icons.headphones_rounded, Color(0xFFB5A1E5)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFFF49B9B));

  const Category(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

String money(int value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} ₫';

class Expense {
  const Expense({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptPath,
    this.rawText = '',
  });
  final String id;
  final String merchant;
  final int amount;
  final DateTime date;
  final Category category;
  final String? receiptPath;
  final String rawText;
  Map<String, Object?> toMap() => {
    'id': id,
    'merchant': merchant,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'receiptPath': receiptPath,
    'rawText': rawText,
  };
  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    merchant: m['merchant'] as String,
    amount: m['amount'] as int,
    date: DateTime.parse(m['date'] as String),
    category: Category.values.byName(m['category'] as String),
    receiptPath: m['receiptPath'] as String?,
    rawText: m['rawText'] as String? ?? '',
  );
}
