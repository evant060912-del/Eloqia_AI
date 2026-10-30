/// Visuals for IELTS Academic Task 1, drawn by the app from invented data.
///
/// The same data produces [ExamVisual.describe], the factual description
/// Mia receives as the task's source material, so her review can check every
/// figure the learner quotes. Pure Dart (no Flutter import).
library;

enum ExamVisualKind { bar, line, pie, table, process, map }

/// One line of a chart, one row of a table or one pie.
class ChartSeries {
  const ChartSeries(this.name, this.values);

  final String name;
  final List<double> values;
}

enum MapFeatureKind { building, housing, green, water, road, facility, sand }

/// A feature of a plan, in a 0–1 frame (x to the east, y to the south).
class MapFeature {
  const MapFeature(
    this.label,
    this.kind,
    this.x,
    this.y,
    this.width,
    this.height,
  );

  final String label;
  final MapFeatureKind kind;
  final double x;
  final double y;
  final double width;
  final double height;

  /// "north-west", "centre", "south"...
  String get area {
    final double cx = x + width / 2;
    final double cy = y + height / 2;
    final String ns = cy < 0.34
        ? 'north'
        : cy > 0.66
        ? 'south'
        : '';
    final String ew = cx < 0.34
        ? 'west'
        : cx > 0.66
        ? 'east'
        : '';
    if (ns.isEmpty && ew.isEmpty) return 'centre';
    if (ns.isEmpty) return ew;
    if (ew.isEmpty) return ns;
    return '$ns-$ew';
  }
}

class MapPlan {
  const MapPlan(this.label, this.features);

  final String label;
  final List<MapFeature> features;
}

class ExamVisual {
  const ExamVisual({
    required this.kind,
    required this.title,
    this.unit = '',
    this.axisLabel = '',
    this.categories = const <String>[],
    this.series = const <ChartSeries>[],
    this.steps = const <String>[],
    this.plans = const <MapPlan>[],
  });

  final ExamVisualKind kind;
  final String title;

  /// Unit of the values ("%", "millions", "hours per week").
  final String unit;

  /// What the categories are (years, countries...), for bar and line charts.
  final String axisLabel;

  /// Bar/line: x labels. Pie: slice labels. Table: column headers.
  final List<String> categories;

  /// Bar/line: one series per line or bar colour. Pie: one series per pie.
  /// Table: one series per row.
  final List<ChartSeries> series;

  /// Process stages, in order.
  final List<String> steps;

  /// Map: two plans to compare (e.g. "1995" and "Today").
  final List<MapPlan> plans;

  String get kindLabel => switch (kind) {
    ExamVisualKind.bar => 'Bar chart',
    ExamVisualKind.line => 'Line graph',
    ExamVisualKind.pie => series.length > 1 ? 'Pie charts' : 'Pie chart',
    ExamVisualKind.table => 'Table',
    ExamVisualKind.process => 'Process diagram',
    ExamVisualKind.map => 'Maps',
  };

  /// True when the data is consistent enough to draw and describe.
  bool get isValid => switch (kind) {
    ExamVisualKind.bar ||
    ExamVisualKind.line ||
    ExamVisualKind.table ||
    ExamVisualKind.pie =>
      categories.isNotEmpty &&
          series.isNotEmpty &&
          series.every(
            (ChartSeries s) =>
                s.values.length == categories.length &&
                s.values.every((double v) => v >= 0),
          ),
    ExamVisualKind.process => steps.length >= 3,
    ExamVisualKind.map =>
      plans.length >= 2 &&
          plans.every(
            (MapPlan p) =>
                p.features.isNotEmpty &&
                p.features.every(
                  (MapFeature f) =>
                      f.x >= 0 &&
                      f.y >= 0 &&
                      f.x + f.width <= 1.0001 &&
                      f.y + f.height <= 1.0001,
                ),
          ),
  };

  /// Largest value of the chart (0 when there are no values).
  double get maxValue {
    double top = 0;
    for (final ChartSeries s in series) {
      for (final double v in s.values) {
        if (v > top) top = v;
      }
    }
    return top;
  }

  /// Factual description sent to Mia as the task's source material.
  String describe() {
    final StringBuffer out = StringBuffer('$kindLabel: $title.');
    final String unitText = unit.isEmpty ? '' : ' Unit: $unit.';
    switch (kind) {
      case ExamVisualKind.bar:
      case ExamVisualKind.line:
        out.write(unitText);
        if (axisLabel.isNotEmpty) out.write(' By $axisLabel.');
        for (final ChartSeries s in series) {
          out.write(' ${s.name}: ');
          out.write(_pairs(categories, s.values));
          out.write('.');
        }
      case ExamVisualKind.pie:
        out.write(unitText);
        for (final ChartSeries s in series) {
          out.write(' ${s.name}: ');
          out.write(_pairs(categories, s.values));
          out.write('.');
        }
      case ExamVisualKind.table:
        out.write(unitText);
        out.write(' Columns: ${categories.join(', ')}.');
        for (final ChartSeries s in series) {
          out.write(' ${s.name}: ');
          out.write(_pairs(categories, s.values));
          out.write('.');
        }
      case ExamVisualKind.process:
        out.write(' Stages in order:');
        for (int i = 0; i < steps.length; i++) {
          out.write(' ${i + 1}. ${steps[i]}.');
        }
      case ExamVisualKind.map:
        for (final MapPlan plan in plans) {
          out.write(' ${plan.label}:');
          out.write(
            plan.features
                .map((MapFeature f) => ' ${f.label} (${f.area})')
                .join(';'),
          );
          out.write('.');
        }
    }
    out.write(' All data is invented for practice.');
    return out.toString();
  }

  static String _pairs(List<String> labels, List<double> values) {
    final List<String> items = <String>[];
    for (int i = 0; i < labels.length && i < values.length; i++) {
      items.add('${labels[i]} ${formatValue(values[i])}');
    }
    return items.join(', ');
  }
}

/// 12.0 -> "12", 12.5 -> "12.5", 1234.0 -> "1,234".
String formatValue(double value) {
  final bool whole = value == value.roundToDouble();
  final String raw = whole
      ? value.round().toString()
      : value.toStringAsFixed(1);
  final List<String> parts = raw.split('.');
  final String digits = parts.first;
  final StringBuffer grouped = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int fromEnd = digits.length - i;
    grouped.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1 && digits[i] != '-') grouped.write(',');
  }
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
}
