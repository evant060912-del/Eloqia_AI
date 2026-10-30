import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'exam_visuals.dart';

const List<Color> _seriesColors = <Color>[
  AppColors.primary,
  AppColors.warmth,
  AppColors.secondaryBright,
  AppColors.writing,
  AppColors.grammar,
  AppColors.info,
];

Color _seriesColor(int index) => _seriesColors[index % _seriesColors.length];

/// Draws an IELTS Task 1 visual from its data. Screen readers get the same
/// factual description Mia receives.
class ExamVisualView extends StatelessWidget {
  const ExamVisualView({super.key, required this.visual});

  final ExamVisual visual;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: visual.describe(),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                visual.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (visual.unit.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  visual.unit,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _body(),
              const SizedBox(height: 8),
              const Text(
                'Data invented for practice.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (visual.kind) {
      case ExamVisualKind.bar:
      case ExamVisualKind.line:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.45,
              child: CustomPaint(painter: _ChartPainter(visual)),
            ),
            const SizedBox(height: 8),
            _Legend(
              labels: visual.series.map((ChartSeries s) => s.name).toList(),
            ),
          ],
        );
      case ExamVisualKind.pie:
        return _Pies(visual: visual);
      case ExamVisualKind.table:
        return _DataTable(visual: visual);
      case ExamVisualKind.process:
        return _Process(steps: visual.steps);
      case ExamVisualKind.map:
        return _Maps(plans: visual.plans);
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: <Widget>[
        for (int i = 0; i < labels.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _seriesColor(i),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[i],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Top of the axis and the step between gridlines ("nice" numbers).
({double top, double step}) niceAxis(double maxValue) {
  if (maxValue <= 0) return (top: 1, step: 0.25);
  final double rough = maxValue / 4;
  final double magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  double step = magnitude;
  for (final double m in <double>[1, 2, 2.5, 5, 10]) {
    if (m * magnitude >= rough) {
      step = m * magnitude;
      break;
    }
  }
  final double top = (maxValue / step).ceil() * step;
  return (top: top, step: step);
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.visual);

  final ExamVisual visual;

  static const double _left = 44;
  static const double _bottom = 30;
  static const double _top = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final ({double top, double step}) axis = niceAxis(visual.maxValue);
    final Rect plot = Rect.fromLTRB(
      _left,
      _top,
      size.width - 4,
      size.height - _bottom,
    );
    final Paint grid = Paint()
      ..color = AppColors.white08
      ..strokeWidth = 1;

    for (double v = 0; v <= axis.top + axis.step / 2; v += axis.step) {
      final double y = plot.bottom - v / axis.top * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        formatValue(v),
        Offset(plot.left - 6, y),
        maxWidth: _left - 8,
        alignRight: true,
      );
    }

    final int n = visual.categories.length;
    final double slot = plot.width / n;
    for (int i = 0; i < n; i++) {
      _text(
        canvas,
        visual.categories[i],
        Offset(plot.left + slot * (i + 0.5), plot.bottom + 14),
        maxWidth: slot - 2,
        center: true,
      );
    }

    if (visual.kind == ExamVisualKind.bar) {
      final int count = visual.series.length;
      final double groupWidth = slot * 0.72;
      final double barWidth = groupWidth / count;
      for (int s = 0; s < count; s++) {
        final Paint paint = Paint()..color = _seriesColor(s);
        final List<double> values = visual.series[s].values;
        for (int i = 0; i < n; i++) {
          final double h = values[i] / axis.top * plot.height;
          final double x =
              plot.left + slot * i + (slot - groupWidth) / 2 + barWidth * s;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(x + 1, plot.bottom - h, barWidth - 2, h),
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
            paint,
          );
        }
      }
    } else {
      for (int s = 0; s < visual.series.length; s++) {
        final Paint line = Paint()
          ..color = _seriesColor(s)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;
        final Paint dot = Paint()..color = _seriesColor(s);
        final List<double> values = visual.series[s].values;
        final Path path = Path();
        for (int i = 0; i < n; i++) {
          final Offset p = Offset(
            plot.left + slot * (i + 0.5),
            plot.bottom - values[i] / axis.top * plot.height,
          );
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
          canvas.drawCircle(p, 3.2, dot);
        }
        canvas.drawPath(path, line);
      }
    }

    final Paint axisPaint = Paint()
      ..color = AppColors.white18
      ..strokeWidth = 1.2;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required double maxWidth,
    bool center = false,
    bool alignRight = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(1, maxWidth));
    final double dx = center
        ? at.dx - painter.width / 2
        : alignRight
        ? at.dx - painter.width
        : at.dx;
    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => oldDelegate.visual != visual;
}

