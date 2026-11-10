import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? C.card(context)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: C.text(context))),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// حلقه پیشرفت
class Ring extends StatelessWidget {
  final double value; // ۰ تا ۱ (بیشتر از ۱ هم مجاز است)
  final double size;
  final double stroke;
  final Color color;
  final Color? track;
  final Widget? child;

  const Ring({
    super.key,
    required this.value,
    this.size = 120,
    this.stroke = 12,
    this.color = C.green,
    this.track,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value.isNaN ? 0 : value.clamp(0.0, 1.0),
          stroke,
          color,
          track ?? Colors.white.withOpacity(0.18),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.v, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * v, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.v != v || o.color != color || o.stroke != stroke || o.track != track;
}

/// نوار درشت‌مغذی
class MacroBar extends StatelessWidget {
  final String label;
  final String valueText;
  final double ratio;
  final Color color;
  const MacroBar({
    super.key,
    required this.label,
    required this.valueText,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: C.muted(context))),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.isNaN ? 0 : ratio.clamp(0.0, 1.0),
            minHeight: 7,
            color: color,
            backgroundColor: C.card2(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(valueText,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: C.text(context))),
      ],
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirmDialog(BuildContext context, String title, String body,
    {String ok = 'تأیید', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok, style: TextStyle(color: danger ? C.red : C.green)),
        ),
      ],
    ),
  );
  return r ?? false;
}
