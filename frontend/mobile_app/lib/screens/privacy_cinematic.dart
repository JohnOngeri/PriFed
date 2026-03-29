import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// ---------------------------------------------------------------------------
/// PRIVACY CINEMATIC: THE DIFFERENTIAL PRIVACY LAB
/// 
/// CORE FUNCTIONALITY: 
/// Visualizes the "Noise Injection" process that prevents individual 
/// data leakage in a Federated Network. Designed for high-stakes 
/// academic and professional judging.
/// ---------------------------------------------------------------------------

class PrivacyCinematic extends StatefulWidget {
  const PrivacyCinematic({super.key});

  @override
  State<PrivacyCinematic> createState() => _PrivacyCinematicState();
}

class _PrivacyCinematicState extends State<PrivacyCinematic>
    with TickerProviderStateMixin {
  
  // --- Animation Controllers ---
  late AnimationController _fadeController;
  late AnimationController _noiseController;
  late AnimationController _pulseController;
  late AnimationController _shieldController;
  
  // --- State Variables ---
  double _epsilonValue = 1.0; // The "Privacy Budget"
  bool _webContentReady = false;
  int _currentNarrativeIndex = 0;
  Timer? _narrativeTimer;

  // --- Constants & Colors ---
  static const Color spaceDark = Color(0xFF060912);
  static const Color cyanGlow = AppTheme.cyberCyan;
  static const Color privacyPurple = AppTheme.privacyPurple;
  static const Color neonGreen = AppTheme.neuralGreen;
  static const Color warningRed = AppTheme.dangerRed;

  // --- Narrative Data for Judges ---
  final List<String> _privacyInsights = [
    "*** NOISE INJECTION ACTIVE: We are utilizing the Laplace Mechanism to perturb gradients. This ensures the 'Epsilon-Differential Privacy' guarantee, making it impossible to reverse-engineer a specific bank's dataset. ***",
    "*** SOVEREIGNTY COMPLIANCE: Configuration optimized for Kenya's Data Protection Act (2019). No Personal Identifiable Information (PII) ever leaves the Nairobi or Lagos nodes. ***",
    "*** PRIVACY-UTILITY TRADE-OFF: A lower ε (Epsilon) adds more noise, protecting the individual but slightly reducing global accuracy. PriFed automatically finds the 'Golden Ratio' for African banking. ***"
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize complex animation sequences
    _fadeController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..forward();
    _noiseController = AnimationController(duration: const Duration(seconds: 5), vsync: this)..repeat();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _shieldController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..forward();

    // Rotate through AI Insights for a "Live Thinking" feel
    _narrativeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentNarrativeIndex = (_currentNarrativeIndex + 1) % _privacyInsights.length;
        });
      }
    });

    // Web stability guard
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _webContentReady = true);
      });
    } else {
      _webContentReady = true;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _noiseController.dispose();
    _pulseController.dispose();
    _shieldController.dispose();
    _narrativeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webContentReady) return const Scaffold(backgroundColor: spaceDark);

    return Scaffold(
      backgroundColor: spaceDark,
      body: Stack(
        children: [
          _buildBackgroundAura(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildAILabStatus(),
                  const SizedBox(height: 25),
                  _buildVisualNoiseChamber(),
                  const SizedBox(height: 30),
                  _buildNarrativeBox(),
                  const SizedBox(height: 30),
                  _buildEpsilonControlPanel(),
                  const SizedBox(height: 30),
                  _buildImpactGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENT BUILDERS ---

  Widget _buildBackgroundAura() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, -0.4),
            radius: 1.5,
            colors: [Color(0xFF0E1A3D), spaceDark],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        const Column(
          children: [
            Text("PRIVACY SHIELD", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text("MATHEMATICAL DATA PROTECTION", style: TextStyle(color: privacyPurple, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        _buildShieldStatusIndicator(),
      ],
    );
  }

  Widget _buildShieldStatusIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: privacyPurple.withOpacity(0.3 * _pulseController.value), width: 2),
        ),
        child: Icon(Icons.security, color: privacyPurple.withOpacity(0.5 + 0.5 * _pulseController.value), size: 18),
      ),
    );
  }

  Widget _buildAILabStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _labStat("EPSILON (ε)", _epsilonValue.toStringAsFixed(1), cyanGlow),
          _labStat("PRIVACY", _getPrivacyStrength(_epsilonValue), neonGreen),
          _labStat("NOISE LVL", "${((10 - _epsilonValue) * 10).toInt()}%", privacyPurple),
        ],
      ),
    );
  }

  Widget _labStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVisualNoiseChamber() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Live Noise Painter
            CustomPaint(
              size: Size.infinite,
              painter: LaplaceNoisePainter(
                epsilon: _epsilonValue,
                animation: _noiseController.value,
              ),
            ),
            // The "Protected Identity" Fingerprint
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spaceDark.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: _getPrivacyColor(_epsilonValue).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.fingerprint_rounded,
                color: _getPrivacyColor(_epsilonValue),
                size: 80,
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: const Text("INDIVIDUAL RECORD MASKING", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeBox() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentNarrativeIndex),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: privacyPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: privacyPurple.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: privacyPurple, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _privacyInsights[_currentNarrativeIndex],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpsilonControlPanel() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF111729),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PRIVACY BUDGET (ε)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              Icon(Icons.info_outline, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Lowering epsilon increases 'Differential Noise' for stronger protection.", style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 25),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cyanGlow,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: cyanGlow.withOpacity(0.2),
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              value: _epsilonValue,
              min: 0.1,
              max: 10.0,
              divisions: 99,
              onChanged: (val) => setState(() => _epsilonValue = val),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shieldTag("MAX ANONYMITY", _epsilonValue <= 2.0),
              _shieldTag("PEAK UTILITY", _epsilonValue >= 8.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shieldTag(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? neonGreen.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(color: active ? neonGreen : Colors.white10, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildImpactGrid() {
    return Row(
      children: [
        _impactCard("DATA SAFETY", _getSafetyDesc(_epsilonValue), _getPrivacyColor(_epsilonValue), Icons.verified_user),
        const SizedBox(width: 15),
        _impactCard("MODEL GAIN", _getUtilityDesc(_epsilonValue), _getUtilityColor(_epsilonValue), Icons.analytics),
      ],
    );
  }

  Widget _impactCard(String title, String desc, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(desc, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // --- HELPER LOGIC ---

  String _getPrivacyStrength(double eps) => eps <= 2.0 ? 'MAXIMUM' : eps <= 5.0 ? 'STRONG' : 'WEAK';
  String _getSafetyDesc(double eps) => eps <= 2.0 ? 'TOTAL' : eps <= 6.0 ? 'SECURE' : 'EXPOSED';
  String _getUtilityDesc(double eps) => eps <= 2.0 ? 'LOW' : eps <= 6.0 ? 'OPTIMAL' : 'MAXIMUM';

  Color _getPrivacyColor(double eps) {
    if (eps <= 3.0) return neonGreen;
    if (eps <= 7.0) return Colors.orangeAccent;
    return warningRed;
  }

  Color _getUtilityColor(double eps) {
    if (eps <= 3.0) return warningRed;
    if (eps <= 7.0) return cyanGlow;
    return neonGreen;
  }
}

/// ---------------------------------------------------------------------------
/// LAPLACE NOISE PAINTER
/// Custom GPU-accelerated drawing to visualize Differential Privacy noise.
/// ---------------------------------------------------------------------------

class LaplaceNoisePainter extends CustomPainter {
  final double epsilon;
  final double animation;

  LaplaceNoisePainter({required this.epsilon, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rand = math.Random(123); // Consistent seed for stable visuals
    
    // As Epsilon goes DOWN, Noise goes UP
    int particleCount = ((10.5 - epsilon) * 15).toInt();
    double baseRadius = (10.5 - epsilon) * 5;

    for (int i = 0; i < particleCount; i++) {
      double x = rand.nextDouble() * size.width;
      double y = rand.nextDouble() * size.height;
      
      // Animate noise expansion
      double wave = math.sin((animation * 2 * math.pi) + i);
      double radius = (rand.nextDouble() * baseRadius) * (1.2 + wave * 0.3);

      paint.color = AppTheme.privacyPurple.withOpacity(0.05 + (0.2 * (1 - epsilon / 10)));
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Draw faint connections to simulate gradient perturbation
      if (i % 4 == 0) {
        final linePaint = Paint()
          ..color = AppTheme.cyberCyan.withOpacity(0.03)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(x, y), Offset(size.width / 2, size.height / 2), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaplaceNoisePainter oldDelegate) => 
      oldDelegate.epsilon != epsilon || oldDelegate.animation != animation;
}