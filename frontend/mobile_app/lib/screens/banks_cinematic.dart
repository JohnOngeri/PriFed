import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class BanksCinematic extends StatefulWidget {
  const BanksCinematic({super.key});

  @override
  State<BanksCinematic> createState() => _BanksCinematicState();
}

class _BanksCinematicState extends State<BanksCinematic>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _chartController;
  late PageController _pageController;
  
  int _selectedBankIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pageController = PageController();
    
    _cardController.forward();
    _chartController.forward();
    
    // Pre-load images to prevent texture rendering issues
    // Use ResizeImage to force exact size decoding without mipmaps
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        ResizeImage(
          const AssetImage('assets/images/world_map2.png'),
          width: 2400,
          height: 1200,
        ),
        context,
      );
      // Pre-load bank images with exact dimensions (3x for high-DPI to prevent upscaling)
      // Using 168x168 (3x of 56x56) ensures no upscaling on any device
      precacheImage(
        ResizeImage(
          const AssetImage('assets/images/bank_hq1.png'),
          width: 168,
          height: 168,
        ),
        context,
      );
      precacheImage(
        ResizeImage(
          const AssetImage('assets/images/bank representation.jpg'),
          width: 168,
          height: 168,
        ),
        context,
      );
      precacheImage(
        ResizeImage(
          const AssetImage('assets/images/bank management.jpg'),
          width: 168,
          height: 168,
        ),
        context,
      );
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _chartController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Global Network and Federation Health
                      Row(
                        children: [
                          Expanded(child: _buildGlobalNetworkSection()),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(child: _buildFederationHealth()),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Bank Selector Section
                      _buildBankSelectorSection(),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Performance Metrics Grid
                      _buildPerformanceMetrics(),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Bottom Section: Fairness Indicator and Charts
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildFairnessIndicator(),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildDetailedCharts(),
                                const SizedBox(height: AppTheme.spacingM),
                                _buildAUCScoreOverRounds(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
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
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Use Navigator.pop() first to properly dispose widgets and textures
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacingS),
          const Text(
            'Banks Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Toggle comparison view
            },
            icon: const Icon(Icons.compare_arrows, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelectorSection() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.cyberCyan.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bank Selectors',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(appState.banks.length, (index) {
                      final bank = appState.banks[index];
                      final isSelected = index == _selectedBankIndex;
                      
                      return Flexible(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < appState.banks.length - 1 ? AppTheme.spacingS : 0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBankIndex = index;
                              });
                            },
                            child: _buildBankCard(bank, isSelected),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankCard(BankData bank, bool isSelected) {
    Color bankColor = _getBankColor(bank.color);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bankColor.withOpacity(isSelected ? 0.4 : 0.15),
            bankColor.withOpacity(isSelected ? 0.2 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: bankColor.withOpacity(isSelected ? 0.8 : 0.3),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: bankColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bank image or icon - Use Container with DecorationImage to avoid texture mipmap issues
          // DecorationImage in BoxDecoration avoids ClipRRect and BoxFit transformations that trigger mipmaps
          RepaintBoundary(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: bankColor.withOpacity(0.6),
                  width: 2,
                ),
                // Use DecorationImage with BoxFit.fill to avoid scaling transformations
                // BoxFit.fill avoids aspect ratio calculations that trigger mipmap generation
                image: DecorationImage(
                  image: ResizeImage(
                    AssetImage(_getBankImagePath(bank.name)),
                    width: 168,
                    height: 168,
                  ),
                  // Use BoxFit.fill instead of cover to avoid aspect ratio calculations
                  // This prevents Impeller from generating mipmaps during transformation
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  // No onError callback for DecorationImage, use color/gradient as fallback
                ),
                // Fallback gradient if image fails to load (only used if image is null)
                gradient: LinearGradient(
                  colors: [
                    bankColor.withOpacity(0.8),
                    bankColor.withOpacity(0.4),
                  ],
                ),
                // Remove boxShadow to avoid blur operations that trigger texture mipmaps
                // boxShadow: [
                //   BoxShadow(
                //     color: bankColor.withOpacity(0.3),
                //     blurRadius: 8,
                //     spreadRadius: 1,
                //   ),
                // ],
              ),
              // Overlay icon as indicator (optional)
              child: Icon(
                _getBankIcon(bank.icon),
                color: Colors.white.withOpacity(0.2),
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // Bank name
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              bank.name,
              style: TextStyle(
                color: bankColor,
                fontSize: isSelected ? 16 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Quick metric
          Text(
            '${(bank.metrics.auc * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAUCScoreOverRounds() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Get data for all banks for comparison
        final allBanksData = <String, List<FlSpot>>{};
        final bankColors = [
          AppTheme.primaryBlue,
          AppTheme.accentGreen,
          AppTheme.primaryPurple,
        ];
        
        for (int bankIndex = 0; bankIndex < appState.banks.length; bankIndex++) {
          final bankId = appState.banks[bankIndex].id;
          final spots = <FlSpot>[];
          
          for (int i = 0; i < appState.trainingRounds.length; i++) {
            final round = appState.trainingRounds[i];
            final bankMetrics = round.clientMetrics[bankId];
            if (bankMetrics != null) {
              spots.add(FlSpot(i.toDouble(), bankMetrics.auc));
            }
          }
          
          if (spots.isNotEmpty) {
            allBanksData[bankId] = spots;
          }
        }
        
        // Generate sample data if empty
        if (allBanksData.isEmpty) {
          for (int bankIndex = 0; bankIndex < 3; bankIndex++) {
            final spots = <FlSpot>[
              FlSpot(0, 0.85 + (bankIndex * 0.01)),
              FlSpot(10, 0.88 + (bankIndex * 0.01)),
              FlSpot(20, 0.91 + (bankIndex * 0.01)),
              FlSpot(30, 0.93 + (bankIndex * 0.01)),
              FlSpot(40, 0.94 + (bankIndex * 0.01)),
            ];
            allBanksData['bank_$bankIndex'] = spots;
          }
        }
        
        final maxX = allBanksData.values.isEmpty 
            ? 50.0 
            : (allBanksData.values.map((spots) => spots.last.x).reduce((a, b) => a > b ? a : b) + 5).toDouble();
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
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
                'AUC Score Over Rounds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 0.05,
                      verticalInterval: 10,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.05),
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
                        axisNameWidget: const Text(
                          'Rounds',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: maxX / 5,
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
                        axisNameWidget: const Text(
                          'AUC',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          interval: 0.1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(2),
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
                    maxX: maxX,
                    minY: 0.8,
                    maxY: 1.0,
                    lineBarsData: allBanksData.entries.map((entry) {
                      final bankIndex = allBanksData.keys.toList().indexOf(entry.key);
                      final color = bankIndex < bankColors.length 
                          ? bankColors[bankIndex] 
                          : AppTheme.cyberCyan;
                      
                      return LineChartBarData(
                        spots: entry.value,
                        isCurved: true,
                        color: color,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(0.25),
                              color.withOpacity(0.0),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: AppTheme.deepNavy.withOpacity(0.95),
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),
              ),
              // Legend
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: appState.banks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bank = entry.value;
                  final color = index < bankColors.length 
                      ? bankColors[index] 
                      : AppTheme.cyberCyan;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bank.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildPerformanceMetrics() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final bank = appState.banks[_selectedBankIndex];
        final metrics = bank.metrics;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Metrics grid - 4 cards in 2x2 layout
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.1,
              children: [
                _buildMetricCard('AUC Score', metrics.auc, AppTheme.accentGreen),
                _buildMetricCard('Precision', metrics.precision, AppTheme.primaryPurple),
                _buildMetricCard('F1 Score', metrics.f1, AppTheme.accentGreen),
                _buildMetricCard('Recall', metrics.recall, AppTheme.primaryBlue),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (value * 100).toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Progress bar
          const SizedBox(height: AppTheme.spacingS),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          // Star rating
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < (value * 5).round() 
                    ? AppTheme.accentGold 
                    : Colors.white.withOpacity(0.2),
                size: 14,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCharts() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
            'Detailed Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Tab selector
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  indicatorColor: AppTheme.primaryCyan,
                  labelColor: AppTheme.primaryCyan,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Performance'),
                    Tab(text: 'Confusion Matrix'),
                    Tab(text: 'Feature Importance'),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                SizedBox(
                  height: 180,
                  child: TabBarView(
                    children: [
                      _buildPerformanceChart(),
                      _buildConfusionMatrix(),
                      _buildFeatureImportance(),
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

  Widget _buildPerformanceChart() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.trainingRounds.isEmpty) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        
        final bankId = appState.banks[_selectedBankIndex].id;
        final spots = <FlSpot>[];
        
        for (int i = 0; i < appState.trainingRounds.length; i++) {
          final round = appState.trainingRounds[i];
          final bankMetrics = round.clientMetrics[bankId];
          if (bankMetrics != null) {
            spots.add(FlSpot(i.toDouble(), bankMetrics.auc));
          }
        }
        
        if (spots.isEmpty) {
          spots.add(const FlSpot(0, 0.85));
          spots.add(const FlSpot(10, 0.88));
          spots.add(const FlSpot(20, 0.91));
          spots.add(const FlSpot(30, 0.93));
          spots.add(const FlSpot(40, 0.94));
        }
        
        return Container(
          padding: const EdgeInsets.all(8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.05,
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
                      interval: spots.length > 10 ? (spots.length / 5).roundToDouble() : 1.0,
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
                    interval: 0.1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(2),
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
              maxX: spots.isEmpty ? 50 : spots.last.x + 5,
              minY: 0.8,
              maxY: 1.0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.cyberCyan,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.cyberCyan,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.cyberCyan.withOpacity(0.3),
                        AppTheme.cyberCyan.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppTheme.deepNavy.withOpacity(0.9),
                  tooltipRoundedRadius: 8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfusionMatrix() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Expanded(child: Container()),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Predicted: Normal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Predicted: Fraud',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Data rows
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Actual:\nNormal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMatrixCell('True Negative', '45,231', AppTheme.accentGreen),
                ),
                Expanded(
                  child: _buildMatrixCell('False Positive', '1,247', AppTheme.warningAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Actual:\nFraud',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMatrixCell('False Negative', '892', AppTheme.dangerRed),
                ),
                Expanded(
                  child: _buildMatrixCell('True Positive', '1,456', AppTheme.accentGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCell(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureImportance() {
    final features = [
      ('TransactionAmt', 0.43, AppTheme.cyberCyan),
      ('card_addr_dist', 0.31, AppTheme.primaryPurple),
      ('P_emaildomain', 0.18, AppTheme.accentGreen),
      ('DeviceType', 0.08, AppTheme.warningAmber),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: feature.$3.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: feature.$3.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: feature.$3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(feature.$2 * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: feature.$3,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: feature.$2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                feature.$3,
                                feature.$3.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: feature.$3.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
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
        }).toList(),
      ),
    );
  }

  Widget _buildFairnessIndicator() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final fairnessScore = appState.getFairnessScore();
        final variance = ((1 - fairnessScore) * 100).toStringAsFixed(5);
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentGreen.withOpacity(0.2),
                AppTheme.accentGreen.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.accentGreen.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fairness Indicator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'All banks within $variance% of each other',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen.withOpacity(0.2),
                    foregroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.accentGreen.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: const Text(
                    'FAIR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBankColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return AppTheme.primaryBlue;
      case 'green':
        return AppTheme.accentGreen;
      case 'purple':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.primaryCyan;
    }
  }

  IconData _getBankIcon(String iconName) {
    switch (iconName) {
      case 'building_modern':
        return Icons.business;
      case 'building_classical':
        return Icons.account_balance;
      case 'building_futuristic':
        return Icons.domain;
      default:
        return Icons.business;
    }
  }
  
  String _getBankImagePath(String bankName) {
    // Try to match bank name to available images
    if (bankName.toLowerCase().contains('bank a') || bankName.toLowerCase().contains('pioneer')) {
      return 'assets/images/bank_hq1.png';
    } else if (bankName.toLowerCase().contains('bank b') || bankName.toLowerCase().contains('innovator')) {
      return 'assets/images/bank representation.jpg';
    } else if (bankName.toLowerCase().contains('bank c') || bankName.toLowerCase().contains('guardian')) {
      return 'assets/images/bank management.jpg';
    }
    // Default to bank representation image
    return 'assets/images/bank representation.jpg';
  }

  Widget _buildGlobalNetworkSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Bank Network',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Use Container with DecorationImage instead of Image widget + ClipRRect
          // This avoids texture transformations that trigger Impeller mipmap generation
          RepaintBoundary(
            // Isolate image rendering to prevent texture conflicts with CustomPaint overlay
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Use DecorationImage with BoxFit.fill to avoid scaling transformations
                // BoxFit.fill avoids aspect ratio calculations that trigger mipmap generation
                image: DecorationImage(
                  image: ResizeImage(
                    const AssetImage('assets/images/world_map2.png'),
                    width: 2400,
                    height: 1200,
                  ),
                  // Use BoxFit.fill instead of cover to avoid aspect ratio calculations
                  // This prevents Impeller from generating mipmaps during transformation
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
                // Fallback gradient if image fails to load (only used if image is null)
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.deepNavy,
                    AppTheme.surfaceDark,
                  ],
                ),
              ),
              // Use Stack with Positioned.fill for overlay instead of ClipRRect + Stack
              child: Stack(
                children: [
                  // Overlay with animated connection points - isolated in separate RepaintBoundary
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _cardController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: NetworkOverlayPainter(
                              animationValue: _cardController.value,
                            ),
                          );
                        },
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
  
  Widget _buildFederationHealth() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final fairnessScore = appState.getFairnessScore();
        final healthPercentage = (fairnessScore * 100).clamp(0.0, 100.0);
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.accentGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard, color: AppTheme.accentGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Federation Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: healthPercentage / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          healthPercentage > 80 
                            ? AppTheme.accentGreen 
                            : healthPercentage > 60 
                              ? AppTheme.warningAmber 
                              : AppTheme.dangerRed,
                        ),
                      ),
                    ),
                    // Percentage text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${healthPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Performance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGreen.withOpacity(0.5),
                  ),
                ),
                child: const Text(
                  'FAIR',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NetworkOverlayPainter extends CustomPainter {
  final double animationValue;
  
  NetworkOverlayPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyberCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final glowPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.3 * animationValue)
      ..style = PaintingStyle.fill;
    
    // Draw connection points (banks on world map)
    final bankPositions = [
      Offset(size.width * 0.25, size.height * 0.3),  // Bank A
      Offset(size.width * 0.75, size.height * 0.4),  // Bank B
      Offset(size.width * 0.5, size.height * 0.7),   // Bank C
    ];
    
    // Draw connections between banks
    for (int i = 0; i < bankPositions.length; i++) {
      for (int j = i + 1; j < bankPositions.length; j++) {
        final start = bankPositions[i];
        final end = bankPositions[j];
        
        // Animated connection line
        final progress = (animationValue * 2) % 1.0;
        final animatedPoint = Offset.lerp(start, end, progress)!;
        
        // Draw connection line
        canvas.drawLine(start, end, paint);
        
        // Draw animated pulse point
        canvas.drawCircle(animatedPoint, 6, glowPaint);
        canvas.drawCircle(animatedPoint, 3, paint..style = PaintingStyle.fill);
      }
    }
    
    // Draw bank nodes with glow
    for (final position in bankPositions) {
      canvas.drawCircle(position, 8, glowPaint);
      canvas.drawCircle(position, 5, paint..style = PaintingStyle.fill);
      canvas.drawCircle(position, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}