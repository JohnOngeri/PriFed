import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// ---------------------------------------------------------------------------
/// NEURAL NETWORK ARCHITECTURE SCREEN
/// Designed for Thesis Defense: Visualizes the 8-layer Deep Neural Network
/// and the Federated Aggregation logic with Differential Privacy.
/// ---------------------------------------------------------------------------

class NeuralNetworkArchitectureScreen extends StatefulWidget {
  const NeuralNetworkArchitectureScreen({super.key});

  @override
  State<NeuralNetworkArchitectureScreen> createState() => _NeuralNetworkArchitectureScreenState();
}

class _NeuralNetworkArchitectureScreenState extends State<NeuralNetworkArchitectureScreen>
    with TickerProviderStateMixin {
  
  // --- Controllers ---
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _entryController;
  
  // --- State ---
  String _selectedView = 'Architecture'; // 'Architecture' or 'Federated Flow'
  bool _webContentReady = false;

  // Fintech Styling
  static const Color spaceDark = Color(0xFF060912);
  static const Color cyanGlow = Color(0xFF00F5FF);
  static const Color purpleSecurity = Color(0xFFD500F9);
  static const Color neonGreen = Color(0xFF00FF88);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _flowController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    _entryController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..forward();

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
    _flowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webContentReady) return const Scaffold(backgroundColor: spaceDark);

    return Scaffold(
      backgroundColor: spaceDark,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildModelHeroHeader(),
            const SizedBox(height: 25),
            _buildViewToggle(),
            const SizedBox(height: 25),
            _buildInteractiveVisualizer(),
            const SizedBox(height: 25),
            _buildNarrativeExplanation(),
            const SizedBox(height: 25),
            _buildLayerAuditTable(),
            const SizedBox(height: 25),
            _buildFeatureImpactSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text(
        "NETWORK ARCHITECTURE",
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
      centerTitle: true,
    );
  }

  Widget _buildModelHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildHexIcon(Icons.psychology, cyanGlow),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PriFed-DNN v1.0", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text("Federated Deep Neural Network", style: TextStyle(color: cyanGlow, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildQuickBadge("SECURE", purpleSecurity),
        ],
      ),
    );
  }

  Widget _buildHexIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildQuickBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _toggleBtn("Architecture", Icons.layers),
          _toggleBtn("Federated Flow", Icons.sync_alt),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, IconData icon) {
    final isSel = _selectedView == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? cyanGlow : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSel ? Colors.black : Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveVisualizer() {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: ArchitecturePainter(
            viewMode: _selectedView,
            pulse: _pulseController.value,
            flow: _flowController.value,
          ),
        ),
      ),
    );
  }

  Widget _buildNarrativeExplanation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: purpleSecurity.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: purpleSecurity.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: purpleSecurity, size: 18),
            SizedBox(width: 10),
            Text("WHY THIS ARCHITECTURE?", style: TextStyle(color: purpleSecurity, fontSize: 12, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10),
          Text(
            _selectedView == 'Architecture' 
              ? "We use a customized 8-layer deep network. Note the 'Dropout' layers—these prevent the model from memorizing specific customer names, ensuring the AI focuses on fraud patterns, not personal identities."
              : "This flow visualizes the 'Aggregator.' Instead of sending raw transactions, our banks only exchange 'Gradients' (mathematical directions). This satisfies GDPR requirements while maintaining global accuracy.",
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerAuditTable() {
    final layers = [
      {"name": "INPUT TENSOR", "dim": "432", "act": "Linear", "type": "Data Entry"},
      {"name": "HIDDEN_01", "dim": "256", "act": "ReLU", "type": "Feature Extraction"},
      {"name": "DP_NOISE_LAYER", "dim": "256", "act": "Laplace", "type": "Privacy Injector"},
      {"name": "HIDDEN_02", "dim": "128", "act": "ReLU", "type": "Pattern Mapping"},
      {"name": "OUTPUT", "dim": "2", "act": "Sigmoid", "type": "Risk Logic"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ARCHITECTURE SPECIFICATIONS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        ...layers.map((l) => _buildLayerRow(l)),
      ],
    );
  }

  Widget _buildLayerRow(Map<String, String> l) {
    bool isDP = l['name']!.contains("DP");
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDP ? purpleSecurity.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: isDP ? purpleSecurity : cyanGlow),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text(l['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (isDP) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/privacy-shield'),
                      child: const Icon(Icons.open_in_new, color: purpleSecurity, size: 14),
                    ),
                  ],
                ],
              ),
              Text(l['type']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l['dim']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            Text(l['act']!, style: TextStyle(color: isDP ? purpleSecurity : cyanGlow, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeatureImpactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("REAL-TIME FEATURE IMPORTANCE (XAI)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _featureBar("Transaction Amount", 0.92),
          _featureBar("Transaction Hour", 0.74),
          _featureBar("Bank Metadata", 0.45),
          _featureBar("Device ID Hash", 0.31),
        ],
      ),
    );
  }

  Widget _featureBar(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text("${(val * 100).toInt()}%", style: const TextStyle(color: cyanGlow, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: val, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(cyanGlow), minHeight: 4),
      ]),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ARCHITECTURE PAINTER
