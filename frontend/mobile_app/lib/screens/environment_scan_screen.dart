import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class EnvironmentScanScreen extends StatefulWidget {
  final String? nodeId;
  final String? epsilon;
  
  const EnvironmentScanScreen({super.key, this.nodeId, this.epsilon});

  @override
  State<EnvironmentScanScreen> createState() => _EnvironmentScanScreenState();
}

class _EnvironmentScanScreenState extends State<EnvironmentScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanProgress;
  
  bool _isScanning = true;
  bool _scanComplete = false;
  Map<String, bool> _scanResults = {};
  String _gpuStatus = 'Checking...';
  String _cpuStatus = 'Checking...';
  String _memoryStatus = 'Checking...';
  String _securityStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scanProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _startScan();
  }

  Future<void> _startScan() async {
    _scanController.forward();
    
    // Simulate scanning process
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _gpuStatus = 'Detected';
        _scanResults['gpu'] = true;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _cpuStatus = 'Compatible';
        _scanResults['cpu'] = true;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _memoryStatus = 'Sufficient';
        _scanResults['memory'] = true;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _securityStatus = 'Secure';
        _scanResults['security'] = true;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanComplete = true;
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
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
                        onPressed: () => context.go('/onboarding/privacy?nodeId=${widget.nodeId}'),
                      ),
                      const Spacer(),
                      Text(
                        'Step 3 of 5',
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
                    'Environment Sentinel Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Verifying hardware capabilities',
                    style: TextStyle(
                      color: AppTheme.cyberCyan.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Scan Progress
                  if (_isScanning)
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _scanProgress,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _scanProgress.value,
                              strokeWidth: 6,
                              color: AppTheme.cyberCyan,
                              backgroundColor: Colors.white.withOpacity(0.1),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Scanning hardware...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  
                  // Scan Results
                  if (_scanComplete)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScanItem(
                              icon: Icons.memory,
                              label: 'GPU Runtime',
                              status: _gpuStatus,
                              isPass: _scanResults['gpu'] ?? false,
                            ),
                            const SizedBox(height: 16),
                            _buildScanItem(
                              icon: Icons.speed,
                              label: 'CPU Performance',
                              status: _cpuStatus,
                              isPass: _scanResults['cpu'] ?? false,
                            ),
                            const SizedBox(height: 16),
                            _buildScanItem(
                              icon: Icons.storage,
                              label: 'Memory',
                              status: _memoryStatus,
                              isPass: _scanResults['memory'] ?? false,
                            ),
                            const SizedBox(height: 16),
                            _buildScanItem(
                              icon: Icons.security,
                              label: 'Security',
                              status: _securityStatus,
                              isPass: _scanResults['security'] ?? false,
                            ),
                            const SizedBox(height: 32),
                            
                            // Diagnostic Report
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.cyberCyan,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Diagnostic Report',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'All systems operational. Your device is ready for federated learning.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Continue Button
                  if (_scanComplete && _scanResults.values.every((v) => v))
                    Container(
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
                          context.go('/onboarding/data-link?nodeId=${widget.nodeId}&epsilon=${widget.epsilon}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Color(0xFF0A192F),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_scanComplete && !_scanResults.values.every((v) => v))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'Hardware requirements not met. Please use a compatible device.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildScanItem({
    required IconData icon,
    required String label,
    required String status,
    required bool isPass,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPass 
              ? AppTheme.cyberCyan.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isPass ? AppTheme.cyberCyan : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: isPass 
                        ? AppTheme.cyberCyan.withOpacity(0.8)
                        : Colors.red.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPass ? Icons.check_circle : Icons.error,
            color: isPass ? AppTheme.cyberCyan : Colors.red,
            size: 24,
          ),
        ],
      ),
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

