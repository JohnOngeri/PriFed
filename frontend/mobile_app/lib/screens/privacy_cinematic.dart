import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/futuristic_visuals.dart';
import '../theme/app_theme.dart';

class PrivacyCinematic extends StatefulWidget {
  const PrivacyCinematic({super.key});

  @override
  State<PrivacyCinematic> createState() => _PrivacyCinematicState();
}

class _PrivacyCinematicState extends State<PrivacyCinematic>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  double _epsilonValue = 8.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.arrow_back, color: AppTheme.cyberCyan, size: 28),
                    ),
                    const Text(
                      'Differential Privacy',
                      style: TextStyle(
                        color: AppTheme.glowWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Security Shield (Center, 240x280px)
                Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: const SecurityShield(
                          size: 240,
                          showCheckmark: true,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Settings Panel
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F3A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings Panel',
                              style: TextStyle(
                                color: AppTheme.glowWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              'Configure differential privacy parameters to balance privacy protection with model utility. Lower epsilon values provide stronger privacy guarantees.',
                              style: TextStyle(
                                color: AppTheme.cyberCyan.withOpacity(0.8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Epsilon Slider
                            const Text(
                              'Privacy Budget (ε)',
                              style: TextStyle(
                                color: AppTheme.glowWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Text(
                                  '1.0',
                                  style: TextStyle(
                                    color: AppTheme.cyberCyan.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppTheme.cyberCyan,
                                      inactiveTrackColor: AppTheme.cyberCyan.withOpacity(0.3),
                                      thumbColor: AppTheme.cyberCyan,
                                      overlayColor: AppTheme.cyberCyan.withOpacity(0.2),
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _epsilonValue,
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 18,
                                      onChanged: (value) {
                                        setState(() {
                                          _epsilonValue = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  '10.0',
                                  style: TextStyle(
                                    color: AppTheme.cyberCyan.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyberCyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.cyberCyan, width: 1),
                                ),
                                child: Text(
                                  'ε = ${_epsilonValue.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    color: AppTheme.cyberCyan,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Privacy Metrics
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          _buildMetricCard(
                            'Privacy Strength',
                            _getPrivacyStrength(_epsilonValue),
                            _getPrivacyColor(_epsilonValue),
                            Icons.shield,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Model Utility',
                            _getModelUtility(_epsilonValue),
                            _getUtilityColor(_epsilonValue),
                            Icons.analytics,
                          ),
                          const SizedBox(height: 16),
                          _buildMetricCard(
                            'Budget Remaining',
                            '${(100 - (_epsilonValue / 10 * 100)).toStringAsFixed(0)}%',
                            AppTheme.cyberCyan,
                            Icons.account_balance_wallet,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
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
                    color: AppTheme.glowWhite.withOpacity(0.8),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPrivacyStrength(double epsilon) {
    if (epsilon <= 2.0) return 'Very Strong';
    if (epsilon <= 4.0) return 'Strong';
    if (epsilon <= 6.0) return 'Moderate';
    if (epsilon <= 8.0) return 'Weak';
    return 'Very Weak';
  }

  String _getModelUtility(double epsilon) {
    if (epsilon <= 2.0) return 'Low';
    if (epsilon <= 4.0) return 'Moderate';
    if (epsilon <= 6.0) return 'Good';
    if (epsilon <= 8.0) return 'High';
    return 'Very High';
  }

  Color _getPrivacyColor(double epsilon) {
    if (epsilon <= 2.0) return AppTheme.neuralGreen;
    if (epsilon <= 4.0) return AppTheme.cyberCyan;
    if (epsilon <= 6.0) return AppTheme.warningAmber;
    return AppTheme.dangerRed;
  }

  Color _getUtilityColor(double epsilon) {
    if (epsilon <= 2.0) return AppTheme.dangerRed;
    if (epsilon <= 4.0) return AppTheme.warningAmber;
    if (epsilon <= 6.0) return AppTheme.cyberCyan;
    return AppTheme.neuralGreen;
  }
}