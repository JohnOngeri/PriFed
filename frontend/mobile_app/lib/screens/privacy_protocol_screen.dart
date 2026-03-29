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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;
  late AnimationController _particleController;
  
  double _epsilonValue = 0.5;
  bool _hasAccepted = false;
  bool _hasReadTerms = false;
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Ensure short content doesn't block the user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && 
          _scrollController.position.maxScrollExtent <= 0) {
        setState(() => _hasReachedBottom = true);
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animationController.forward();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Threshold to detect bottom (100 pixels from end)
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100) {
        if (!_hasReachedBottom) {
          setState(() {
            _hasReachedBottom = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _particleController.dispose();
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
              painter: ParticleBackgroundPainter(
                animation: _particleController,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        // Returns to Step 1
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
                  
                  const SizedBox(height: 16),
                  
                  // Link to Privacy Lab Visualization
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: TextButton.icon(
                        // Educational "Learn More" role: pushed onto the stack
                        onPressed: () => context.push('/privacy-shield'),
                        icon: const Icon(Icons.science_outlined, color: AppTheme.cyberCyan, size: 18),
                        label: Text(
                          'Enter Privacy Lab Visualization',
                          style: TextStyle(
                            color: AppTheme.cyberCyan.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.cyberCyan.withOpacity(0.5),
                          ),
                        ),
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
                                onChanged: _hasReachedBottom ? (value) {
                                  setState(() {
                                    _hasReadTerms = value ?? false;
                                    if (_hasReadTerms) {
                                      _hasAccepted = true;
                                    }
                                  });
                                } : null,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _hasReachedBottom ? () {
                                    setState(() {
                                      _hasReadTerms = !_hasReadTerms;
                                      if (_hasReadTerms) {
                                        _hasAccepted = true;
                                      }
                                    });
                                  } : null,
                                  child: Text(
                                    'I understand and agree to the PrivFed Privacy Policy and Participating Bank Terms (ε = ${_epsilonValue.toStringAsFixed(1)})',
                                    style: TextStyle(
                                      color: _hasReachedBottom 
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.white.withOpacity(0.3),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_hasReachedBottom)
                            Padding(
                              padding: const EdgeInsets.only(left: 48, top: 4),
                              child: Text(
                                'Please scroll to the bottom to enable acceptance',
                                style: TextStyle(
                                  color: AppTheme.cyberCyan.withOpacity(0.5),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Keep text "walkthrough-friendly": short headings + short paragraphs.
                          _policyHeading('PrivFed Privacy Policy & Participating Bank Terms'),
                          _policyHeading('1) Introduction / Purpose'),
                          _policyBody(
                            'PrivFed helps financial institutions improve fraud detection using federated learning. '
                            'Your institution trains and evaluates locally, while the federation coordinates privacy-preserving learning '
                            'signals and reports model quality back to you.',
                          ),
                          _policyBody(
                            'PrivFed is designed to keep raw transaction records inside the institution - no raw data is shared between banks.',
                          ),

                          const SizedBox(height: 10),
                          _policyHeading('2) Data Collection and Usage'),
                          _policyBullet('Raw transaction data never leaves your institution or device.'),
                          _policyBullet('For fraud predictions, you submit only the transaction features required for scoring.'),
                          _policyBullet('For federated training, what\'s shared is privacy-protected learning signals (e.g., model updates) and aggregated metrics.'),
                          _policyBullet('For security and operations, PrivFed may collect monitoring telemetry (e.g., request logs and system events). This telemetry is used for auditing and reliability, not to expose raw transaction data.'),
                          _policyBullet('We use metrics and privacy accounting outputs (AUC, recall-style evaluation, fairness indicators, and DP budget status) to power the dashboards.'),

                          const SizedBox(height: 10),
                          _policyHeading('3) Privacy Protection Measures'),
                          _policyBody(
                            'PrivFed applies Differential Privacy training (DP-SGD). During training, gradients are clipped and noise is added '
                            'so individual contributions cannot be reliably recovered.',
                          ),
                          _policyBody(
                            'We track the privacy budget using epsilon (ε) and delta (δ). Lower ε means stronger protection (more noise). '
                            'Your chosen ε is displayed during onboarding and shown in monitoring views so your governance team can review the privacy trade-off.',
                          ),

                          const SizedBox(height: 10),
                          _policyHeading('4) User Responsibilities (Banks / Admins)'),
                          _policyBullet('Use PrivFed to support legitimate fraud detection and model governance.'),
                          _policyBullet('Protect access credentials, restrict admin actions to authorized personnel, and follow your internal security controls.'),
                          _policyBullet('Do not attempt to reverse-engineer training data or infer individual customer behavior.'),
                          _policyBullet('Do not misuse predictions (for example, outside approved fraud/risk programs or in ways prohibited by law or policy).'),

                          const SizedBox(height: 10),
                          _policyHeading('5) Fair Use and Ethical AI Clause'),
                          _policyBullet('We encourage responsible use and fairness monitoring across institutions.'),
                          _policyBullet('Do not use PrivFed in a way that unfairly discriminates or targets individuals or groups without a lawful basis and oversight.'),

                          const SizedBox(height: 10),
                          _policyHeading('6) Limitations and Liability'),
                          _policyBody(
                            'Fraud predictions are probabilistic. The system provides risk scores and explanations - not guarantees that a transaction is fraud.',
                          ),
                          _policyBody(
                            'False positives and false negatives are possible. Your institution remains responsible for investigation, decisioning, and any regulatory approvals required for downstream actions.',
                          ),

                          const SizedBox(height: 10),
                          _policyHeading('7) Security and Compliance'),
                          _policyBullet('PrivFed uses authentication and role checks to control access to protected actions.'),
                          _policyBullet('PrivFed operational logs support monitoring and auditing of system behavior (for example, request logging and security events).'),
                          _policyBullet('When deployed in production, encryption in transit (TLS/HTTPS behind your reverse proxy) should be used to protect network traffic.'),
                          _policyBullet('PrivFed follows data-minimization principles and purpose limitation aligned with GDPR-style expectations (where applicable).'),

                          const SizedBox(height: 10),
                          _policyHeading('8) Consent and Participation in Federation'),
                          _policyBody(
                            'Your institution agrees before joining the federation and participating in training rounds. PrivFed supports federation membership '
                            'via a bank application and a governance voting process.',
                          ),
                          _policyBullet('New banks are approved when a 2/3 consensus threshold is met (rounded up).'),

                          const SizedBox(height: 10),
                          _policyHeading('9) Transparency and Monitoring'),
                          _policyBullet('Dashboards show global and per-bank performance metrics (including AUC) and privacy budget status.'),
                          _policyBullet('Fairness analysis helps highlight performance disparities between institutions.'),
                          _policyBullet('Privacy budget status (ε) is visible so your team can review the privacy-utility trade-off over time.'),

                          const SizedBox(height: 10),
                          _policyHeading('10) Updates and Changes'),
                          _policyBody(
                            'We may update these Terms and the Privacy Policy as PrivFed evolves. When you participate again (e.g., joining a federation or re-entering onboarding), you will be asked to review and accept the latest version.',
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
                            // Explicitly move to Step 3: Hardware Scan
                            final uri = Uri(
                              path: '/onboarding/scan',
                              queryParameters: {
                                if (widget.nodeId != null) 'nodeId': widget.nodeId!,
                                'epsilon': _epsilonValue.toStringAsFixed(1),
                              },
                            );
                            context.go(uri.toString());
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

  Widget _policyHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _policyBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.62),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _policyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  ParticleBackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.cyberCyan.withOpacity(0.1);
    final random = math.Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      // Vertical drift to match Step 1 aesthetic
      final yOffset = (animation.value * 150 * (random.nextDouble() + 0.5)) % size.height;
      final y = (random.nextDouble() * size.height + yOffset) % size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) => true;
}
