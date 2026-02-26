import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class PrivacyProtocolScreen extends StatefulWidget {
  final String? nodeId;
  
  const PrivacyProtocolScreen({super.key, this.nodeId});

  @override
  State<PrivacyProtocolScreen> createState() => _PrivacyProtocolScreenState();
}

class _PrivacyProtocolScreenState extends State<PrivacyProtocolScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  double _epsilonValue = 0.5;
  bool _hasAccepted = false;
  bool _hasReadTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/onboarding/identity'),
                      ),
                      const Spacer(),
                      Text(
                        'Step 2 of 5',
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
                    'Compliance & Privacy Protocol',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Accept Differential Privacy budget',
                    style: TextStyle(
                      color: AppTheme.cyberCyan.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Epsilon Value Display
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.cyberCyan.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppTheme.cyberCyan,
                            size: 64,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Differential Privacy Budget',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ε = ${_epsilonValue.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppTheme.cyberCyan,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Privacy Level: ${_getPrivacyLevel(_epsilonValue)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Epsilon Slider
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Adjust Privacy Level',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Higher = More Privacy',
                              style: TextStyle(
                                color: AppTheme.cyberCyan.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: _epsilonValue,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          activeColor: AppTheme.cyberCyan,
                          inactiveColor: Colors.white.withOpacity(0.2),
                          onChanged: (value) {
                            setState(() {
                              _epsilonValue = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.1 (Strict)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '2.0 (Balanced)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Terms and Conditions
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _hasReadTerms,
                                activeColor: AppTheme.cyberCyan,
                                onChanged: (value) {
                                  setState(() {
                                    _hasReadTerms = value ?? false;
                                    if (_hasReadTerms) {
                                      _hasAccepted = true;
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _hasReadTerms = !_hasReadTerms;
                                      if (_hasReadTerms) {
                                        _hasAccepted = true;
                                      }
                                    });
                                  },
                                  child: Text(
                                    'I understand that Differential Privacy (ε = ${_epsilonValue.toStringAsFixed(1)}) will protect my data during federated learning',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Mathematical noise will be added to protect sensitive information\n'
                            '• Your data never leaves your device\n'
                            '• Only aggregated model updates are shared',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Continue Button
                  if (_hasAccepted)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF64FFDA), Color(0xFF48CAE4)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Pass epsilon value to next screen
                            context.go('/onboarding/scan?nodeId=${widget.nodeId}&epsilon=$_epsilonValue');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept & Continue',
                            style: TextStyle(
                              color: Color(0xFF0A192F),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  String _getPrivacyLevel(double epsilon) {
    if (epsilon < 0.5) return 'Very High';
    if (epsilon < 1.0) return 'High';
    if (epsilon < 1.5) return 'Medium';
    return 'Balanced';
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

