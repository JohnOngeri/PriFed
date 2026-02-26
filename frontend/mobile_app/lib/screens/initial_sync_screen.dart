import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class InitialSyncScreen extends StatefulWidget {
  final String? nodeId;
  final String? epsilon;
  
  const InitialSyncScreen({super.key, this.nodeId, this.epsilon});

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _syncController;
  late Animation<double> _pulseAnimation;
  
  bool _isDownloading = true;
  bool _isRunningDebug = false;
  bool _isComplete = false;
  String _currentStep = 'Downloading Global Model...';
  double _downloadProgress = 0.0;
  double _debugProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _syncController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _syncController,
        curve: Curves.easeInOut,
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _syncController.repeat(reverse: true);
          }
        }),
    );
    _startSync();
  }

  Future<void> _startSync() async {
    // Step 1: Download Global Model
    _syncController.forward();
    
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _downloadProgress = i / 100;
          if (i < 100) {
            _currentStep = 'Downloading Global Model... ${i}%';
          }
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isRunningDebug = true;
        _currentStep = 'Running debug round...';
      });
    }
    
    // Step 2: Run Debug Round
    for (int i = 0; i <= 100; i += 15) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _debugProgress = i / 100;
          if (i < 100) {
            _currentStep = 'Running debug round... ${i}%';
          }
        });
      }
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isRunningDebug = false;
        _isComplete = true;
        _currentStep = 'Synchronization complete!';
      });
    }
    
    // Auto-navigate to dashboard after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          // Background particles
          Positioned.fill(
            child: CustomPaint(
              painter: ParticleBackgroundPainter(),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/onboarding/data-link?nodeId=${widget.nodeId}&epsilon=${widget.epsilon}'),
                      ),
                      const Spacer(),
                      Text(
                        'Step 5 of 5',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  const Text(
                    'Initial Synchronization',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Connecting to the federation',
                    style: TextStyle(
                      color: AppTheme.cyberCyan.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(),
                  
                  // Sync Animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.cyberCyan.withOpacity(_pulseAnimation.value * 0.3),
                              AppTheme.cyberCyan.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sync,
                            color: AppTheme.cyberCyan,
                            size: 80,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Progress Indicator
                  if (_isDownloading || _isRunningDebug)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            value: _isDownloading ? _downloadProgress : _debugProgress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.cyberCyan,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentStep,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  
                  // Success Message
                  if (_isComplete)
                    Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.cyberCyan,
                          size: 64,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Synchronization Complete!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your node is now part of the federation',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.cyberCyan.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSyncInfo('Node ID', widget.nodeId ?? 'N/A'),
                              const SizedBox(height: 12),
                              _buildSyncInfo('Privacy Budget', 'ε = ${widget.epsilon ?? "0.5"}'),
                              const SizedBox(height: 12),
                              _buildSyncInfo('Status', 'Connected'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  
                  const Spacer(),
                  
                  if (_isComplete)
                    Text(
                      'Redirecting to dashboard...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.cyberCyan,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ParticleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.1);
    final random = math.Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) => false;
}