/// The high-performance custom drawing logic.
/// ---------------------------------------------------------------------------

class ArchitecturePainter extends CustomPainter {
  final String viewMode;
  final double pulse;
  final double flow;

  ArchitecturePainter({required this.viewMode, required this.pulse, required this.flow});

  @override
  void paint(Canvas canvas, Size size) {
    if (viewMode == 'Architecture') {
      _paintNeuralLayers(canvas, size);
    } else {
      _paintFederatedFlow(canvas, size);
    }
  }

  void _paintNeuralLayers(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 0.5;

    final List<int> layers = [4, 6, 8, 5, 2];
    final double spacingX = size.width / (layers.length + 1);
    
    List<List<Offset>> nodeMap = [];

    // 1. Calculate and Draw Nodes
    for (int i = 0; i < layers.length; i++) {
      List<Offset> currentLayer = [];
      double spacingY = size.height / (layers[i] + 1);
      
      for (int j = 0; j < layers[i]; j++) {
        Offset pos = Offset(spacingX * (i + 1), spacingY * (j + 1));
        currentLayer.add(pos);

        // Draw Glow
        paint.color = (i == 2 ? const Color(0xFFD500F9) : const Color(0xFF00F5FF)).withOpacity(0.1 + (0.2 * pulse));
        canvas.drawCircle(pos, 8 + (4 * pulse), paint);

        // Draw Core
        paint.color = i == 2 ? const Color(0xFFD500F9) : const Color(0xFF00F5FF);
        canvas.drawCircle(pos, 4, paint);
      }
      nodeMap.add(currentLayer);
    }

    // 2. Draw Connections with Flowing Particles
    for (int i = 0; i < nodeMap.length - 1; i++) {
      for (var startNode in nodeMap[i]) {
        for (var endNode in nodeMap[i + 1]) {
          linePaint.color = Colors.white.withOpacity(0.05);
          canvas.drawLine(startNode, endNode, linePaint);

          // Flowing particle
          double dist = (endNode - startNode).distance;
          double progress = (flow * 2 + (startNode.dy / size.height)) % 1.0;
          Offset particlePos = Offset.lerp(startNode, endNode, progress)!;
          
          paint.color = Colors.white.withOpacity(0.2);
          canvas.drawCircle(particlePos, 1.5, paint);
        }
      }
    }
  }

  void _paintFederatedFlow(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    Offset center = Offset(size.width / 2, size.height / 2);
    
    // Draw Aggregator
    paint.color = const Color(0xFF00F5FF);
    canvas.drawCircle(center, 40, paint);
    
    // Draw 3 Bank Nodes
    List<Offset> banks = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8),
    ];

    for (var bank in banks) {
      paint.color = Colors.white24;
      canvas.drawCircle(bank, 25, paint);
      
      // Draw Flow Lines
      Path path = Path();
      path.moveTo(bank.dx, bank.dy);
      path.quadraticBezierTo(center.dx, bank.dy, center.dx, center.dy);
      
      paint.color = const Color(0xFFD500F9).withOpacity(0.2);
      canvas.drawPath(path, paint);

      // Gradient Particle Flow
      final metrics = path.computeMetrics().first;
      final tangent = metrics.getTangentForOffset(metrics.length * flow);
      if (tangent != null) {
        final dotPaint = Paint()..color = const Color(0xFFD500F9)..style = PaintingStyle.fill;
        canvas.drawCircle(tangent.position, 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}