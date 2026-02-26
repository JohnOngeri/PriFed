import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class NeuralNetworkArchitectureScreen extends StatefulWidget {
  const NeuralNetworkArchitectureScreen({super.key});

  @override
  State<NeuralNetworkArchitectureScreen> createState() => _NeuralNetworkArchitectureScreenState();
}

class _NeuralNetworkArchitectureScreenState extends State<NeuralNetworkArchitectureScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _layerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _flowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _layerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flowController.dispose();
    _layerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        title: const Text(
          'NEURAL NETWORK ARCHITECTURE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModelOverview(),
            const SizedBox(height: 24),
            _buildArchitectureVisualization(),
            const SizedBox(height: 24),
            _buildLayerDetails(),
            const SizedBox(height: 24),
            _buildNetworkMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_tree,
                  color: AppTheme.cyberCyan,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Federated Learning Model',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deep Neural Network for Fraud Detection',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Layers', '8', Icons.layers),
              const SizedBox(width: 16),
              _buildStatItem('Parameters', '2.4M', Icons.memory),
              const SizedBox(width: 16),
              _buildStatItem('Banks', '12', Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMedium.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.cyberCyan, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureVisualization() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: NeuralNetworkPainter(
          pulseAnimation: _pulseController,
          flowAnimation: _flowController,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildLayerDetails() {
    final layers = [
      {'name': 'Input Layer', 'neurons': '128', 'activation': 'ReLU'},
      {'name': 'Hidden Layer 1', 'neurons': '256', 'activation': 'ReLU'},
      {'name': 'Hidden Layer 2', 'neurons': '512', 'activation': 'ReLU'},
      {'name': 'Hidden Layer 3', 'neurons': '256', 'activation': 'ReLU'},
      {'name': 'Hidden Layer 4', 'neurons': '128', 'activation': 'ReLU'},
      {'name': 'Dropout Layer', 'rate': '0.3', 'activation': '-'},
      {'name': 'Hidden Layer 5', 'neurons': '64', 'activation': 'ReLU'},
      {'name': 'Output Layer', 'neurons': '2', 'activation': 'Sigmoid'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layer Architecture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...layers.map((layer) => _buildLayerCard(layer)),
      ],
    );
  }

  Widget _buildLayerCard(Map<String, String> layer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cyberCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (layer['neurons'] != null)
                      Text(
                        'Neurons: ${layer['neurons']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    if (layer['rate'] != null)
                      Text(
                        'Dropout Rate: ${layer['rate']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Text(
                      'Activation: ${layer['activation']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Model Accuracy', '94.2%', 0.942),
          const SizedBox(height: 16),
          _buildMetricRow('Training Loss', '0.12', 0.88),
          const SizedBox(height: 16),
          _buildMetricRow('Validation Accuracy', '92.8%', 0.928),
          const SizedBox(height: 16),
          _buildMetricRow('Federated Rounds', '45/50', 0.9),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
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
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceMedium,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyberCyan),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class NeuralNetworkPainter extends CustomPainter {
  final Animation<double> pulseAnimation;
  final Animation<double> flowAnimation;

  NeuralNetworkPainter({
    required this.pulseAnimation,
    required this.flowAnimation,
  }) : super(repaint: Listenable.merge([pulseAnimation, flowAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final nodePaint = Paint()
      ..color = AppTheme.cyberCyan
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.3 * pulseAnimation.value)
      ..style = PaintingStyle.fill;

    // Draw layers
    final layerCount = 5;
    final layerSpacing = size.width / (layerCount + 1);
    final nodeRadius = 8.0;
    final nodesPerLayer = [4, 6, 8, 6, 2];

    final layers = <List<Offset>>[];

    for (int layer = 0; layer < layerCount; layer++) {
      final x = layerSpacing * (layer + 1);
      final layerNodes = <Offset>[];
      final nodeCount = nodesPerLayer[layer];
      final nodeSpacing = size.height / (nodeCount + 1);

      for (int node = 0; node < nodeCount; node++) {
        final y = nodeSpacing * (node + 1);
        final nodePos = Offset(x, y);
        layerNodes.add(nodePos);

        // Draw node with glow
        canvas.drawCircle(nodePos, nodeRadius + 2, glowPaint);
        canvas.drawCircle(nodePos, nodeRadius, nodePaint);
      }
      layers.add(layerNodes);
    }

    // Draw connections
    for (int layer = 0; layer < layers.length - 1; layer++) {
      for (final fromNode in layers[layer]) {
        for (final toNode in layers[layer + 1]) {
          final flowOffset = flowAnimation.value * (toNode - fromNode).distance;
          final connectionPaint = Paint()
            ..color = AppTheme.cyberCyan.withOpacity(0.3)
            ..strokeWidth = 1;

          canvas.drawLine(fromNode, toNode, connectionPaint);

          // Draw flowing data
          if (flowOffset > 0 && flowOffset < (toNode - fromNode).distance) {
            final flowPoint = Offset.lerp(fromNode, toNode, flowOffset / (toNode - fromNode).distance)!;
            canvas.drawCircle(flowPoint, 3, nodePaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(NeuralNetworkPainter oldDelegate) => true;
}

