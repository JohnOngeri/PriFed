import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/futuristic_visuals.dart';
import '../components/animated_background.dart';

class LiveDemoScreen extends StatefulWidget {
  const LiveDemoScreen({super.key});

  @override
  State<LiveDemoScreen> createState() => _LiveDemoScreenState();
}

class _LiveDemoScreenState extends State<LiveDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _simulationController;
  late AnimationController _privacyController;
  bool _isRunning = false;
  int _currentRound = 0;
  double _globalAccuracy = 0.0;
  double _privacyBudget = 10.0;

  @override
  void initState() {
    super.initState();
    _simulationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _privacyController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _simulationController.addListener(() {
      setState(() {
        _currentRound = (_simulationController.value * 50).round();
        _globalAccuracy = 0.85 + (_simulationController.value * 0.10);
        _privacyBudget = 10.0 - (_simulationController.value * 2.0);
      });
    });
  }

  @override
  void dispose() {
    _simulationController.dispose();
    _privacyController.dispose();
    super.dispose();
  }

  void _startSimulation() {
    setState(() => _isRunning = true);
    _simulationController.forward();
    _privacyController.repeat();
  }

  void _stopSimulation() {
    setState(() => _isRunning = false);
    _simulationController.stop();
    _privacyController.stop();
  }

  void _resetSimulation() {
    setState(() {
      _isRunning = false;
      _currentRound = 0;
      _globalAccuracy = 0.0;
      _privacyBudget = 10.0;
    });
    _simulationController.reset();
    _privacyController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            child: Container(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSimulationControls(),
                        const SizedBox(height: 20),
                        _buildBankProgress(),
                        const SizedBox(height: 20),
                        _buildPrivacyMeter(),
                        const SizedBox(height: 20),
                        _buildGlobalMetrics(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          HolographicButton(
            onPressed: () {
              // Use Navigator.pop() first to properly dispose widgets and textures
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/dashboard');
              }
            },
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.cyberGradient.createShader(bounds),
                  child: const Text(
                    'Live Demo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'Federated Learning Simulation',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControls() {
    return GlassmorphicContainer(
      child: Column(
        children: [
          const Text(
            'Simulation Controls',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HolographicButton(
                onPressed: _isRunning ? null : _startSimulation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: _isRunning ? Colors.grey : AppTheme.cyberCyan),
                    const SizedBox(width: 8),
                    Text('Start', style: TextStyle(color: _isRunning ? Colors.grey : Colors.white)),
                  ],
                ),
              ),
              HolographicButton(
                onPressed: _isRunning ? _stopSimulation : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause, color: !_isRunning ? Colors.grey : AppTheme.neonPink),
                    const SizedBox(width: 8),
                    Text('Pause', style: TextStyle(color: !_isRunning ? Colors.grey : Colors.white)),
                  ],
                ),
              ),
              HolographicButton(
                onPressed: _resetSimulation,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: AppTheme.electricBlue),
                    SizedBox(width: 8),
                    Text('Reset', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Round: $_currentRound/50',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBankProgress() {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Training Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBankCard('Bank A', 0.92 + (_simulationController.value * 0.03), AppTheme.cyberCyan),
          const SizedBox(height: 12),
          _buildBankCard('Bank B', 0.89 + (_simulationController.value * 0.04), AppTheme.electricBlue),
          const SizedBox(height: 12),
          _buildBankCard('Bank C', 0.87 + (_simulationController.value * 0.05), AppTheme.neonPink),
        ],
      ),
    );
  }

  Widget _buildBankCard(String bankName, double accuracy, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isRunning ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: _isRunning
                ? RotationTransition(
                    turns: _privacyController,
                    child: const Icon(Icons.sync, size: 8, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: accuracy,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyMeter() {
    return GlassmorphicContainer(
      child: Column(
        children: [
          const Text(
            'Privacy Budget (ε)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _privacyBudget / 10.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _privacyBudget > 5 ? AppTheme.cyberCyan : AppTheme.neonPink,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _privacyBudget.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'remaining',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _privacyBudget > 5 ? 'Strong Privacy' : 'Privacy Depleting',
            style: TextStyle(
              color: _privacyBudget > 5 ? AppTheme.cyberCyan : AppTheme.neonPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMetrics() {
    return GlassmorphicContainer(
      child: Column(
        children: [
          const Text(
            'Global Model Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Accuracy',
                  '${(_globalAccuracy * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'F1 Score',
                  '${((_globalAccuracy - 0.05) * 100).toStringAsFixed(1)}%',
                  Icons.balance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'AUC',
                  '${((_globalAccuracy + 0.02) * 100).toStringAsFixed(1)}%',
                  Icons.show_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Precision',
                  '${((_globalAccuracy - 0.03) * 100).toStringAsFixed(1)}%',
                  Icons.precision_manufacturing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.holographicGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.cyberCyan, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}