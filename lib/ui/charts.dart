import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/expense.dart';

class SpendingCharts extends StatefulWidget {
  const SpendingCharts({super.key, required this.expenses});
  final List<Expense> expenses;
  @override
  State<SpendingCharts> createState() => _SpendingChartsState();
}

class _SpendingChartsState extends State<SpendingCharts>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  Category? selected;
  int? day;
  @override
  void didUpdateWidget(covariant SpendingCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    animation.forward(from: 0);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = widget.expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final totals = {
      for (final c in Category.values)
        c: month
            .where((e) => e.category == c)
            .fold<int>(0, (s, e) => s + e.amount),
    };
    final total = totals.values.fold<int>(0, (a, b) => a + b);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final weekly = days
        .map(
          (d) => widget.expenses
              .where(
                (e) =>
                    e.date.year == d.year &&
                    e.date.month == d.month &&
                    e.date.day == d.day,
              )
              .fold<int>(0, (s, e) => s + e.amount),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where it went',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'This month · tap a category to explore',
          style: TextStyle(color: Color(0xFF7B8783)),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: GestureDetector(
              onTapUp: (details) {
                final p = details.localPosition - const Offset(120, 120);
                if (p.distance < 72 || p.distance > 120) return;
                var angle =
                    (math.atan2(p.dy, p.dx) + math.pi / 2) % (math.pi * 2);
                var sum = 0.0;
                for (final c in Category.values) {
                  sum += total == 0 ? 0 : totals[c]! / total * math.pi * 2;
                  if (angle <= sum) {
                    setState(() => selected = selected == c ? null : c);
                    break;
                  }
                }
              },
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => CustomPaint(
                  painter: DonutPainter(
                    totals,
                    Curves.easeOutCubic.transform(animation.value),
                    selected,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected?.label ?? 'MONTHLY TOTAL',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: Color(0xFF7B8783),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          money(selected == null ? total : totals[selected]!),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Category.values
              .map(
                (c) => FilterChip(
                  selected: selected == c,
                  onSelected: (_) =>
                      setState(() => selected = selected == c ? null : c),
                  avatar: CircleAvatar(backgroundColor: c.color, radius: 5),
                  label: Text(
                    '${c.label}  ${total == 0 ? 0 : (totals[c]! / total * 100).round()}%',
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
        const Text(
          'Your week, at a glance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          day == null
              ? 'Last 7 days · ${money(weekly.fold(0, (a, b) => a + b))}'
              : '${days[day!].day}/${days[day!].month} · ${money(weekly[day!])}',
          style: const TextStyle(color: Color(0xFF7B8783)),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 170,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, box) => GestureDetector(
              onTapUp: (d) => setState(
                () => day = (d.localPosition.dx / (box.maxWidth / 7))
                    .floor()
                    .clamp(0, 6),
              ),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => CustomPaint(
                  painter: WeeklyPainter(weekly, days, animation.value, day),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.progress, this.selected);
  final Map<Category, int> values;
  final double progress;
  final Category? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 18,
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      p..color = const Color(0xFFEAF0EB),
    );
    final total = values.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final c in Category.values) {
      final sweep = values[c]! / total * 2 * math.pi * progress;
      if (sweep > 0) {
        p
          ..color = c.color.withValues(
            alpha: selected == null || selected == c ? 1 : .3,
          )
          ..strokeWidth = selected == c ? 32 : 25;
        canvas.drawArc(rect, start + .025, math.max(0, sweep - .05), false, p);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}

class WeeklyPainter extends CustomPainter {
  WeeklyPainter(this.values, this.days, this.progress, this.selected);
  final List<int> values;
  final List<DateTime> days;
  final double progress;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(1, values.reduce(math.max));
    final step = size.width / 7;
    final paint = Paint()..color = const Color(0xFFE8EEE8);
    for (var j = 0; j < 3; j++) {
      final y = 15 + j * (size.height - 45) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var i = 0; i < 7; i++) {
      final h =
          (size.height - 45) *
          values[i] /
          maxValue *
          Curves.easeOutCubic.transform(progress);
      paint.color = selected == i
          ? const Color(0xFFF4B860)
          : const Color(0xFF246B52);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            step * i + step * .23,
            size.height - 28 - math.max(3, h),
            step * .54,
            math.max(3, h),
          ),
          const Radius.circular(6),
        ),
        paint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[days[i].weekday - 1],
          style: const TextStyle(fontSize: 12, color: Color(0xFF7B8783)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(step * i + (step - tp.width) / 2, size.height - 17),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyPainter old) => true;
}
