import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Particle Trail Effect - Swirling glowing particles like in the reference images
class ParticleTrailEffect extends StatefulWidget {
  final int particleCount;
  final double speed;
  final Color particleColor;
  
  const ParticleTrailEffect({
    super.key,
    this.particleCount = 30,
    this.speed = 1.0,
    this.particleColor = AppTheme.cyberCyan,
  });

  @override
  State<ParticleTrailEffect> createState() => _ParticleTrailEffectState();
}

class _ParticleTrailEffectState extends State<ParticleTrailEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Initialize particles with random positions
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: 2 + math.Random().nextDouble() * 4,
        speed: 0.3 + math.Random().nextDouble() * widget.speed,
        angle: math.Random().nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticleTrailPainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.particleColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

class ParticleTrailPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticleTrailPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    for (var particle in particles) {
      // Update particle position in a wave pattern
      final offset = progress * particle.speed;
      final newX = (particle.x + math.sin(offset + particle.angle) * 0.3) * size.width;
      final newY = (particle.y + math.cos(offset + particle.angle) * 0.2) * size.height;
      
      // Draw particle with glow
      paint.color = color.withOpacity(0.8);
      canvas.drawCircle(Offset(newX, newY), particle.size, paint);
      
      // Draw glow effect
      paint.color = color.withOpacity(0.3);
      canvas.drawCircle(Offset(newX, newY), particle.size * 3, paint);
      
      // Draw trail
      if (particles.indexOf(particle) > 0) {
        final prevParticle = particles[particles.indexOf(particle) - 1];
        final prevX = (prevParticle.x + math.sin(offset - 0.1 + prevParticle.angle) * 0.3) * size.width;
        final prevY = (prevParticle.y + math.cos(offset - 0.1 + prevParticle.angle) * 0.2) * size.height;
        
        paint.style = PaintingStyle.stroke;
        paint.color = color.withOpacity(0.4);
        paint.strokeWidth = 1;
        canvas.drawLine(Offset(prevX, prevY), Offset(newX, newY), paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticleTrailPainter oldDelegate) => true;
}

/// Wireframe Element - Glowing wireframe like the padlock in reference images
class WireframeElement extends StatelessWidget {
  final Widget child;
  final Color wireframeColor;
  final double glowIntensity;
  
  const WireframeElement({
    super.key,
    required this.child,
    this.wireframeColor = AppTheme.wireframeBlue,
    this.glowIntensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Glow background
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: wireframeColor.withOpacity(0.4 * glowIntensity),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: child,
        ),
        // Wireframe overlay
        CustomPaint(
          painter: WireframePainter(
            color: wireframeColor,
            glowIntensity: glowIntensity,
          ),
          child: child,
        ),
      ],
    );
  }
}

class WireframePainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  WireframePainter({
    required this.color,
    this.glowIntensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;

    // Draw grid pattern
    final gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      paint.color = color.withOpacity(0.3 * glowIntensity);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      paint.color = color.withOpacity(0.3 * glowIntensity);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw border with glow
    paint.color = color.withOpacity(0.8 * glowIntensity);
    paint.strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant WireframePainter oldDelegate) => false;
}

/// Network Visualization - Glowing lines connecting nodes
class NetworkVisualization extends StatefulWidget {
  final int nodeCount;
  final double connectionDensity;
  
  const NetworkVisualization({
    super.key,
    this.nodeCount = 8,
    this.connectionDensity = 0.3,
  });

  @override
  State<NetworkVisualization> createState() => _NetworkVisualizationState();
}

class _NetworkVisualizationState extends State<NetworkVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<NetworkNode> _nodes = [];
  final List<NetworkConnection> _connections = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Initialize nodes
    final random = math.Random();
    for (int i = 0; i < widget.nodeCount; i++) {
      _nodes.add(NetworkNode(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 8 + random.nextDouble() * 8,
      ));
    }
    
    // Create connections
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        if (random.nextDouble() < widget.connectionDensity) {
          _connections.add(NetworkConnection(
            from: i,
            to: j,
            intensity: random.nextDouble(),
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkPainter(
            nodes: _nodes,
            connections: _connections,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class NetworkNode {
  double x;
  double y;
  double size;
  
  NetworkNode({
    required this.x,
    required this.y,
    required this.size,
  });
}

class NetworkConnection {
  int from;
  int to;
  double intensity;
  
  NetworkConnection({
    required this.from,
    required this.to,
    required this.intensity,
  });
}

class NetworkPainter extends CustomPainter {
  final List<NetworkNode> nodes;
  final List<NetworkConnection> connections;
  final double progress;

  NetworkPainter({
    required this.nodes,
    required this.connections,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connections first (behind nodes)
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var connection in connections) {
      final fromNode = nodes[connection.from];
      final toNode = nodes[connection.to];
      
      final fromX = fromNode.x * size.width;
      final fromY = fromNode.y * size.height;
      final toX = toNode.x * size.width;
      final toY = toNode.y * size.height;
      
      // Animated pulse along connection
      final pulseOffset = (progress * 2) % 1.0;
      final pulseX = fromX + (toX - fromX) * pulseOffset;
      final pulseY = fromY + (toY - fromY) * pulseOffset;
      
      // Draw connection line
      connectionPaint.color = AppTheme.cyberCyan.withOpacity(0.3 * connection.intensity);
      canvas.drawLine(Offset(fromX, fromY), Offset(toX, toY), connectionPaint);
      
      // Draw pulsing point
      connectionPaint.color = AppTheme.cyberCyan.withOpacity(0.8);
      canvas.drawCircle(Offset(pulseX, pulseY), 3, connectionPaint);
    }
    
    // Draw nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.fill;
    
    for (var node in nodes) {
      final x = node.x * size.width;
      final y = node.y * size.height;
      
      // Outer glow
      nodePaint.color = AppTheme.cyberCyan.withOpacity(0.4);
      canvas.drawCircle(Offset(x, y), node.size * 2, nodePaint);
      
      // Inner glow
      nodePaint.color = AppTheme.cyberCyan.withOpacity(0.6);
      canvas.drawCircle(Offset(x, y), node.size * 1.5, nodePaint);
      
      // Core
      nodePaint.color = AppTheme.cyberCyan;
      canvas.drawCircle(Offset(x, y), node.size, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant NetworkPainter oldDelegate) => true;
}

/// Glowing Background - Deep navy with subtle blue effects
class GlowingBackground extends StatelessWidget {
  final Widget child;
  final bool showParticles;
  final bool showNetwork;
  
  const GlowingBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showNetwork = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkBackgroundGradient,
      ),
      child: Stack(
        children: [
          if (showParticles)
            Positioned.fill(
              child: ParticleTrailEffect(
                particleCount: 25,
                speed: 0.8,
              ),
            ),
          if (showNetwork)
            Positioned.fill(
              child: NetworkVisualization(
                nodeCount: 6,
                connectionDensity: 0.4,
              ),
            ),
          child,
        ],
      ),
    );
  }
}







