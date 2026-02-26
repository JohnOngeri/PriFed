import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

// Chart data classes
class ChartData {
  final String label;
  final double value;
  final Color color;
  
  const ChartData(this.label, this.value, this.color);
}

class ChartPoint {
  final double x;
  final double y;
  
  const ChartPoint(this.x, this.y);
}

// Holographic Earth Globe Widget
class HolographicGlobe extends StatefulWidget {
  final double size;
  final bool showConnections;
  final bool showParticles;
  
  const HolographicGlobe({
    super.key,
    this.size = 200,
    this.showConnections = true,
    this.showParticles = true,
  });

  @override
  State<HolographicGlobe> createState() => _HolographicGlobeState();
}

class _HolographicGlobeState extends State<HolographicGlobe>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: AppTheme.globeRotation,
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: AppTheme.energyPulse,
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: AppTheme.particleDrift,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbital particles
          if (widget.showParticles)
            ...List.generate(8, (index) => 
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  final angle = (index * math.pi / 4) + (_particleController.value * 2 * math.pi);
                  final radius = widget.size * 0.6;
                  return Positioned(
                    left: widget.size / 2 + math.cos(angle) * radius - 2,
                    top: widget.size / 2 + math.sin(angle) * radius - 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyberCyan.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyberCyan.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Main globe
          AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _pulseController]),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: GlobePainter(
                    pulseValue: _pulseController.value,
                    showConnections: widget.showConnections,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  final double pulseValue;
  final bool showConnections;

  GlobePainter({required this.pulseValue, required this.showConnections});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Globe wireframe
    final globePaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity((0.6 + pulseValue * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw latitude lines
    for (int i = 1; i < 6; i++) {
      final y = center.dy - radius + (i * radius * 2 / 6);
      final ellipseRadius = math.sqrt(radius * radius - (y - center.dy) * (y - center.dy));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: ellipseRadius * 2, height: 20),
        globePaint,
      );
    }

    // Draw longitude lines
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final startAngle = i * math.pi / 4;
      for (double t = 0; t <= math.pi; t += 0.1) {
        final x = center.dx + radius * math.sin(t) * math.cos(startAngle);
        final y = center.dy - radius * math.cos(t);
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, globePaint);
    }

    // City pulse points
    final cityPaint = Paint()
      ..color = AppTheme.neonPink.withOpacity((0.8 + pulseValue * 0.2).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final cities = [
      Offset(center.dx + 30, center.dy - 20),
      Offset(center.dx - 40, center.dy + 10),
      Offset(center.dx + 20, center.dy + 30),
      Offset(center.dx - 20, center.dy - 30),
    ];

    for (final city in cities) {
      canvas.drawCircle(city, 3 + pulseValue * 2, cityPaint);
    }

    // Connection lines
    if (showConnections) {
      final connectionPaint = Paint()
        ..color = AppTheme.electricBlue.withOpacity((0.3 + pulseValue * 0.7).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      for (int i = 0; i < cities.length; i++) {
        for (int j = i + 1; j < cities.length; j++) {
          canvas.drawLine(cities[i], cities[j], connectionPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Security Shield Widget
class SecurityShield extends StatefulWidget {
  final double size;
  final bool showCheckmark;
  
  const SecurityShield({
    super.key,
    this.size = 100,
    this.showCheckmark = true,
  });

  @override
  State<SecurityShield> createState() => _SecurityShieldState();
}

class _SecurityShieldState extends State<SecurityShield>
    with TickerProviderStateMixin {
  late AnimationController _energyController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _energyController = AnimationController(
      duration: AppTheme.energyPulse,
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _energyController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating particles
          ...List.generate(6, (index) => 
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                final angle = (index * math.pi / 3) + (_particleController.value * 2 * math.pi);
                final radius = widget.size * 0.7;
                return Positioned(
                  left: widget.size / 2 + math.cos(angle) * radius - 1.5,
                  top: widget.size / 2 + math.sin(angle) * radius - 1.5,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cyberCyan.withOpacity(0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Shield
          AnimatedBuilder(
            animation: _energyController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ShieldPainter(
                  energyValue: _energyController.value,
                  showCheckmark: widget.showCheckmark,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ShieldPainter extends CustomPainter {
  final double energyValue;
  final bool showCheckmark;

  ShieldPainter({required this.energyValue, required this.showCheckmark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shieldSize = size.width * 0.6;

    // Hexagonal shield path
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + shieldSize / 2 * math.cos(angle);
      final y = center.dy + shieldSize / 2 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Shield gradient fill
    final shieldPaint = Paint()
      ..shader = AppTheme.shieldGradient.createShader(
        Rect.fromCenter(center: center, width: shieldSize, height: shieldSize),
      )
      ..color = AppTheme.electricBlue.withOpacity(0.3);
    canvas.drawPath(path, shieldPaint);

    // Shield border with energy effect
    final borderPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity((0.6 + energyValue * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Energy rings
    for (int i = 1; i <= 3; i++) {
      final ringPaint = Paint()
        ..color = AppTheme.cyberCyan.withOpacity(((0.3 - i * 0.1) * energyValue).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, shieldSize / 2 + i * 10 * energyValue, ringPaint);
    }

    // Checkmark
    if (showCheckmark) {
      final checkPaint = Paint()
        ..color = AppTheme.neuralGreen.withOpacity((0.8 + energyValue * 0.2).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final checkPath = Path();
      checkPath.moveTo(center.dx - 10, center.dy);
      checkPath.lineTo(center.dx - 3, center.dy + 7);
      checkPath.lineTo(center.dx + 10, center.dy - 7);
      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Fingerprint Scanner Widget
class FingerprintScanner extends StatefulWidget {
  final double size;
  
  const FingerprintScanner({
    super.key,
    this.size = 120,
  });

  @override
  State<FingerprintScanner> createState() => _FingerprintScannerState();
}

class _FingerprintScannerState extends State<FingerprintScanner>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scanController, _ringController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: FingerprintPainter(
              scanValue: _scanController.value,
              ringValue: _ringController.value,
            ),
          );
        },
      ),
    );
  }
}

class FingerprintPainter extends CustomPainter {
  final double scanValue;
  final double ringValue;

  FingerprintPainter({required this.scanValue, required this.ringValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Concentric rings
    for (int i = 1; i <= 4; i++) {
      final ringPaint = Paint()
        ..color = AppTheme.cyberCyan.withOpacity((0.3 + ringValue * 0.4 / i).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }

    // Fingerprint pattern
    final fingerprintPaint = Paint()
      ..color = AppTheme.glowWhite.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw fingerprint ridges
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final ridgeRadius = radius * (0.3 + i * 0.08);
      for (double angle = 0; angle < 2 * math.pi; angle += 0.1) {
        final x = center.dx + ridgeRadius * math.cos(angle + i * 0.2);
        final y = center.dy + ridgeRadius * math.sin(angle + i * 0.2);
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, fingerprintPaint);
    }

    // Scanning line
    final scanPaint = Paint()
      ..color = AppTheme.neonPink.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scanY = center.dy - radius + (scanValue * radius * 2);
    canvas.drawLine(
      Offset(center.dx - radius, scanY),
      Offset(center.dx + radius, scanY),
      scanPaint,
    );

    // HUD elements
    final hudPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Corner brackets
    final bracketSize = 15.0;
    final corners = [
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius),
    ];

    for (final corner in corners) {
      // Draw L-shaped brackets at corners
      canvas.drawLine(corner, Offset(corner.dx + (corner.dx < center.dx ? bracketSize : -bracketSize), corner.dy), hudPaint);
      canvas.drawLine(corner, Offset(corner.dx, corner.dy + (corner.dy < center.dy ? bracketSize : -bracketSize)), hudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Neural Network Visualization Widget
class NeuralNetworkViz extends StatefulWidget {
  final double width;
  final double height;
  
  const NeuralNetworkViz({
    super.key,
    this.width = 300,
    this.height = 200,
  });

  @override
  State<NeuralNetworkViz> createState() => _NeuralNetworkVizState();
}

class _NeuralNetworkVizState extends State<NeuralNetworkViz>
    with TickerProviderStateMixin {
  late AnimationController _dataFlowController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _dataFlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: AppTheme.energyPulse,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dataFlowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_dataFlowController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: NeuralNetworkPainter(
              dataFlowValue: _dataFlowController.value,
              pulseValue: _pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final double dataFlowValue;
  final double pulseValue;

  NeuralNetworkPainter({required this.dataFlowValue, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Define node positions
    final nodes = <Offset>[
      // Input layer
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.8),
      // Hidden layer
      Offset(size.width * 0.4, size.height * 0.15),
      Offset(size.width * 0.4, size.height * 0.35),
      Offset(size.width * 0.4, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.85),
      // Output layer
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.7),
    ];

    // Draw connections
    final connectionPaint = Paint()
      ..color = AppTheme.electricBlue.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Input to hidden connections
    for (int i = 0; i < 3; i++) {
      for (int j = 3; j < 7; j++) {
        canvas.drawLine(nodes[i], nodes[j], connectionPaint);
        
        // Data flow particles
        final progress = (dataFlowValue + i * 0.1 + j * 0.05) % 1.0;
        final particlePos = Offset.lerp(nodes[i], nodes[j], progress)!;
        canvas.drawCircle(
          particlePos,
          2,
          Paint()..color = AppTheme.neonPink.withOpacity(0.8),
        );
      }
    }

    // Hidden to output connections
    for (int i = 3; i < 7; i++) {
      for (int j = 7; j < 9; j++) {
        canvas.drawLine(nodes[i], nodes[j], connectionPaint);
        
        // Data flow particles
        final progress = (dataFlowValue + i * 0.1 + j * 0.05) % 1.0;
        final particlePos = Offset.lerp(nodes[i], nodes[j], progress)!;
        canvas.drawCircle(
          particlePos,
          2,
          Paint()..color = AppTheme.neonPink.withOpacity(0.8),
        );
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodePaint = Paint()
        ..color = AppTheme.cyberCyan.withOpacity((0.6 + pulseValue * 0.4).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(nodes[i], 6 + pulseValue * 2, nodePaint);
      
      // Node glow
      canvas.drawCircle(
        nodes[i],
        10 + pulseValue * 4,
        Paint()
          ..color = AppTheme.cyberCyan.withOpacity((0.2 * pulseValue).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Abstract Energy Flows Widget
class EnergyFlows extends StatefulWidget {
  final double width;
  final double height;
  
  const EnergyFlows({
    super.key,
    this.width = 300,
    this.height = 150,
  });

  @override
  State<EnergyFlows> createState() => _EnergyFlowsState();
}

class _EnergyFlowsState extends State<EnergyFlows>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flowController, _particleController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: EnergyFlowPainter(
              flowValue: _flowController.value,
              particleValue: _particleController.value,
            ),
          );
        },
      ),
    );
  }
}

class EnergyFlowPainter extends CustomPainter {
  final double flowValue;
  final double particleValue;

  EnergyFlowPainter({required this.flowValue, required this.particleValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Energy ribbon paths
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw flowing ribbons
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = size.height * (0.2 + i * 0.3);
      
      for (double x = 0; x <= size.width; x += 5) {
        final wave = math.sin((x / size.width * 4 * math.pi) + (flowValue * 2 * math.pi) + (i * math.pi / 3)) * 20;
        final y = yOffset + wave;
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      // Gradient colors for ribbons
      final colors = [AppTheme.cyberCyan, AppTheme.privacyPurple, AppTheme.neonPink];
      ribbonPaint.color = colors[i].withOpacity(0.8);
      canvas.drawPath(path, ribbonPaint);
      
      // Particle explosions at intersections
      if (i < 2) {
        final intersectionX = size.width * (0.3 + i * 0.4);
        final intersectionY = size.height * 0.5;
        
        // Explosion particles
        for (int j = 0; j < 8; j++) {
          final angle = j * math.pi / 4 + particleValue * 2 * math.pi;
          final distance = 20 * particleValue;
          final particleX = intersectionX + math.cos(angle) * distance;
          final particleY = intersectionY + math.sin(angle) * distance;
          
          canvas.drawCircle(
            Offset(particleX, particleY),
            3 * (1 - particleValue),
            Paint()..color = AppTheme.particleGold.withOpacity((1 - particleValue).clamp(0.0, 1.0)),
          );
        }
      }
    }

    // Bokeh background effects
    for (int i = 0; i < 15; i++) {
      final x = (i * 37.0 + flowValue * 100) % size.width;
      final y = (i * 23.0 + math.sin(flowValue * 2 * math.pi + i) * 50) % size.height;
      final colors = [AppTheme.plasmaOrange, AppTheme.cyberCyan, AppTheme.electricBlue];
      
      canvas.drawCircle(
        Offset(x, y),
        5 + math.sin(particleValue * 2 * math.pi + i) * 3,
        Paint()
          ..color = colors[i % 3].withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Donut Chart for Analytics
class DonutChart extends StatefulWidget {
  final double size;
  final List<ChartData> data;
  final String centerText;
  
  const DonutChart({
    super.key,
    this.size = 280,
    this.data = const [],
    this.centerText = '69%',
  });
  
  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: DonutChartPainter(
              data: widget.data,
              centerText: widget.centerText,
              progress: _animation.value,
            ),
          );
        },
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  final String centerText;
  final double progress;
  
  DonutChartPainter({
    required this.data,
    required this.centerText,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final strokeWidth = 30.0;
    
    double startAngle = -math.pi / 2;
    
    final total = data.fold(0.0, (sum, item) => sum + item.value);
    
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi * progress;
      
      final paint = Paint()
        ..color = data[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      // Glow effect
      final glowPaint = Paint()
        ..color = data[i].color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF1A1F3A)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius - strokeWidth / 2, centerPaint);
    
    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Area Line Chart
class AreaLineChart extends StatefulWidget {
  final double width;
  final double height;
  final List<ChartPoint> data;
  final Color color;
  
  const AreaLineChart({
    super.key,
    this.width = 320,
    this.height = 180,
    this.data = const [],
    this.color = AppTheme.cyberCyan,
  });
  
  @override
  State<AreaLineChart> createState() => _AreaLineChartState();
}

class _AreaLineChartState extends State<AreaLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: AreaLineChartPainter(
              data: widget.data,
              color: widget.color,
              progress: _animation.value,
            ),
          );
        },
      ),
    );
  }
}

class AreaLineChartPainter extends CustomPainter {
  final List<ChartPoint> data;
  final Color color;
  final double progress;
  
  AreaLineChartPainter({
    required this.data,
    required this.color,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }
    
    // Calculate points
    final points = <Offset>[];
    if (data.isNotEmpty) {
      final maxX = data.map((p) => p.x).reduce((a, b) => a > b ? a : b);
      final maxY = data.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      
      for (final point in data) {
        final x = padding + (chartWidth * point.x / maxX);
        final y = padding + chartHeight * (1 - point.y / maxY);
        points.add(Offset(x, y));
      }
    }
    
    // Area path
    final areaPath = Path();
    areaPath.moveTo(points.first.dx, size.height - padding);
    
    for (int i = 0; i < points.length * progress; i++) {
      if (i < points.length) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }
    }
    
    if (points.length * progress > 0) {
      areaPath.lineTo(points[(points.length * progress).floor().clamp(0, points.length - 1)].dx, size.height - padding);
    }
    areaPath.close();
    
    // Area gradient
    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.6),
        color.withOpacity(0.0),
      ],
    );
    
    final areaPaint = Paint()
      ..shader = areaGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(areaPath, areaPaint);
    
    // Line path
    final linePath = Path();
    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length * progress; i++) {
        if (i < points.length) {
          linePath.lineTo(points[i].dx, points[i].dy);
        }
      }
    }
    
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(linePath, linePaint);
    
    // Glowing dots
    for (int i = 0; i < points.length * progress; i++) {
      if (i < points.length) {
        // Glow
        canvas.drawCircle(
          points[i],
          12,
          Paint()
            ..color = color.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        
        // Dot
        canvas.drawCircle(
          points[i],
          4,
          Paint()..color = color,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Hexagonal 3D Structure
class HexagonalStructure extends StatefulWidget {
  final double size;
  
  const HexagonalStructure({
    super.key,
    this.size = 280,
  });
  
  @override
  State<HexagonalStructure> createState() => _HexagonalStructureState();
}

class _HexagonalStructureState extends State<HexagonalStructure>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _particleController]),
        builder: (context, child) {
          return CustomPaint(
            painter: HexagonalStructurePainter(
              rotation: _rotationController.value,
              particlePhase: _particleController.value,
            ),
          );
        },
      ),
    );
  }
}

class HexagonalStructurePainter extends CustomPainter {
  final double rotation;
  final double particlePhase;
  
  HexagonalStructurePainter({
    required this.rotation,
    required this.particlePhase,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Floating particles
    for (int i = 0; i < 20; i++) {
      final angle = (i * 2 * math.pi / 20) + (particlePhase * 2 * math.pi);
      final radius = size.width * (0.4 + 0.2 * math.sin(particlePhase * 2 * math.pi + i));
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        2 + math.sin(particlePhase * 4 * math.pi + i) * 1,
        Paint()..color = AppTheme.cyberCyan.withOpacity(0.6),
      );
    }
    
    // Layered hexagons
    final colors = [
      AppTheme.neonPink,
      AppTheme.privacyPurple,
      AppTheme.electricBlue,
      AppTheme.cyberCyan,
    ];
    
    for (int layer = 0; layer < 5; layer++) {
      final hexSize = size.width * (0.15 + layer * 0.08);
      final layerRotation = rotation * 2 * math.pi + (layer * math.pi / 6);
      final yOffset = layer * 8.0;
      
      final hexPath = Path();
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 + layerRotation;
        final x = center.dx + hexSize * math.cos(angle);
        final y = center.dy + hexSize * math.sin(angle) + yOffset;
        
        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();
      
      // Gradient fill
      final gradient = LinearGradient(
        colors: [
          colors[layer % colors.length].withOpacity(0.3),
          colors[layer % colors.length].withOpacity(0.1),
        ],
      );
      
      final fillPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCenter(center: center, width: hexSize * 2, height: hexSize * 2),
        );
      
      canvas.drawPath(hexPath, fillPaint);
      
      // Glowing edges
      final edgePaint = Paint()
        ..color = colors[layer % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawPath(hexPath, edgePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Holographic Interface for Settings
class HolographicInterface extends StatefulWidget {
  final double size;
  
  const HolographicInterface({
    super.key,
    this.size = 300,
  });
  
  @override
  State<HolographicInterface> createState() => _HolographicInterfaceState();
}

class _HolographicInterfaceState extends State<HolographicInterface>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _scanController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _ringController.dispose();
    _scanController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ringController, _scanController, _particleController]),
        builder: (context, child) {
          return CustomPaint(
            painter: HolographicInterfacePainter(
              ringRotation: _ringController.value,
              scanProgress: _scanController.value,
              particlePhase: _particleController.value,
            ),
          );
        },
      ),
    );
  }
}

class HolographicInterfacePainter extends CustomPainter {
  final double ringRotation;
  final double scanProgress;
  final double particlePhase;
  
  HolographicInterfacePainter({
    required this.ringRotation,
    required this.scanProgress,
    required this.particlePhase,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Floating particles
    for (int i = 0; i < 30; i++) {
      final angle = (i * 2 * math.pi / 30) + (particlePhase * 2 * math.pi);
      final radius = size.width * (0.3 + 0.4 * (i % 3) / 3);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      canvas.drawCircle(
        Offset(x, y),
        1 + (i % 3),
        Paint()..color = AppTheme.cyberCyan.withOpacity(0.4),
      );
    }
    
    // Concentric rings
    final ringColors = [AppTheme.electricBlue, AppTheme.cyberCyan, AppTheme.privacyPurple];
    
    for (int i = 0; i < 5; i++) {
      final radius = size.width * (0.15 + i * 0.08);
      final rotation = ringRotation * 2 * math.pi * (i % 2 == 0 ? 1 : -1);
      
      final ringPaint = Paint()
        ..color = ringColors[i % ringColors.length].withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Draw segmented ring
      for (int j = 0; j < 12; j++) {
        final startAngle = j * math.pi / 6 + rotation;
        final sweepAngle = math.pi / 8;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          ringPaint,
        );
      }
    }
    
    // Central lock/shield icon
    final iconSize = size.width * 0.12;
    final iconPath = Path();
    
    // Shield shape
    iconPath.moveTo(center.dx, center.dy - iconSize);
    iconPath.lineTo(center.dx + iconSize * 0.6, center.dy - iconSize * 0.3);
    iconPath.lineTo(center.dx + iconSize * 0.6, center.dy + iconSize * 0.3);
    iconPath.lineTo(center.dx, center.dy + iconSize);
    iconPath.lineTo(center.dx - iconSize * 0.6, center.dy + iconSize * 0.3);
    iconPath.lineTo(center.dx - iconSize * 0.6, center.dy - iconSize * 0.3);
    iconPath.close();
    
    final iconPaint = Paint()
      ..color = AppTheme.glowWhite.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(iconPath, iconPaint);
    
    // Glow around icon
    canvas.drawPath(
      iconPath,
      Paint()
        ..color = AppTheme.cyberCyan.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Scanning lines
    final scanAngle = scanProgress * 2 * math.pi;
    final scanPaint = Paint()
      ..color = AppTheme.neonPink.withOpacity(0.8)
      ..strokeWidth = 2;
    
    for (int i = 0; i < 3; i++) {
      final angle = scanAngle + (i * math.pi / 3);
      final startRadius = size.width * 0.2;
      final endRadius = size.width * 0.45;
      
      canvas.drawLine(
        Offset(
          center.dx + startRadius * math.cos(angle),
          center.dy + startRadius * math.sin(angle),
        ),
        Offset(
          center.dx + endRadius * math.cos(angle),
          center.dy + endRadius * math.sin(angle),
        ),
        scanPaint,
      );
    }
    
    // HUD corner elements
    final hudPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.6)
      ..strokeWidth = 2;
    
    final cornerSize = 20.0;
    final corners = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.9),
    ];
    
    for (final corner in corners) {
      // L-shaped brackets
      canvas.drawLine(
        corner,
        Offset(corner.dx + (corner.dx < center.dx ? cornerSize : -cornerSize), corner.dy),
        hudPaint,
      );
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + (corner.dy < center.dy ? cornerSize : -cornerSize)),
        hudPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}