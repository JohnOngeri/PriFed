import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class CinematicBankCollaborationBackground extends StatefulWidget {
  const CinematicBankCollaborationBackground({super.key});

  @override
  State<CinematicBankCollaborationBackground> createState() =>
      _CinematicBankCollaborationBackgroundState();
}

class _CinematicBankCollaborationBackgroundState
    extends State<CinematicBankCollaborationBackground>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _flowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _flowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BankCollaborationPainter(
        mainAnimation: _mainController,
        pulseAnimation: _pulseController,
        flowAnimation: _flowController,
        particleAnimation: _particleController,
      ),
      child: Container(),
    );
  }
}

class BankCollaborationPainter extends CustomPainter {
  final Animation<double> mainAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> flowAnimation;
  final Animation<double> particleAnimation;

  BankCollaborationPainter({
    required this.mainAnimation,
    required this.pulseAnimation,
    required this.flowAnimation,
    required this.particleAnimation,
  }) : super(repaint: Listenable.merge([
          mainAnimation,
          pulseAnimation,
          flowAnimation,
          particleAnimation,
        ]));

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.deepNavy,
        Colors.black,
        AppTheme.deepNavy.withOpacity(0.8),
      ],
    );

    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundPaint = Paint()
      ..shader = backgroundGradient.createShader(backgroundRect);
    canvas.drawRect(backgroundRect, backgroundPaint);

    // Draw network grid
    _drawNetworkGrid(canvas, size);

    // Draw bank buildings
    final banks = _getBankPositions(size);
    for (int i = 0; i < banks.length; i++) {
      _drawBankBuilding(canvas, banks[i], i, size);
    }

    // Draw data flows between banks
    _drawDataFlows(canvas, banks, size);

    // Draw particles
    _drawParticles(canvas, size);

    // Draw central hub
    _drawCentralHub(canvas, size);
  }

  void _drawNetworkGrid(Canvas canvas, Size size) {
    // Mix of blue and orange grid lines
    final blueGridPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.08)
      ..strokeWidth = 0.5;
    
    final orangeGridPaint = Paint()
      ..color = AppTheme.plasmaOrange.withOpacity(0.05)
      ..strokeWidth = 0.5;

    // Horizontal lines (alternating blue and orange)
    for (int i = 0; i < 10; i++) {
      final y = (i * size.height / 10) +
          (math.sin(mainAnimation.value * 2 * math.pi + i) * 5);
      final paint = (i % 2 == 0) ? blueGridPaint : orangeGridPaint;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical lines (alternating blue and orange)
    for (int i = 0; i < 15; i++) {
      final x = (i * size.width / 15) +
          (math.cos(mainAnimation.value * 2 * math.pi + i) * 5);
      final paint = (i % 2 == 0) ? blueGridPaint : orangeGridPaint;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  List<Offset> _getBankPositions(Size size) {
    return [
      Offset(size.width * 0.15, size.height * 0.3), // Top left
      Offset(size.width * 0.85, size.height * 0.25), // Top right
      Offset(size.width * 0.2, size.height * 0.75), // Bottom left
      Offset(size.width * 0.8, size.height * 0.7), // Bottom right
      Offset(size.width * 0.5, size.height * 0.15), // Top center
      Offset(size.width * 0.5, size.height * 0.85), // Bottom center
    ];
  }

  void _drawBankBuilding(Canvas canvas, Offset position, int index, Size size) {
    final colors = [
      AppTheme.cyberCyan,      // Blue
      AppTheme.electricBlue,   // Bright Blue
      AppTheme.plasmaOrange,   // Orange
      AppTheme.privacyPurple,  // Purple
      AppTheme.cyberCyan,      // Blue
      AppTheme.electricBlue,   // Bright Blue
    ];

    final bankColor = colors[index % colors.length];
    final pulse = pulseAnimation.value;
    final glow = 0.3 + (pulse * 0.2);

    // Building base glow
    final glowPaint = Paint()
      ..color = bankColor.withOpacity(glow * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Building structure (isometric style)
    final buildingWidth = 60.0;
    final buildingHeight = 80.0 + (index % 3) * 20.0;

    // Draw building shadow
    final shadowPath = Path()
      ..moveTo(position.dx - buildingWidth / 2, position.dy)
      ..lineTo(position.dx - buildingWidth / 2 + 10, position.dy - 10)
      ..lineTo(position.dx + buildingWidth / 2 + 10, position.dy - 10)
      ..lineTo(position.dx + buildingWidth / 2, position.dy)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw building front face
    final frontPath = Path()
      ..moveTo(position.dx - buildingWidth / 2, position.dy)
      ..lineTo(position.dx - buildingWidth / 2, position.dy - buildingHeight)
      ..lineTo(position.dx + buildingWidth / 2, position.dy - buildingHeight)
      ..lineTo(position.dx + buildingWidth / 2, position.dy)
      ..close();

    final frontPaint = Paint()
      ..color = bankColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(frontPath, frontPaint);

    // Draw building side face
    final sidePath = Path()
      ..moveTo(position.dx + buildingWidth / 2, position.dy)
      ..lineTo(position.dx + buildingWidth / 2 + 10, position.dy - 10)
      ..lineTo(position.dx + buildingWidth / 2 + 10, position.dy - buildingHeight - 10)
      ..lineTo(position.dx + buildingWidth / 2, position.dy - buildingHeight)
      ..close();

    final sidePaint = Paint()
      ..color = bankColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sidePath, sidePaint);

    // Draw windows
    final windowPaint = Paint()
      ..color = bankColor.withOpacity(0.8 + pulse * 0.2)
      ..style = PaintingStyle.fill;

    final windowRows = 5;
    final windowCols = 3;
    final windowSize = 6.0;

    for (int row = 0; row < windowRows; row++) {
      for (int col = 0; col < windowCols; col++) {
        if ((row + col + index) % 2 == 0) {
          final windowX = position.dx -
              buildingWidth / 2 +
              (col + 1) * (buildingWidth / (windowCols + 1));
          final windowY = position.dy -
              buildingHeight +
              (row + 1) * (buildingHeight / (windowRows + 1));

          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(windowX, windowY),
              width: windowSize,
              height: windowSize,
            ),
            windowPaint,
          );
        }
      }
    }

    // Draw glow around building
    canvas.drawCircle(position, buildingWidth, glowPaint);
  }

  void _drawDataFlows(Canvas canvas, List<Offset> banks, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw connections from each bank to center
    for (int i = 0; i < banks.length; i++) {
      final bank = banks[i];
      // Alternate between blue and orange for connections
      final connectionColor = (i % 2 == 0) ? AppTheme.cyberCyan : AppTheme.plasmaOrange;
      
      final connectionPaint = Paint()
        ..color = connectionColor.withOpacity(0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(bank, center, connectionPaint);

      // Draw flowing data particles
      final flowProgress = flowAnimation.value;
      final flowPoint = Offset.lerp(
        bank,
        center,
        flowProgress,
      )!;

      final particlePaint = Paint()
        ..color = connectionColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(flowPoint, 4, particlePaint);
      canvas.drawCircle(flowPoint, 8, particlePaint..color = connectionColor.withOpacity(0.3));
    }

    // Draw connections between banks (blue/orange theme)
    for (int i = 0; i < banks.length; i++) {
      for (int j = i + 1; j < banks.length; j++) {
        final connectionPaint = Paint()
          ..color = AppTheme.cyberCyan.withOpacity(0.2)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        canvas.drawLine(banks[i], banks[j], connectionPaint);
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    final particleCount = 30;
    
    // Mix of blue, orange, and purple particles
    final particleColors = [
      AppTheme.cyberCyan,
      AppTheme.electricBlue,
      AppTheme.plasmaOrange,
      AppTheme.privacyPurple,
    ];

    for (int i = 0; i < particleCount; i++) {
      final progress = (particleAnimation.value + (i / particleCount)) % 1.0;
      final angle = (i * 2 * math.pi / particleCount) + (mainAnimation.value * 2 * math.pi);
      final radius = size.width * 0.3;
      final x = size.width / 2 + math.cos(angle) * radius * progress;
      final y = size.height / 2 + math.sin(angle) * radius * progress;

      final particleColor = particleColors[i % particleColors.length];
      final particlePaint = Paint()
        ..color = particleColor
        ..style = PaintingStyle.fill;

      final particleSize = 2.0 + (math.sin(progress * 2 * math.pi) * 1.0);
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        particlePaint..color = particleColor.withOpacity(0.6 - progress * 0.4),
      );
    }
  }

  void _drawCentralHub(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pulse = pulseAnimation.value;
    final hubSize = 40.0 + (pulse * 10);

    // Outer glow rings (blue and orange alternating)
    for (int i = 0; i < 3; i++) {
      final ringColor = (i % 2 == 0) ? AppTheme.cyberCyan : AppTheme.plasmaOrange;
      final ringPaint = Paint()
        ..color = ringColor.withOpacity(0.25 - (i * 0.05))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final ringSize = hubSize + (i * 20) + (pulse * 5);
      canvas.drawCircle(center, ringSize, ringPaint);
    }

    // Central hub (hexagon) with blue/orange gradient
    final hexPath = Path();
    final hexRadius = hubSize;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (mainAnimation.value * 2 * math.pi * 0.1);
      final x = center.dx + math.cos(angle) * hexRadius;
      final y = center.dy + math.sin(angle) * hexRadius;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final hubPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.cyberCyan,
          AppTheme.plasmaOrange,
          AppTheme.electricBlue,
          AppTheme.cyberCyan,
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: hexRadius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(hexPath, hubPaint);

    // Inner core (white/orange glow)
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9 + pulse * 0.1),
          AppTheme.plasmaOrange.withOpacity(0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: hubSize * 0.4))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubSize * 0.4, corePaint);
  }

  @override
  bool shouldRepaint(BankCollaborationPainter oldDelegate) => true;
}

