import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simple Bar Chart Widget
class SimpleBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final double maxValue;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = Colors.blue,
    this.maxValue = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(
        values: values,
        labels: labels,
        barColor: barColor,
        maxValue: maxValue,
      ),
      size: Size.infinite,
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final double maxValue;

  BarChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth = (size.width - 40) / values.length;
    final maxHeight = size.height - 40;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * maxHeight;
      final x = 20 + (i * barWidth) + (barWidth * 0.2);
      final y = size.height - 20 - barHeight;

      paint.color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth * 0.6, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth * 0.3) - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}

/// Simple Line Chart Widget
class SimpleLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LineChartPainter(
        values: values,
        labels: labels,
        lineColor: lineColor,
      ),
      size: Size.infinite,
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;

  LineChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce(math.max);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = lineColor;

    final path = Path();
    final pointWidth = (size.width - 40) / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = 20 + (i * pointWidth);
      final y = size.height - 20 - ((values[i] / maxValue) * (size.height - 40));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }

    canvas.drawPath(path, paint);

    // Draw labels
    for (int i = 0; i < labels.length; i++) {
      final x = 20 + (i * pointWidth);
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

/// Donut Chart Widget
class DonutChart extends StatelessWidget {
  final List<ChartSegment> segments;

  const DonutChart({
    super.key,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DonutChartPainter(segments: segments),
      size: Size.infinite,
    );
  }
}

class ChartSegment {
  final double value;
  final Color color;
  final String label;

  ChartSegment({
    required this.value,
    required this.color,
    required this.label,
  });
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;

  DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final total = segments.fold(0.0, (sum, segment) => sum + segment.value);

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}

/// Map with Pins Widget
class MapWithPins extends StatelessWidget {
  final List<MapPin> pins;
  final Path? routePath;

  const MapWithPins({
    super.key,
    required this.pins,
    this.routePath,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MapWithPinsPainter(
        pins: pins,
        routePath: routePath,
      ),
      size: Size.infinite,
    );
  }
}

class MapPin {
  final Offset position;
  final Color color;
  final String? label;

  MapPin({
    required this.position,
    required this.color,
    this.label,
  });
}

class MapWithPinsPainter extends CustomPainter {
  final List<MapPin> pins;
  final Path? routePath;

  MapWithPinsPainter({
    required this.pins,
    this.routePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw route path
    if (routePath != null) {
      final pathPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.red
        ..strokeCap = StrokeCap.round;

      // Create dashed path
      final dashPath = Path();
      const dashWidth = 5.0;
      const dashSpace = 3.0;
      final pathMetrics = routePath!.computeMetrics();

      for (final pathMetric in pathMetrics) {
        var distance = 0.0;
        while (distance < pathMetric.length) {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + dashWidth),
            Offset.zero,
          );
          distance += dashWidth + dashSpace;
        }
      }

      canvas.drawPath(dashPath, pathPaint);
    }

    // Draw pins
    for (var pin in pins) {
      final paint = Paint()..color = pin.color;
      canvas.drawCircle(pin.position, 8, paint);
      canvas.drawCircle(pin.position, 12, paint..color = pin.color.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant MapWithPinsPainter oldDelegate) => true;
}







