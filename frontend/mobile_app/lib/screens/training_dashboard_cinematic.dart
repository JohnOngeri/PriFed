import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../components/futuristic_visuals.dart';
import '../components/world_map_visualization.dart';
import 'dart:math' as math;

class TrainingDashboardCinematic extends StatefulWidget {
  const TrainingDashboardCinematic({super.key});

  @override
  State<TrainingDashboardCinematic> createState() => _TrainingDashboardCinematicState();
}

class _TrainingDashboardCinematicState extends State<TrainingDashboardCinematic>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _chartController;
  late AnimationController _pulseController;
  late AnimationController _timelineController;
  
  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _progressController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _chartController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _timelineController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepNavy,
              AppTheme.surfaceDark,
              AppTheme.deepNavy,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildGlobalNetworkCard(),
                      const SizedBox(height: 24),
                      _buildNeuralNetworkVisualization(),
                      const SizedBox(height: 24),
                      _buildLiveMetricsChart(),
                      const SizedBox(height: 24),
                      _buildTimelineVisualization(),
                      const SizedBox(height: 24),
                      _buildRoundDetails(),
                      const SizedBox(height: 24),
                      _buildTrainingMetrics(),
                      const SizedBox(height: 24),
                      _buildLiveActivityFeed(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.cyberCyan.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Training Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time federated learning',
                  style: TextStyle(
                    color: AppTheme.cyberCyan.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neuralGreen.withOpacity(0.3 + _pulseController.value * 0.1),
                      AppTheme.cyberCyan.withOpacity(0.2 + _pulseController.value * 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.neuralGreen.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neuralGreen.withOpacity(0.4 * _pulseController.value),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.neuralGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neuralGreen.withOpacity(0.8),
                            blurRadius: 8 + _pulseController.value * 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppTheme.neuralGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final status = appState.systemStatus;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryCyan.withOpacity(0.25),
                AppTheme.primaryPurple.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.primaryCyan.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Round progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round ${status.currentRound}/${status.totalRounds}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Federated Learning Progress',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            // Background circle
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white.withOpacity(0.1),
                              ),
                            ),
                            // Progress circle
                            CircularProgressIndicator(
                              value: status.progress * _progressController.value,
                              strokeWidth: 6,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation(
                                AppTheme.primaryCyan,
                              ),
                            ),
                            // Center text
                            Center(
                              child: Text(
                                '${(status.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Progress bar with shimmer
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Elapsed: 2h 34m | Remaining: 52m',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            // Progress fill
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: status.progress * _progressController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            // Shimmer effect
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Positioned(
                                  left: (MediaQuery.of(context).size.width - 32) * 
                                        status.progress * _pulseController.value,
                                  child: Container(
                                    width: 20,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.5),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Current metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Current Global AUC',
                      appState.globalMetrics.auc.toStringAsFixed(3),
                      Icons.trending_up,
                      AppTheme.accentGreen,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Active Banks',
                      '${status.participatingBanks}/3',
                      Icons.business,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Privacy Budget',
                      'ε = ${appState.privacyMetrics.currentEpsilon.toStringAsFixed(1)}',
                      Icons.shield,
                      AppTheme.primaryPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGlobalNetworkCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: AppTheme.cyberCyan, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Global Network',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const WorldMapVisualization(
              showDevices: true,
              showConnections: true,
              animateConnections: true,
              height: 200,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Federated learning across global network',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetricsChart() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          margin: const EdgeInsets.all(AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Training Metrics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Real-time',
                      style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Chart
              AnimatedBuilder(
                animation: _chartController,
                builder: (context, child) {
                  return SizedBox(
                    height: 200,
                    child: LineChart(
                      _buildChartData(appState.trainingRounds, _chartController.value),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Global', AppTheme.primaryCyan, true),
                  _buildLegendItem('Bank A', AppTheme.primaryBlue, false),
                  _buildLegendItem('Bank B', AppTheme.accentGreen, false),
                  _buildLegendItem('Bank C', AppTheme.primaryPurple, false),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isThick) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isThick ? 20 : 16,
          height: isThick ? 3 : 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<dynamic> rounds, double animationValue) {
    final spots = <FlSpot>[];
    final bankASpots = <FlSpot>[];
    final bankBSpots = <FlSpot>[];
    final bankCSpots = <FlSpot>[];
    
    final maxRounds = (rounds.length * animationValue).round();
    
    for (int i = 0; i < maxRounds && i < rounds.length; i++) {
      final round = rounds[i];
      spots.add(FlSpot(i.toDouble(), round.globalMetrics.auc * 100));
      
      if (round.clientMetrics.containsKey('bank_a')) {
        bankASpots.add(FlSpot(i.toDouble(), round.clientMetrics['bank_a']!.auc * 100));
      }
      if (round.clientMetrics.containsKey('bank_b')) {
        bankBSpots.add(FlSpot(i.toDouble(), round.clientMetrics['bank_b']!.auc * 100));
      }
      if (round.clientMetrics.containsKey('bank_c')) {
        bankCSpots.add(FlSpot(i.toDouble(), round.clientMetrics['bank_c']!.auc * 100));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 10,
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
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: math.max(rounds.length.toDouble() - 1, 10),
      minY: 85,
      maxY: 100,
      lineBarsData: [
        // Global line (thick)
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: AppTheme.primaryGradient,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryCyan.withOpacity(0.3),
                AppTheme.primaryCyan.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Bank A line
        LineChartBarData(
          spots: bankASpots,
          isCurved: true,
          color: AppTheme.primaryBlue,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Bank B line
        LineChartBarData(
          spots: bankBSpots,
          isCurved: true,
          color: AppTheme.accentGreen,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
        // Bank C line
        LineChartBarData(
          spots: bankCSpots,
          isCurved: true,
          color: AppTheme.primaryPurple,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      ],
    );
  }

  Widget _buildTimelineVisualization() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final status = appState.systemStatus;
        
        return Container(
          margin: const EdgeInsets.all(AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Training Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              AnimatedBuilder(
                animation: _timelineController,
                builder: (context, child) {
                  return SizedBox(
                    height: 60,
                    child: CustomPaint(
                      painter: TimelinePainter(
                        currentRound: status.currentRound,
                        totalRounds: status.totalRounds,
                        animationValue: _timelineController.value,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Timeline labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Round 1',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Current: ${status.currentRound}',
                    style: const TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Target: ${status.totalRounds}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoundDetails() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final status = appState.systemStatus;
        
        return Container(
          margin: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: ExpansionTile(
            title: Text(
              'Round ${status.currentRound} Details',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  children: appState.banks.map((bank) {
                    return _buildBankProgress(bank.name, bank.metrics.auc, bank.color);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankProgress(String bankName, double auc, String colorName) {
    Color color;
    switch (colorName) {
      case 'blue':
        color = AppTheme.primaryBlue;
        break;
      case 'green':
        color = AppTheme.accentGreen;
        break;
      case 'purple':
        color = AppTheme.primaryPurple;
        break;
      default:
        color = AppTheme.primaryCyan;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.business,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(auc * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: auc,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < 5 ? AppTheme.accentGold : Colors.white.withOpacity(0.3),
                size: 16,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralNetworkVisualization() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Neural Network Architecture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Center(
            child: Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3)),
              ),
              child: const NeuralNetworkViz(width: double.infinity, height: 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingMetrics() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Training Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildTrainingMetricCard('Training Loss', '0.0234', 'Decreasing', AppTheme.cyberCyan, Icons.trending_down),
          const SizedBox(height: AppTheme.spacingM),
          _buildTrainingMetricCard('Validation Accuracy', '94.7%', 'Improving', AppTheme.accentGreen, Icons.trending_up),
          const SizedBox(height: AppTheme.spacingM),
          _buildTrainingMetricCard('Current Epoch', '47/100', 'In Progress', AppTheme.warningAmber, Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildTrainingMetricCard(String title, String value, String status, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActivityFeed() {
    final activities = [
      ActivityItem(
        icon: Icons.check_circle,
        color: AppTheme.accentGreen,
        message: 'Round 47 completed',
        timestamp: '2 seconds ago',
      ),
      ActivityItem(
        icon: Icons.upload,
        color: AppTheme.primaryBlue,
        message: 'Bank C submitted update',
        timestamp: '5 seconds ago',
      ),
      ActivityItem(
        icon: Icons.settings,
        color: AppTheme.primaryCyan,
        message: 'Aggregation started',
        timestamp: '8 seconds ago',
      ),
      ActivityItem(
        icon: Icons.download,
        color: AppTheme.accentGreen,
        message: 'Bank B received global model',
        timestamp: '12 seconds ago',
      ),
      ActivityItem(
        icon: Icons.security,
        color: AppTheme.primaryPurple,
        message: 'Privacy budget updated: ε = 7.92',
        timestamp: '15 seconds ago',
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Activity Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.5),
                          blurRadius: 4 + _pulseController.value * 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          ...activities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  activity.timestamp,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  final int currentRound;
  final int totalRounds;
  final double animationValue;
  
  TimelinePainter({
    required this.currentRound,
    required this.totalRounds,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    
    // Draw background line
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
    
    // Draw completed rounds
    paint.color = AppTheme.accentGreen;
    final completedWidth = (currentRound / totalRounds) * size.width * animationValue;
    canvas.drawLine(
      Offset(0, y),
      Offset(completedWidth, y),
      paint,
    );
    
    // Draw milestone markers
    for (int i = 10; i <= totalRounds; i += 10) {
      final x = (i / totalRounds) * size.width;
      final isCompleted = i <= currentRound;
      
      paint.color = isCompleted ? AppTheme.accentGreen : Colors.white.withOpacity(0.3);
      canvas.drawCircle(Offset(x, y), 6, paint);
      
      // Milestone number
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: TextStyle(
            color: isCompleted ? AppTheme.accentGreen : Colors.white.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y + 12),
      );
    }
    
    // Draw current round marker
    if (currentRound > 0) {
      final currentX = (currentRound / totalRounds) * size.width;
      
      // Pulsing current marker
      paint.color = AppTheme.primaryCyan;
      canvas.drawCircle(Offset(currentX, y), 8, paint);
      
      // Glow effect
      paint.color = AppTheme.primaryCyan.withOpacity(0.3);
      canvas.drawCircle(Offset(currentX, y), 12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ActivityItem {
  final IconData icon;
  final Color color;
  final String message;
  final String timestamp;

  ActivityItem({
    required this.icon,
    required this.color,
    required this.message,
    required this.timestamp,
  });
}