import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DashboardCard extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onTap;
  final String? imagePath;

  const DashboardCard({
    super.key,
    required this.child,
    required this.title,
    this.onTap,
    this.imagePath,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.15),
                      blurRadius: _isHovered ? 30 : 20,
                      offset: Offset(0, _isHovered ? 12 : 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background image or gradient
                      if (widget.imagePath != null)
                        Positioned.fill(
                          child: Image.asset(
                            widget.imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image: ${widget.imagePath}');
                              debugPrint('Error: $error');
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey[900]!,
                                      Colors.grey[800]!,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image not found',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[900]!.withOpacity(0.8),
                                Colors.grey[800]!.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),

                      // Glassmorphism overlay (reduced opacity to show images)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(_isHovered ? 0.08 : 0.05),
                                Colors.white.withOpacity(_isHovered ? 0.05 : 0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(_isHovered ? 0.2 : 0.15),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: widget.child),
                            // Title overlay at bottom
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Text(
                                widget.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