class _Pies extends StatelessWidget {
  const _Pies({required this.visual});

  final ExamVisual visual;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final ChartSeries s in visual.series)
              SizedBox(
                width: 150,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(painter: _PiePainter(s.values)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Legend(labels: visual.categories),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (double a, double b) => a + b);
    if (total <= 0) return;
    final Rect box = Offset.zero & size;
    final Offset centre = box.center;
    final double radius = size.shortestSide / 2;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final double sweep = values[i] / total * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = _seriesColor(i),
      );
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        sweep,
        true,
        Paint()
          ..color = AppColors.backgroundElevated
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final double share = values[i] / total;
      if (share >= 0.07) {
        final double middle = start + sweep / 2;
        final Offset at =
            centre + Offset(math.cos(middle), math.sin(middle)) * radius * 0.62;
        final TextPainter label = TextPainter(
          text: TextSpan(
            text: '${formatValue(values[i])}%',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PiePainter oldDelegate) => oldDelegate.values != values;
}

class _DataTable extends StatelessWidget {
  const _DataTable({required this.visual});

  final ExamVisual visual;

  @override
  Widget build(BuildContext context) {
    const TextStyle head = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 12.5,
    );
    const TextStyle cell = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12.5,
    );
    Widget pad(Widget child, {bool end = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Align(
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.symmetric(
          inside: const BorderSide(color: AppColors.white08),
        ),
        children: <TableRow>[
          TableRow(
            decoration: const BoxDecoration(color: AppColors.white05),
            children: <Widget>[
              pad(const Text('', style: head)),
              for (final String c in visual.categories)
                pad(Text(c, style: head), end: true),
            ],
          ),
          for (final ChartSeries row in visual.series)
            TableRow(
              children: <Widget>[
                pad(Text(row.name, style: head)),
                for (final double v in row.values)
                  pad(Text(formatValue(v), style: cell), end: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _Process extends StatelessWidget {
  const _Process({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white12),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ],
    );
  }
}

Color mapFeatureColor(MapFeatureKind kind) => switch (kind) {
  MapFeatureKind.building => AppColors.surfaceInteractive,
  MapFeatureKind.housing => AppColors.warmth.withValues(alpha: 0.55),
  MapFeatureKind.green => AppColors.success.withValues(alpha: 0.45),
  MapFeatureKind.water => AppColors.info.withValues(alpha: 0.55),
  MapFeatureKind.road => AppColors.white18,
  MapFeatureKind.facility => AppColors.secondary.withValues(alpha: 0.6),
  MapFeatureKind.sand => AppColors.xp.withValues(alpha: 0.32),
};

class _Maps extends StatelessWidget {
  const _Maps({required this.plans});

  final List<MapPlan> plans;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool sideBySide = constraints.maxWidth >= 520;
        final double width = sideBySide
            ? (constraints.maxWidth - 12) / plans.length
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final MapPlan plan in plans)
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          plan.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AspectRatio(
                          aspectRatio: 1.25,
                          child: CustomPaint(painter: _MapPainter(plan)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.plan);

  final MapPlan plan;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(frame, Paint()..color = AppColors.background);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.white18
        ..style = PaintingStyle.stroke,
    );
    // Roads first, so buildings sit on top.
    final List<MapFeature> ordered = <MapFeature>[
      ...plan.features.where((MapFeature f) => f.kind == MapFeatureKind.road),
      ...plan.features.where((MapFeature f) => f.kind != MapFeatureKind.road),
    ];
    for (final MapFeature f in ordered) {
      final Rect r = Rect.fromLTWH(
        f.x * size.width,
        f.y * size.height,
        f.width * size.width,
        f.height * size.height,
      ).deflate(1.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(5)),
        Paint()..color = mapFeatureColor(f.kind),
      );
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: f.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: math.max(1, r.width - 4));
      label.paint(canvas, r.center - Offset(label.width / 2, label.height / 2));
    }
    // North arrow.
    final TextPainter north = TextPainter(
      text: const TextSpan(
        text: '↑ N',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    north.paint(canvas, Offset(size.width - north.width - 6, 4));
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => oldDelegate.plan != plan;
}
