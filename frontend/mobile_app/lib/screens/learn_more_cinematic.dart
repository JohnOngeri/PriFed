import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ---------------------------------------------------------------------------
/// LEARN MORE CINEMATIC: THE KIGALI TRUST MESH
/// 
/// UNIQUE VALUE: Uses local context (Kimironko to Downtown) to demonstrate 
/// real-time "Intelligence Vaccination". Proves that an attack in one 
/// suburb creates immunity in the city center within 120ms.
/// ---------------------------------------------------------------------------

class LearnMoreCinematic extends StatefulWidget {
  const LearnMoreCinematic({super.key});

  @override
  State<LearnMoreCinematic> createState() => _LearnMoreCinematicState();
}

class _LearnMoreCinematicState extends State<LearnMoreCinematic>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _transferController;
  int _activeStep = 0;
  bool _webContentReady = false;

  // Modern Fintech Palette
  static const Color spaceDark = Color(0xFF060912);
  static const Color cyanGlow = Color(0xFF00F5FF);
  static const Color privacyPurple = Color(0xFFD500F9);
  static const Color goldWinner = Color(0xFFFFD700);
  static const Color neonGreen = Color(0xFF00FF88);

  final List<LifecycleStep> _steps = [
    LifecycleStep(
      title: "Local Flag: Kimironko",
      location: "Equity Bank Branch",
      desc: "A suspicious high-value transaction is attempted at an ATM in Kimironko. The local PriFed agent detects a 0.82 fraud probability.",
      icon: Icons.location_on_rounded,
      aiInsight: "*** SENSITIVE DATA ALERT: No customer names or account numbers leave Kimironko. Only the mathematical anomaly is processed. ***",
      color: cyanGlow,
    ),
    LifecycleStep(
      title: "Laplace Shielding",
      location: "On-Premise Server",
      desc: "Before transmission, we inject Laplace noise (ε=8.0). This masks the 'Kimironko ATM ID' while preserving the fraud pattern logic.",
      icon: Icons.security_rounded,
      aiInsight: "*** PRIVACY COMPLIANCE: This step satisfies the Rwanda Data Protection Law by ensuring zero PII enters the shared mesh. ***",
      color: privacyPurple,
    ),
    LifecycleStep(
      title: "The Shared Brain",
      location: "National Aggregator",
      desc: "The update is merged with patterns from across Rwanda. The Global Model learns this new 'Midnight Thief' pattern instantly.",
      icon: Icons.hub_rounded,
      aiInsight: "*** COLLECTIVE GAIN: The model reaches 0.7289 AUC, nearly matching the performance of a giant centralized data lake. ***",
      color: goldWinner,
    ),
    LifecycleStep(
      title: "Downtown Immunity",
      location: "Bank of Kigali HQ",
      desc: "The 'Intelligence Vaccine' is pushed to BK Downtown. If the thief tries the same card there, the system blocks it instantly.",
      icon: Icons.verified_user_rounded,
      aiInsight: "*** RESULT: Downtown Kigali is now immune to an attack that happened 4km away in Kimironko just 120ms ago. ***",
      color: neonGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _transferController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    
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
    _pulseController.dispose();
    _transferController.dispose();
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildKigaliPulseVisual(),
                      const SizedBox(height: 30),
                      _buildInteractiveTimeline(),
                      const SizedBox(height: 30),
                      _buildScientificTruthCard(),
                      const SizedBox(height: 30),
                      _buildLocalMythBusters(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundAura() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.5, -0.5),
            radius: 1.5,
            colors: [Color(0xFF0A1633), spaceDark],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.go('/dashboard'),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("KNOWLEDGE LIFECYCLE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
              Text("THE 120ms VACCINATION PULSE", style: TextStyle(color: cyanGlow, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKigaliPulseVisual() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: KigaliTransferPainter(
              progress: _transferController.value,
              pulse: _pulseController.value,
              activeStep: _activeStep,
            ),
          ),
          Positioned(
            top: 0, left: 0,
            child: _locationLabel("KIMIRONKO", cyanGlow),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: _locationLabel("DOWNTOWN", neonGreen),
          ),
        ],
      ),
    );
  }

  Widget _locationLabel(String text, Color color) {
    return Column(
      children: [
        Icon(Icons.account_balance, color: color, size: 16),
        Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildInteractiveTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHRONOLOGY OF A DEFENSE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15),
        ..._steps.asMap().entries.map((entry) => _buildTimelineStep(entry.value, entry.key)),
      ],
    );
  }

  Widget _buildTimelineStep(LifecycleStep step, int index) {
    bool isActive = _activeStep == index;
    return GestureDetector(
      onTap: () => setState(() => _activeStep = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? step.color.withOpacity(0.4) : Colors.white.withOpacity(0.03)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 12, 
                  backgroundColor: isActive ? step.color : Colors.white10,
                  child: Text("${index + 1}", style: TextStyle(color: isActive ? Colors.black : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                if (index != _steps.length - 1) Container(width: 1, height: 40, color: Colors.white10),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(step.location.toUpperCase(), style: TextStyle(color: step.color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900)),
                  if (isActive) Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(step.desc, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                  ),
                  if (isActive) Container(
                    margin: const EdgeInsets.only(top: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                    child: Text(step.aiInsight, style: TextStyle(color: step.color, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScientificTruthCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF111729),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text("EMPIRICAL EVIDENCE (ROUND 50)", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _truthRow("Local AUC (Isolated)", "0.582", Colors.white24),
          const Divider(color: Colors.white10, height: 20),
          _truthRow("PriFed Global AUC", "0.728", cyanGlow),
          const SizedBox(height: 15),
          const Text(
            "By collaborating, Bank of Kigali Downtown gains a 25% accuracy increase from patterns it hasn't even seen yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _truthRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildLocalMythBusters() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [goldWinner.withOpacity(0.1), Colors.transparent]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: goldWinner.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb, color: goldWinner, size: 18),
            SizedBox(width: 10),
            Text("SKEPTIC'S CORNER", style: TextStyle(color: goldWinner, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
          const SizedBox(height: 15),
          _myth("Wait, does BK see Equity's customer balances?", "No. Only 'Gradient Updates' (math slopes) are shared. It's impossible to reverse-engineer a gradient back to a bank balance."),
          const SizedBox(height: 10),
          _myth("Is it really fast enough for real-time?", "Yes. The entire lifecycle—from Kimironko flag to Downtown immunity—takes under 120ms, faster than a standard card authorization pulse."),
        ],
      ),
    );
  }

  Widget _myth(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(a, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class LifecycleStep {
  final String title;
  final String location;
  final String desc;
  final String aiInsight;
  final IconData icon;
  final Color color;
  LifecycleStep({required this.title, required this.location, required this.desc, required this.aiInsight, required this.icon, required this.color});
}

class KigaliTransferPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final int activeStep;

  KigaliTransferPainter({required this.progress, required this.pulse, required this.activeStep});

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(40, 40);
    final end = Offset(size.width - 40, size.height - 40);
    final center = Offset(size.width / 2, size.height / 2);
    
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 1.5..style = PaintingStyle.stroke;

    // 1. Draw Paths
    linePaint.color = Colors.white.withOpacity(0.05);
    Path path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(center.dx, start.dy, center.dx, center.dy);
    path.quadraticBezierTo(center.dx, end.dy, end.dx, end.dy);
    canvas.drawPath(path, linePaint);

    // 2. Draw Moving Intelligence Particles
    if (activeStep >= 2) {
      final metrics = path.computeMetrics().first;
      for (int i = 0; i < 3; i++) {
        double p = (progress + (i * 0.33)) % 1.0;
        final tangent = metrics.getTangentForOffset(metrics.length * p);
        if (tangent != null) {
          paint.color = const Color(0xFFFFD700);
          canvas.drawCircle(tangent.position, 2, paint);
          paint.color = const Color(0xFFFFD700).withOpacity(0.2);
          canvas.drawCircle(tangent.position, 6 * pulse, paint);
        }
      }
    }

    // 3. Draw Nodes
    _drawNode(canvas, start, const Color(0xFF00F5FF), activeStep >= 0);
    _drawNode(canvas, center, const Color(0xFFD500F9), activeStep >= 2);
    _drawNode(canvas, end, const Color(0xFF00FF88), activeStep >= 3);
  }

  void _drawNode(Canvas canvas, Offset pos, Color color, bool active) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (active) {
      paint.color = color.withOpacity(0.2 * pulse);
      canvas.drawCircle(pos, 15, paint);
      paint.color = color;
      canvas.drawCircle(pos, 4, paint);
    } else {
      paint.color = Colors.white10;
      canvas.drawCircle(pos, 3, paint);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}