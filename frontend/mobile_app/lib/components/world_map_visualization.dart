import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Professional World Map with Devices and Network Connections
class WorldMapVisualization extends StatefulWidget {
  final bool showDevices;
  final bool showConnections;
  final bool animateConnections;
  final double height;

  const WorldMapVisualization({
    super.key,
    this.showDevices = true,
    this.showConnections = true,
    this.animateConnections = true,
    this.height = 300,
  });

  @override
  State<WorldMapVisualization> createState() => _WorldMapVisualizationState();
}

class _WorldMapVisualizationState extends State<WorldMapVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // World Map Background
          _buildWorldMap(),
          
          // Network Connections
          if (widget.showConnections) _buildConnections(),
          
          // Devices
          if (widget.showDevices) _buildDevices(),
        ],
      ),
    );
  }

  Widget _buildWorldMap() {
    return CustomPaint(
      painter: SimpleWorldMapPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildConnections() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkConnectionsPainter(
            animationValue: widget.animateConnections ? _controller.value : 0.0,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildDevices() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        return Stack(
          children: [
            // Smartphone - North America
            Positioned(
              left: width * 0.15,
              top: height * 0.3,
              child: _buildDeviceIcon(
                Icons.smartphone,
                Colors.black,
                'USA',
              ),
            ),
            // Laptop - South America
            Positioned(
              left: width * 0.2,
              top: height * 0.55,
              child: _buildDeviceIcon(
                Icons.laptop,
                Colors.blue,
                'Brazil',
              ),
            ),
            // Satellite - Africa
            Positioned(
              left: width * 0.35,
              top: height * 0.45,
              child: _buildDeviceIcon(
                Icons.satellite_alt,
                Colors.orange,
                'Africa',
              ),
            ),
            // Server - Asia
            Positioned(
              left: width * 0.55,
              top: height * 0.35,
              child: _buildDeviceIcon(
                Icons.dns,
                Colors.blue,
                'Asia',
              ),
            ),
            // Webcam - Australia
            Positioned(
              left: width * 0.7,
              top: height * 0.65,
              child: _buildDeviceIcon(
                Icons.videocam,
                Colors.grey,
                'Australia',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceIcon(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class SimpleWorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Draw simplified continents
    // North America
    final naPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.15)
      ..lineTo(size.width * 0.35, size.height * 0.12)
      ..lineTo(size.width * 0.4, size.height * 0.25)
      ..lineTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.1, size.height * 0.35)
      ..close();
    canvas.drawPath(naPath, paint);

    // South America
    final saPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height * 0.48)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height * 0.85)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..close();
    canvas.drawPath(saPath, paint);

    // Europe/Africa
    final eafPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.2)
      ..lineTo(size.width * 0.6, size.height * 0.18)
      ..lineTo(size.width * 0.65, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.7)
      ..lineTo(size.width * 0.45, size.height * 0.75)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..close();
    canvas.drawPath(eafPath, paint);

    // Asia
    final asiaPath = Path()
      ..moveTo(size.width * 0.6, size.height * 0.18)
      ..lineTo(size.width * 0.85, size.height * 0.15)
      ..lineTo(size.width * 0.9, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.55)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..close();
    canvas.drawPath(asiaPath, paint);

    // Australia
    final ausPath = Path()
      ..moveTo(size.width * 0.75, size.height * 0.7)
      ..lineTo(size.width * 0.9, size.height * 0.65)
      ..lineTo(size.width * 0.92, size.height * 0.8)
      ..lineTo(size.width * 0.8, size.height * 0.85)
      ..close();
    canvas.drawPath(ausPath, paint);
  }

  @override
  bool shouldRepaint(covariant SimpleWorldMapPainter oldDelegate) => false;
}

class NetworkConnectionsPainter extends CustomPainter {
  final double animationValue;

  NetworkConnectionsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.cyberCyan.withOpacity(0.4);

    // Connection points (normalized to device positions)
    final points = [
      Offset(size.width * 0.15, size.height * 0.3), // USA
      Offset(size.width * 0.2, size.height * 0.55),  // Brazil
      Offset(size.width * 0.35, size.height * 0.45), // Africa
      Offset(size.width * 0.55, size.height * 0.35), // Asia
      Offset(size.width * 0.7, size.height * 0.65),  // Australia
    ];

    // Draw connections
    final connections = [
      [0, 3], // USA to Asia
      [0, 2], // USA to Africa
      [1, 2], // Brazil to Africa
      [1, 4], // Brazil to Australia
      [2, 3], // Africa to Asia
      [2, 4], // Africa to Australia
      [3, 4], // Asia to Australia
    ];

    for (var connection in connections) {
      final from = points[connection[0]];
      final to = points[connection[1]];

      // Draw dashed line
      _drawDashedLine(canvas, from, to, paint);

      // Animated pulse
      final pulseOffset = (animationValue * 2) % 1.0;
      final pulseX = from.dx + (to.dx - from.dx) * pulseOffset;
      final pulseY = from.dy + (to.dy - from.dy) * pulseOffset;

      final pulsePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppTheme.cyberCyan;

      canvas.drawCircle(Offset(pulseX, pulseY), 4, pulsePaint);
      canvas.drawCircle(
        Offset(pulseX, pulseY),
        8,
        pulsePaint..color = AppTheme.cyberCyan.withOpacity(0.3),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final dashPath = pathMetric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(dashPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant NetworkConnectionsPainter oldDelegate) => true;
}
