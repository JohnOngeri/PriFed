import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../components/dashboard_card.dart';
import '../providers/api_service.dart';
import '../models/models.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background image.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              // Use cache dimensions to prevent mipmap generation (full screen size at 2x)
              cacheWidth: 800,
              cacheHeight: 1600,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading background image: $error');
                return Container(
                  color: const Color(0xFF0A0F1E),
                );
              },
            ),
          ),

          // Dark overlay for readability (reduced opacity to show background)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildBackendStatusRow(),
                  
                  // Main Dashboard Grid
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildDashboardGrid(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendStatusRow() {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        Color dotColor(bool healthy) =>
            healthy ? Colors.greenAccent : Colors.redAccent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _StatusDot(color: dotColor(api.authHealthy)),
                  const SizedBox(width: 6),
                  const Text(
                    'Node.js API',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  _StatusDot(color: dotColor(api.aiHealthy)),
                  const SizedBox(width: 6),
                  const Text(
                    'FastAPI AI',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Top bar with back button and settings
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  // Show confirmation dialog for sign out
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1A1F3A),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/login');
                            },
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                tooltip: 'Sign Out',
              ),
              IconButton(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
        // Logo icon section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
              const SizedBox(height: 16),
              // COLLABORATION text
              const Text(
                'COLLABORATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    if (isMobile) {
      // Mobile: Single column
      return Column(
        children: [
          _buildTrainingCard(),
          const SizedBox(height: 16),
          _buildNeuralNetworkCard(),
          const SizedBox(height: 16),
          _buildBanksRepresentationCard(),
          const SizedBox(height: 16),
          _buildPrivacyCard(),
          const SizedBox(height: 16),
          _buildBankHQCard(),
          const SizedBox(height: 16),
          _buildFraudExplorerCard(),
          const SizedBox(height: 16),
          _buildResultsCard(),
          const SizedBox(height: 16),
          _buildLearnMoreCard(),
          const SizedBox(height: 16),
          _buildLiveDemoCard(),
          const SizedBox(height: 16),
          _buildBankManagementCard(),
        ],
      );
    } else if (isTablet) {
      // Tablet: 2 columns
      return Column(
        children: [
          // First Row: Training and Neural Network
          Row(
            children: [
              Expanded(child: _buildTrainingCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildNeuralNetworkCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Second Row: Banks Representation and Privacy
          Row(
            children: [
              Expanded(child: _buildBanksRepresentationCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildPrivacyCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Third Row: Bank HQ and Fraud Explorer
          Row(
            children: [
              Expanded(child: _buildBankHQCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFraudExplorerCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Fourth Row: Results
          _buildResultsCard(),
          const SizedBox(height: 16),
          // Fifth Row: Learn More and Live Demo
          Row(
            children: [
              Expanded(child: _buildLearnMoreCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLiveDemoCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Sixth Row: Bank Management
          _buildBankManagementCard(),
        ],
      );
    } else {
      // Desktop: 3 columns
      return Column(
        children: [
          // First Row: Training, Neural Network, Bank HQ
          Row(
            children: [
              Expanded(child: _buildTrainingCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildNeuralNetworkCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildBankHQCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Second Row: Banks Representation, Privacy, Fraud Explorer
          Row(
            children: [
              Expanded(child: _buildBanksRepresentationCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildPrivacyCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFraudExplorerCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Third Row: Results, Learn More, Live Demo
          Row(
            children: [
              Expanded(child: _buildResultsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLearnMoreCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLiveDemoCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Fourth Row: Bank Management (centered)
          Row(
            children: [
              Expanded(child: Container()),
              Expanded(flex: 2, child: _buildBankManagementCard()),
              Expanded(child: Container()),
            ],
          ),
        ],
      );
    }
  }

  // Training Card
  Widget _buildTrainingCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'TRAINING',
        imagePath: 'assets/images/Training.jpg',
        onTap: () => context.go('/training'),
        child: Container(),
      ),
    );
  }

  // Neural Network Card
  Widget _buildNeuralNetworkCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'NEURAL NETWORK',
        imagePath: 'assets/images/neural_brain_dynamic.png',
        onTap: () => context.go('/neural-network'),
        child: Container(),
      ),
    );
  }

  // Banks Representation Card
  Widget _buildBanksRepresentationCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'BANKS REPRESENTATION',
        imagePath: 'assets/images/bank representation.jpg',
        onTap: () => context.go('/banks'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Consumer<ApiService>(
            builder: (context, api, _) {
              return FutureBuilder<Map<String, BankMetrics>>(
                future: api.getBankMetrics(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null || data.isEmpty) {
                    return const Text(
                      'Bank metrics unavailable (using simulated data)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  }

                  List<Widget> bankCards = [];
                  final keys = ['Bank_A', 'Bank_B', 'Bank_C'];
                  for (final key in keys) {
                    final m = data[key];
                    if (m == null) continue;
                    final samples = m.numSamples ?? 0;
                    final fraudRate = (m.fraudRate ?? 0.0) * 100;
                    bankCards.add(
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key.replaceAll('_', ' '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Samples: ${samples.toString()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fraud rate: ${fraudRate.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (bankCards.isEmpty) {
                    return const Text(
                      'No bank metrics available',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...bankCards.expand((w) => [w, const SizedBox(width: 8)])
                    ]..removeLast(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Privacy Card
  Widget _buildPrivacyCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'PRIVACY',
        imagePath: 'assets/images/privacy.jpg',
        onTap: () => context.go('/privacy'),
        child: Container(),
      ),
    );
  }

  // Bank HQ Card
  Widget _buildBankHQCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'BANK HQ',
        imagePath: 'assets/images/bank_hq1.png',
        onTap: () => context.go('/bank-hq'),
        child: Container(),
      ),
    );
  }

  // Fraud Explorer Card
  Widget _buildFraudExplorerCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'FRAUD EXPLORER',
        imagePath: 'assets/images/fraud_ai2.png',
        onTap: () => context.go('/fraud'),
        child: Container(),
      ),
    );
  }

  // Results Card with Chart
  Widget _buildResultsCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'RESULTS',
        imagePath: 'assets/images/Results.jpg',
        onTap: () => context.go('/results'),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: _buildResultsChart(),
        ),
      ),
    );
  }

  Widget _buildResultsChart() {
    final spots = [
      const FlSpot(0, 2.4),
      const FlSpot(1, 2.1),
      const FlSpot(2, 2.2),
      const FlSpot(3, 2.4),
      const FlSpot(4, 1.9),
      const FlSpot(5, 1.96),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 3,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // Learn More Card - World map
  Widget _buildLearnMoreCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'LEARN MORE',
        imagePath: 'assets/images/world_map2.png',
        onTap: () => context.go('/learn'),
        child: Container(),
      ),
    );
  }

  // Live Demo Card - Video grid
  Widget _buildLiveDemoCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'LIVE DEMO',
        imagePath: 'assets/images/people_office2.png',
        onTap: () => context.go('/demo'),
        child: Container(),
      ),
    );
  }

  // Bank Management Card
  Widget _buildBankManagementCard() {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: 'BANK MANAGEMENT',
        imagePath: 'assets/images/bank management.jpg',
        onTap: () => context.go('/bank-management'),
        child: Container(),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
