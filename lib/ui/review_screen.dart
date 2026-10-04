import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/expense.dart';
import '../domain/receipt_parser.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    this.existing,
    this.rawText = '',
    this.receiptPath,
    this.bytes,
    this.ocrMs,
  });
  final Expense? existing;
  final String rawText;
  final String? receiptPath;
  final Uint8List? bytes;
  final int? ocrMs;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final form = GlobalKey<FormState>();
  late final parsed = ReceiptParser().parse(widget.rawText);
  late final merchant = TextEditingController(
    text: widget.existing?.merchant ?? parsed.merchant ?? '',
  );
  late final amount = TextEditingController(
    text: (widget.existing?.amount ?? parsed.amount)?.toString() ?? '',
  );
  late DateTime date = widget.existing?.date ?? parsed.date ?? DateTime.now();
  late Category category = widget.existing?.category ?? parsed.category;
  @override
  void dispose() {
    merchant.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Review receipt' : 'Edit expense'),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFD9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.fact_check_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A quick check, then you’re done.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      widget.ocrMs == null
                          ? 'You are always in control.'
                          : 'On-device OCR · ${widget.ocrMs} ms',
                      style: const TextStyle(color: Color(0xFF7B8783)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.bytes != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                widget.bytes!,
                height: 170,
                fit: BoxFit.contain,
              ),
            ),
          ],
          if (widget.existing == null && widget.rawText.isNotEmpty)
            ...parsed.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '• $w',
                  style: const TextStyle(color: Color(0xFF9A5B15)),
                ),
              ),
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: merchant,
            decoration: const InputDecoration(
              labelText: 'Merchant',
              prefixIcon: Icon(Icons.storefront),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Enter a merchant'
                : v.trim().length > 100
                ? 'Use at most 100 characters'
                : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total amount',
              suffixText: 'VND',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (v) => ReceiptParser.parseAmount(v ?? '') == null
                ? 'Enter a positive whole VND amount'
                : null,
          ),
          const SizedBox(height: 18),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: Colors.white,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Transaction date'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100, 12, 31),
              );
              if (chosen != null) setState(() => date = chosen);
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: Category.values
                .map(
                  (c) => ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 17),
                    selected: category == c,
                    onSelected: (_) => setState(() => category = c),
                  ),
                )
                .toList(),
          ),
          if (widget.rawText.isNotEmpty) ...[
            const SizedBox(height: 18),
            ExpansionTile(
              title: const Text('Original recognized text'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(widget.rawText),
                ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.pop(
                context,
                Expense(
                  id:
                      widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  merchant: merchant.text.trim(),
                  amount: ReceiptParser.parseAmount(amount.text)!,
                  date: DateTime(date.year, date.month, date.day),
                  category: category,
                  receiptPath:
                      widget.receiptPath ?? widget.existing?.receiptPath,
                  rawText: widget.rawText,
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Save expense'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saved privately on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF7B8783)),
          ),
        ],
      ),
    ),
  );
}
