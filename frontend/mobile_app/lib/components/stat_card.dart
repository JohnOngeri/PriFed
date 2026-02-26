import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool showSparkline;
  final bool showIndicators;
  final bool showProgressBar;
  final double? progress;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.showSparkline = false,
    this.showIndicators = false,
    this.showProgressBar = false,
    this.progress,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );
    _glowController = AnimationController(
      duration: AppTheme.energyPulse,
      vsync: this,
    );
    _particleController = AnimationController(
      duration: AppTheme.particleDrift,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppTheme.elasticEase),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: AppTheme.energyEase),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
    
    _animationController.forward();
    _glowController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Semantics(
          label: '${widget.title}: ${widget.value}${widget.subtitle != null ? ', ${widget.subtitle}' : ''}',
          button: widget.onTap != null,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedBuilder(
                animation: Listenable.merge([_scaleAnimation, _glowAnimation, _particleAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isHovered ? 1.05 : _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.1),
                            widget.color.withOpacity(0.05),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: widget.color.withOpacity(_glowAnimation.value * 0.8),
                          width: _isHovered ? 2 : 1,
                        ),
                        boxShadow: _isHovered ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ] : [
                          BoxShadow(
                            color: widget.color.withOpacity(_glowAnimation.value * 0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Particle effects
                          ...List.generate(5, (index) => 
                            Positioned(
                              left: (index * 30.0 + _particleAnimation.value * 100) % 200,
                              top: (index * 20.0 + math.sin(_particleAnimation.value * 2 * math.pi + index) * 10) % 80,
                              child: Container(
                                width: AppTheme.particleSize,
                                height: AppTheme.particleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.color.withOpacity(0.6 * _glowAnimation.value),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.color.withOpacity(0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Main content
                          _buildCardContent(appState),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCardContent(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12 * appState.textScaleFactor,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withOpacity(0.3),
                    widget.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.holographicGradient.createShader(bounds),
          child: Text(
            widget.value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * appState.textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            widget.subtitle!,
            style: TextStyle(
              color: widget.color.withOpacity(0.8),
              fontSize: 10 * appState.textScaleFactor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (widget.showProgressBar && widget.progress != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.2),
                ],
              ),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widget.progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppTheme.energyFlowGradient,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}