import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// ---------------------------------------------------------------------------
/// THE PAN-AFRICAN TRUST MESH
/// Focuses on regional sovereignty in East, West, and Southern Africa.
/// Visualizes how Federated Learning creates a "Shared Brain" for the continent.
/// ---------------------------------------------------------------------------

class BankHQNetworkScreen extends StatefulWidget {
  const BankHQNetworkScreen({super.key});

  @override
  State<BankHQNetworkScreen> createState() => _BankHQNetworkScreenState();
}

class _BankHQNetworkScreenState extends State<BankHQNetworkScreen>
    with TickerProviderStateMixin {
  
  // --- Controllers ---
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _entryController;
  
  // --- AI Narrative Logic ---
  int _currentInsightIndex = 0;
  Timer? _insightTimer;
  final List<String> _aiInsights = [
    "*** PriFed optimizes for regional nuances in Nairobi and Lagos. By localizing training, we capture unique African fraud patterns without violating the Kenya Data Protection Act. ***",
    "*** Satellite nodes in Cairo and Kigali are zero-trust entry points. New institutions join the mesh asynchronously, gaining immediate protection from the Global Intelligence Pool. ***",
    "*** Architecture optimized for M-Pesa and Airtel Money integration. Sensitive PII stays on-premise, while encrypted gradients stop regional fraud rings in real-time. ***"
  ];

  // --- Data Nodes: Nairobi, Lagos, Joburg ---
  final List<BankNode> nodes = [
    BankNode(name: 'Primary Node A (East)', city: 'Nairobi, Kenya', status: 'TRANSMITTING', gain: '+34.2%', isPrimary: true, lat: -1.286, lon: 36.817),
    BankNode(name: 'Primary Node B (West)', city: 'Lagos, Nigeria', status: 'TRAINING', gain: '+28.5%', isPrimary: true, lat: 6.524, lon: 3.379),
    BankNode(name: 'Primary Node C (South)', city: 'Johannesburg, SA', status: 'ACTIVE', gain: '+41.9%', isPrimary: true, lat: -26.204, lon: 28.047),
    // Scaling Satellite Nodes
    BankNode(name: 'Kigali Satellite', city: 'Rwanda', status: 'IDLE', gain: 'PENDING', isPrimary: false, lat: -1.944, lon: 30.061),
    BankNode(name: 'Accra Satellite', city: 'Ghana', status: 'IDLE', gain: 'PENDING', isPrimary: false, lat: 5.603, lon: -0.187),
    BankNode(name: 'Cairo Gateway', city: 'Egypt', status: 'IDLE', gain: 'N/A', isPrimary: false, lat: 30.044, lon: 31.235),
    BankNode(name: 'Addis Hub', city: 'Ethiopia', status: 'IDLE', gain: 'N/A', isPrimary: false, lat: 9.033, lon: 38.750),
  ];

  static const Color cyanGlow = Color(0xFF00F5FF);
  static const Color privacyPurple = Color(0xFFD500F9);
  static const Color spaceDark = Color(0xFF060912);
  static const Color neonGreen = Color(0xFF00FF88);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _flowController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();
    _entryController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..forward();

    // Rotate through AI Insights every 8 seconds
    _insightTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) setState(() => _currentInsightIndex = (_currentInsightIndex + 1) % _aiInsights.length);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flowController.dispose();
    _entryController.dispose();
    _insightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: spaceDark,
      body: Stack(
        children: [
          _buildAtmosphericBase(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildInsightPanel(),
                const SizedBox(height: 10),
                _buildMeshVisualizer(),
                const SizedBox(height: 15),
                _buildRegionSummary(),
                Expanded(child: _buildNodeRegistry()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildAtmosphericBase() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: [Color(0xFF0B1A3D), spaceDark],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.grid_view_rounded, color: Colors.white70), onPressed: () => context.go('/dashboard')),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AFRICA TRUST MESH", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text("DECENTRALIZED INTELLIGENCE NETWORK", style: TextStyle(color: cyanGlow, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          _buildPrimaryBadge(),
        ],
      ),
    );
  }

  Widget _buildPrimaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: neonGreen)),
      child: const Text("3 NODES LIVE", style: TextStyle(color: neonGreen, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildInsightPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentInsightIndex),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        height: 85,
        width: double.infinity,
        decoration: BoxDecoration(
          color: privacyPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: privacyPurple.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: privacyPurple, size: 20),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _aiInsights[_currentInsightIndex],
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeshVisualizer() {
    return Container(
      height: 280,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          _buildMapLines(),
          CustomPaint(
            size: Size.infinite,
            painter: AfricaMeshPainter(
              nodes: nodes,
              pulse: _pulseController.value,
              flow: _flowController.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLines() {
    return Opacity(
      opacity: 0.05,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 12),
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.5))),
      ),
    );
  }

  Widget _buildRegionSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("SATELLITE REGISTRY", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text("EAST • WEST • SOUTH", style: TextStyle(color: cyanGlow.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNodeRegistry() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: nodes.length,
      itemBuilder: (context, index) => _buildNodeCard(nodes[index], index),
    );
  }

  Widget _buildNodeCard(BankNode node, int index) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) {
        final slide = Curves.easeOutCubic.transform((_entryController.value - (index * 0.1)).clamp(0, 1));
        return Opacity(
          opacity: slide,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - slide)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: node.isPrimary ? cyanGlow.withOpacity(0.1) : Colors.white10),
              ),
              child: Row(
                children: [
                  _nodeIcon(node),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.name, style: TextStyle(color: node.isPrimary ? Colors.white : Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(node.city.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (node.isPrimary) _nodeMetrics(node),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nodeIcon(BankNode node) {
    final color = node.isPrimary ? cyanGlow : Colors.white12;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(node.isPrimary ? Icons.wifi_tethering : Icons.radar, color: color, size: 18),
    );
  }

  Widget _nodeMetrics(BankNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(node.gain, style: const TextStyle(color: neonGreen, fontSize: 14, fontWeight: FontWeight.w900)),
        const Text("NETWORK DIVIDEND", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- MODELS & PAINTERS ---

class BankNode {
  final String name;
  final String city;
  final String status;
  final String gain;
  final bool isPrimary;
  final double lat;
  final double lon;
  BankNode({required this.name, required this.city, required this.status, required this.gain, required this.isPrimary, required this.lat, required this.lon});
}

class AfricaMeshPainter extends CustomPainter {
  final List<BankNode> nodes;
  final double pulse;
  final double flow;

  AfricaMeshPainter({required this.nodes, required this.pulse, required this.flow});

  @override
  void paint(Canvas canvas, Size size) {
    // Focus Africa View Bounds
    const minLat = -38.0; const maxLat = 38.0;
    const minLon = -20.0; const maxLon = 55.0;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    
    List<Offset> points = nodes.map((n) {
      final x = (n.lon - minLon) / (maxLon - minLon) * size.width;
      final y = (1 - (n.lat - minLat) / (maxLat - minLat)) * size.height;
      return Offset(x, y);
    }).toList();

    // 1. Draw Paths to Global Aggregator (Primary Only)
    for (int i = 0; i < points.length; i++) {
      if (nodes[i].isPrimary) {
        final p = points[i];
        final linePaint = Paint()..color = const Color(0xFF00F5FF).withOpacity(0.1)..strokeWidth = 1;
        
        Path path = Path();
        path.moveTo(p.dx, p.dy);
        path.quadraticBezierTo(center.dx, p.dy, center.dx, center.dy);
        canvas.drawPath(path, linePaint);

        // Gradient Particles
        final metrics = path.computeMetrics().first;
        final tangent = metrics.getTangentForOffset(metrics.length * ((flow + (i * 0.3)) % 1.0));
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2, Paint()..color = const Color(0xFF00F5FF));
          canvas.drawCircle(tangent.position, 6 * pulse, Paint()..color = const Color(0xFF00F5FF).withOpacity(0.2));
        }
      }
    }

    // 2. Draw Nodes
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isPrimary = nodes[i].isPrimary;
      
      if (isPrimary) {
        // Privacy Shield Visualization
        paint.color = const Color(0xFFD500F9).withOpacity(0.15 * pulse);
        canvas.drawCircle(p, 15, paint);
        
        paint.color = const Color(0xFF00F5FF);
        canvas.drawCircle(p, 4, paint);
        canvas.drawCircle(p, 8, Paint()..style = PaintingStyle.stroke..color = Colors.white24);
      } else {
        canvas.drawCircle(p, 2, Paint()..color = Colors.white10);
      }
    }

    // 3. Central Aggregator
    paint.color = Colors.white12;
    canvas.drawCircle(center, 25 + (5 * pulse), paint);
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}