import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool enableParticles;
  final bool enableGradients;
  final double intensity;
  
  const AnimatedBackground({
    super.key,
    required this.child,
    this.enableParticles = true,
    this.enableGradients = true,
    this.intensity = 1.0,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _initializeParticles();
  }

  void _initializeParticles() {
    _particles = List.generate(
      (AppTheme.maxParticles * widget.intensity).round(),
      (index) => Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: 2 + math.Random().nextDouble() * 6,
        speed: 0.1 + math.Random().nextDouble() * 0.3,
        opacity: 0.2 + math.Random().nextDouble() * 0.6,
        color: _getRandomParticleColor(),
        angle: math.Random().nextDouble() * 2 * math.pi,
      ),
    );
  }

  Color _getRandomParticleColor() {
    final colors = [
      AppTheme.glowWhite,
      AppTheme.cyberCyan,
      AppTheme.plasmaOrange,
      AppTheme.neonPink,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient layers
        if (widget.enableGradients)
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_gradientController.value * 2 * math.pi) * 0.3,
                      math.cos(_gradientController.value * 2 * math.pi) * 0.3,
                    ),
                    colors: [
                      AppTheme.deepNavy.withOpacity(0.8),
                      AppTheme.spaceBlack.withOpacity(0.9),
                      AppTheme.spaceBlack,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
        
        // Particle system
        if (widget.enableParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: ParticleSystemPainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                  intensity: widget.intensity,
                ),
              );
            },
          ),
        
        // Depth blur layers
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppTheme.deepNavy.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Main content
        widget.child,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;
  double angle;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.angle,
  });

  void update(double deltaTime) {
    // Brownian motion with drift
    x += math.cos(angle) * speed * deltaTime;
    y += math.sin(angle) * speed * deltaTime;
    
    // Add subtle random movement
    angle += (math.Random().nextDouble() - 0.5) * 0.1;
    
    // Wrap around screen
    if (x > 1.0) x = 0.0;
    if (x < 0.0) x = 1.0;
    if (y > 1.0) y = 0.0;
    if (y < 0.0) y = 1.0;
  }
}

class ParticleSystemPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final double intensity;

  ParticleSystemPainter({
    required this.particles,
    required this.animationValue,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw particles
    for (final particle in particles) {
      particle.update(0.016); // ~60fps
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      // Particle with glow effect
      final glowPaint = Paint()
        ..color = particle.color.withOpacity((particle.opacity * 0.3 * intensity).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      final particlePaint = Paint()
        ..color = particle.color.withOpacity((particle.opacity * intensity).clamp(0.0, 1.0));
      
      // Draw glow
      canvas.drawCircle(Offset(x, y), particle.size * 2, glowPaint);
      
      // Draw particle
      canvas.drawCircle(Offset(x, y), particle.size, particlePaint);
    }
    
    // Draw connection lines between nearby particles
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        
        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance < 100) {
          final connectionPaint = Paint()
            ..color = AppTheme.cyberCyan.withOpacity(
              ((1 - distance / 100) * 0.2 * intensity).clamp(0.0, 1.0),
            )
            ..strokeWidth = 0.5;
          
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            connectionPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Glassmorphism Container Widget
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: borderColor ?? AppTheme.cyberCyan.withOpacity(0.3),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity * 1.2),
                  Colors.white.withOpacity(opacity * 0.8),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Holographic Button Widget
class HolographicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const HolographicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<HolographicButton> createState() => _HolographicButtonState();
}

class _HolographicButtonState extends State<HolographicButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AppTheme.microAnimation,
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.cyberCyan;
    
    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _pressController,
            _shimmerController,
          ]),
          builder: (context, child) {
            final scale = 1.0 - (_pressController.value * 0.05);
            final glowIntensity = 0.3 + (_hoverController.value * 0.7);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: color.withOpacity(glowIntensity.clamp(0.0, 1.0)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity((glowIntensity * 0.5).clamp(0.0, 1.0)),
                      blurRadius: 15 + (_hoverController.value * 10),
                      spreadRadius: 2 + (_hoverController.value * 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shimmer effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: CustomPaint(
                          painter: ShimmerPainter(
                            progress: _shimmerController.value,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    // Button content
                    widget.child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shimmerRect = Rect.fromLTWH(
      -size.width + (progress * size.width * 2),
      0,
      size.width,
      size.height,
    );

    canvas.drawRect(shimmerRect, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Loading Animation Widget
class FuturisticLoader extends StatefulWidget {
  final double size;
  final Color? color;
  
  const FuturisticLoader({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<FuturisticLoader> createState() => _FuturisticLoaderState();
}

class _FuturisticLoaderState extends State<FuturisticLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.cyberCyan;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: LoaderPainter(
              rotationValue: _rotationController.value,
              pulseValue: _pulseController.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class LoaderPainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;
  final Color color;

  LoaderPainter({
    required this.rotationValue,
    required this.pulseValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    // Rotating outer ring
    final outerPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final outerPath = Path();
    for (double i = 0; i < 0.75; i += 0.01) {
      final angle = (i + rotationValue) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        outerPath.moveTo(x, y);
      } else {
        outerPath.lineTo(x, y);
      }
    }
    canvas.drawPath(outerPath, outerPaint);

    // Pulsing inner circle
    final innerPaint = Paint()
      ..color = color.withOpacity((0.6 + pulseValue * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.3 + pulseValue * 5, innerPaint);

    // Particle burst
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + rotationValue * 2 * math.pi;
      final distance = radius * 0.6 + pulseValue * 10;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      canvas.drawCircle(
        Offset(x, y),
        2 + pulseValue * 2,
        Paint()..color = color.withOpacity((0.8 - pulseValue * 0.3).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}