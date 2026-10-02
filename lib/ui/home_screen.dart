import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/store.dart';
import '../domain/expense.dart';
import '../domain/receipt_parser.dart';
import '../services/ocr_service.dart';
import 'capture_screen.dart';
import 'charts.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = ExpenseStore();
  List<Expense> expenses = [];
  bool loading = true, processing = false;
  String? error;
  int page = 0;
  Category? filter;
  String query = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await store.load();
      if (mounted) {
        setState(() {
          expenses = result;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Could not load expenses. Please retry.';
          loading = false;
        });
      }
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> review({
    Expense? existing,
    String raw = '',
    Uint8List? bytes,
    String? path,
    int? ms,
  }) async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          existing: existing,
          rawText: raw,
          bytes: bytes,
          receiptPath: path,
          ocrMs: ms,
        ),
      ),
    );
    if (result == null) {
      if (existing == null && path != null) await store.discardReceipt(path);
      return;
    }
    try {
      await store.save(result);
      await load();
      message('Expense saved');
    } catch (e) {
      message('Could not save expense. Please try again.');
    }
  }

  Future<void> scan() async {
    if (kIsWeb) {
      await parserDemo();
      return;
    }
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
    if (bytes == null || !mounted) return;
    setState(() => processing = true);
    String? path;
    try {
      path = await store.cacheReceipt(
        bytes,
        DateTime.now().microsecondsSinceEpoch.toString(),
      );
      final result = await OcrService().recognize(path);
      if (!mounted) return;
      setState(() => processing = false);
      await review(
        raw: result.text,
        bytes: bytes,
        path: path,
        ms: result.milliseconds,
      );
    } catch (e) {
      if (path != null) await store.discardReceipt(path);
      message('Recognition failed. Try a clearer photo or add manually.');
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> parserDemo() async {
    final controller = TextEditingController(text: sampleReceipt);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Try the receipt parser'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sample text, not a camera scan. Offline image OCR is available in the Android app.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 11,
                decoration: const InputDecoration(labelText: 'Receipt text'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Parse receipt'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
    if (text != null && mounted) await review(raw: text);
  }

  Future<void> seed() async {
    final now = DateTime.now();
    final examples = [
      ('Green Mart', 150000, Category.food),
      ('Campus Bookshop', 85000, Category.study),
      ('Grab ride', 42000, Category.travel),
      ('Coffee corner', 35000, Category.food),
      ('Cinema night', 95000, Category.entertainment),
      ('Tech accessories', 180000, Category.gear),
    ];
    try {
      for (var i = 0; i < examples.length; i++) {
        final e = examples[i];
        await store.save(
          Expense(
            id: 'sample-$i',
            merchant: e.$1,
            amount: e.$2,
            date: DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: i)),
            category: e.$3,
            rawText: 'Demo data - manually seeded',
          ),
        );
      }
      await load();
      message('Sample expenses added');
    } catch (e) {
      message('Could not add sample expenses');
    }
  }

  Future<void> edit(Expense e) async {
    try {
      final bytes = await store.receiptBytes(e.receiptPath);
      if (mounted) await review(existing: e, raw: e.rawText, bytes: bytes);
    } catch (_) {
      message('Could not open receipt');
    }
  }

  Future<void> remove(Expense e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text(
          '${e.merchant} · ${money(e.amount)}\nThe saved receipt will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      try {
        await store.delete(e);
        await load();
        message('Expense deleted');
      } catch (_) {
        message('Could not delete expense');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final total = month.fold<int>(0, (s, e) => s + e.amount);
    final visible = expenses
        .where(
          (e) =>
              (filter == null || e.category == filter) &&
              e.merchant.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error!),
                            TextButton(
                              onPressed: load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 100),
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF193B2F),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFFDDF4A6),
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Text(
                                  'pocketreceipt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -.7,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'More options',
                                onSelected: (v) {
                                  if (v == 'sample') seed();
                                  if (v == 'parser') parserDemo();
                                  if (v == 'about') {
                                    showAboutDialog(
                                      context: context,
                                      applicationName: 'PocketReceipt',
                                      applicationVersion: '1.0.0',
                                      children: [
                                        const Text(
                                          'Offline-first expense tracking. VND amounts. Camera OCR uses Google ML Kit on Android. Browser companion uses typed text and browser storage. No analytics or cloud upload.',
                                        ),
                                      ],
                                    );
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'parser',
                                    child: Text('Try sample receipt'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'sample',
                                    child: Text('Add sample expenses'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'about',
                                    child: Text('About & privacy'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            page == 0
                                ? 'Little receipts.\nA clearer picture.'
                                : page == 1
                                ? 'Every expense,\nin one place.'
                                : 'Make sense of\nyour spending.',
                            style: const TextStyle(
                              fontSize: 34,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page == 0
                                ? 'Less typing. More living.'
                                : page == 1
                                ? 'Search, review and keep things in order.'
                                : 'Small insights for better everyday choices.',
                            style: const TextStyle(
                              color: Color(0xFF7B8783),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (kIsWeb)
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF0DB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'WEB COMPANION · Try text parsing and charts. Install the Android APK for offline camera OCR.',
                              ),
                            ),
                          if (page == 0) ...[
                            Container(
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: const Color(0xFF193B2F),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy')
                                            .format(now)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.north_east,
                                        color: Color(0xFFDDF4A6),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    money(total),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${month.length} expenses · stored on your device',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDDF4A6),
                                      foregroundColor: const Color(0xFF193B2F),
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                    ),
                                    onPressed: scan,
                                    icon: const Icon(
                                      Icons.document_scanner_outlined,
                                    ),
                                    label: Text(
                                      kIsWeb
                                          ? 'Try receipt parser'
                                          : 'Scan a receipt',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Recent expenses',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => page = 1),
                                  child: const Text('See all'),
                                ),
                              ],
                            ),
                            if (expenses.isEmpty)
                              empty()
                            else
                              ...expenses.take(4).map(tile),
                            const SizedBox(height: 20),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: SpendingCharts(expenses: expenses),
                              ),
                            ),
                          ],
                          if (page == 1) ...[
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search merchants',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (v) => setState(() => query = v),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 7,
                              children: [
                                FilterChip(
                                  label: const Text('All'),
                                  selected: filter == null,
                                  onSelected: (_) =>
                                      setState(() => filter = null),
                                ),
                                ...Category.values.map(
                                  (c) => FilterChip(
                                    label: Text(c.label),
                                    selected: filter == c,
                                    onSelected: (_) => setState(
                                      () => filter = filter == c ? null : c,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (visible.isEmpty)
                              empty()
                            else
                              ...visible.map(tile),
                          ],
                          if (page == 2)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: SpendingCharts(expenses: expenses),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            if (processing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 18),
                          Text('Reading receipt on this device…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: processing ? null : () => review(),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large),
            label: 'Insights',
          ),
        ],
      ),
    );
  }

  Widget empty() => Container(
    padding: const EdgeInsets.all(26),
    alignment: Alignment.center,
    child: Column(
      children: [
        const Icon(Icons.spa_outlined, size: 38, color: Color(0xFF7B8783)),
        const SizedBox(height: 12),
        const Text(
          'A fresh start for your spending.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 7),
        const Text('Scan a receipt or add an expense to begin.'),
        TextButton(
          onPressed: seed,
          child: const Text('Explore with sample data'),
        ),
      ],
    ),
  );
  Widget tile(Expense e) => Card(
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      onTap: () => edit(e),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: e.category.color.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(13),
        ),
        child: e.receiptPath == null
            ? Icon(e.category.icon, color: const Color(0xFF193B2F))
            : FutureBuilder<Uint8List?>(
                future: store.receiptBytes('${e.receiptPath}.thumb.jpg'),
                builder: (context, snapshot) => snapshot.data == null
                    ? Icon(e.category.icon)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      ),
              ),
      ),
      title: Text(
        e.merchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${e.category.label} · ${DateFormat('dd MMM').format(e.date)}${e.receiptPath == null ? '' : ' · receipt'}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF7B8783)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            money(e.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          PopupMenuButton<String>(
            tooltip: 'Expense actions',
            onSelected: (v) => v == 'delete' ? remove(e) : edit(e),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    ),
  );
}
