import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../components/futuristic_visuals.dart';
import '../config/api_config.dart';
import '../providers/api_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final TextEditingController _apiUrlController = TextEditingController();

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
    _apiUrlController.dispose();
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
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Particle field (space-like)
            ...List.generate(30, (index) => 
              Positioned(
                left: (index * 53.0) % MediaQuery.of(context).size.width,
                top: (index * 37.0) % MediaQuery.of(context).size.height,
                child: Container(
                  width: 2 + (index % 3),
                  height: 2 + (index % 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [AppTheme.electricBlue, AppTheme.cyberCyan, AppTheme.privacyPurple][index % 3].withOpacity(0.4),
                  ),
                ),
              ),
            ),
            
            SafeArea(
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.cyberCyan,
                            size: 28,
                          ),
                        ),
                        Text(
                          'Settings',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.glowWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.settings,
                          color: AppTheme.cyberCyan,
                          size: 28,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Holographic Interface (Center, 300x300px)
                    Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: const HolographicInterface(
                              size: 300,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Settings Options
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              _buildApiServerSection(context),
                              const SizedBox(height: 16),
                              _buildHighPrivacyModeToggle(context),
                              const SizedBox(height: 16),
                              _buildPrivacyEngineSection(context),
                              const SizedBox(height: 16),
                              _buildPrivacyAuditSection(),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'Connectivity',
                                'Network and sync settings',
                                Icons.wifi,
                                AppTheme.cyberCyan,
                                () {},
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'Privacy Settings',
                                'Differential privacy configuration',
                                Icons.security,
                                AppTheme.privacyPurple,
                                () => context.go('/privacy'),
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'Training Parameters',
                                'Federated learning configuration',
                                Icons.tune,
                                AppTheme.electricBlue,
                                () {},
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'System Diagnostics',
                                'Performance and health monitoring',
                                Icons.monitor_heart,
                                AppTheme.neuralGreen,
                                () async {
                                  final apiService = Provider.of<ApiService>(context, listen: false);
                                  await apiService.updateBaseUrl(null);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'Export & Backup',
                                'Data export and backup options',
                                Icons.backup,
                                AppTheme.warningAmber,
                                () {},
                              ),
                              const SizedBox(height: 16),
                              _buildSettingsOption(
                                'Learn More',
                                'Educational content and tutorials',
                                Icons.school,
                                AppTheme.electricBlue,
                                () => context.go('/learn'),
                              ),
                              const SizedBox(height: 24),
                              _buildSignOutButton(),
                              const SizedBox(height: 16),
                              _buildAboutSection(),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.6),
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
                  Icons.info_outline,
                  color: AppTheme.cyberCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'About PrivFed',
                style: TextStyle(
                  color: AppTheme.glowWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'PrivFed Project',
            style: TextStyle(
              color: AppTheme.glowWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Privacy-Preserving Federated Learning for Fraud Detection across multiple financial institutions.',
            style: TextStyle(
              color: AppTheme.glowWhite.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Build', '2024.1.1'),
          _buildInfoRow('License', 'MIT'),
          _buildInfoRow('Repository', 'github.com/privfed'),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Team',
            style: TextStyle(
              color: AppTheme.glowWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTeamMember('Dr. Sarah Chen', 'Lead Research Scientist', 'Federated Learning & Privacy', AppTheme.electricBlue),
          const SizedBox(height: 12),
          _buildTeamMember('Alex Rodriguez', 'Senior ML Engineer', 'Differential Privacy Implementation', AppTheme.cyberCyan),
          const SizedBox(height: 12),
          _buildTeamMember('Dr. Michael Kim', 'Security Architect', 'Cryptographic Protocols', AppTheme.privacyPurple),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.glowWhite.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.cyberCyan,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String role, String expertise, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.glowWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expertise,
                  style: TextStyle(
                    color: AppTheme.glowWhite.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApiServerSection(BuildContext context) {
    return Consumer2<AppState, ApiService>(
      builder: (context, appState, apiService, _) {
        final currentOverride = appState.settings.apiBaseUrlOverride;
        final effectiveUrl = currentOverride ?? ApiConfig.platformDefaultUrl;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A).withOpacity(0.6),
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
                      Icons.api,
                      color: AppTheme.cyberCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'API Server',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Auth :3000 | AI :8000. Physical: http://YOUR_IP:8000/api',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<ApiService>(
                builder: (context, api, _) {
                  final authMs = api.authLatencyMs;
                  final aiMs = api.aiLatencyMs;
                  return Text(
                    'Latency 3000: ${authMs?.toString() ?? '–'} ms | 8000: ${aiMs?.toString() ?? '–'} ms',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: effectiveUrl,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.cyberCyan.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final url = _apiUrlController.text.trim();
                        if (url.isEmpty) return;
                        await appState.updateSettings(
                          appState.settings.copyWith(apiBaseUrlOverride: url),
                        );
                        await apiService.updateBaseUrl(url);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(apiService.isConnected
                                  ? 'Connected to PrivFed Backend'
                                  : 'Saved. Connection failed - check URL and backend.'),
                              backgroundColor: apiService.isConnected
                                  ? AppTheme.neuralGreen
                                  : AppTheme.warningAmber,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save, color: AppTheme.cyberCyan, size: 18),
                      label: const Text('Save & Connect', style: TextStyle(color: AppTheme.cyberCyan)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      _apiUrlController.clear();
                      await appState.updateSettings(
                        appState.settings.copyWith(apiBaseUrlOverride: null),
                      );
                      await apiService.updateBaseUrl(null);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(apiService.isConnected
                                ? 'Using default: ${ApiConfig.platformDefaultUrl}'
                                : 'Reverted to default. Check backend.'),
                            backgroundColor: apiService.isConnected
                                ? AppTheme.neuralGreen
                                : AppTheme.warningAmber,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, color: AppTheme.electricBlue, size: 18),
                    label: const Text('Use Default', style: TextStyle(color: AppTheme.electricBlue)),
                  ),
                ],
              ),
              if (apiService.connectionStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    apiService.connectionStatus,
                    style: TextStyle(
                      color: apiService.isConnected ? AppTheme.neuralGreen : AppTheme.warningAmber,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyEngineSection(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, _) {
        final metrics = apiService.privacyMetrics;
        final epsilon = metrics?.currentEpsilon ?? 8.0;
        final noise = metrics?.noiseMultiplier ?? 1.0;
        final enabled = epsilon > 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.privacyPurple.withOpacity(0.3),
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
                      color: AppTheme.privacyPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: AppTheme.privacyPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Privacy Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Differential Privacy',
                enabled ? 'Enabled' : 'Disabled',
              ),
              _buildInfoRow(
                'Noise Multiplier',
                noise.toStringAsFixed(2),
              ),
              _buildInfoRow(
                'Epsilon (ε)',
                epsilon.toStringAsFixed(1),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyAuditSection() {
    return Consumer<ApiService>(
      builder: (context, apiService, _) {
        final entries = apiService.privacyAuditLog;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neuralGreen.withOpacity(0.3),
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
                      color: AppTheme.neuralGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_clock,
                      color: AppTheme.neuralGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Privacy Audit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Text(
                  'No recent prediction requests logged.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            e,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighPrivacyModeToggle(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.privacyPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.privacyPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  color: AppTheme.privacyPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'High Privacy Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use Differential Privacy model (Config 4) for fraud predictions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: appState.settings.highPrivacyMode,
                onChanged: (value) async {
                  await appState.updateSettings(
                    appState.settings.copyWith(highPrivacyMode: value),
                  );
                },
                activeTrackColor: AppTheme.privacyPurple.withOpacity(0.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.glowWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.glowWhite.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.dangerRed.withOpacity(0.3),
            AppTheme.plasmaOrange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dangerRed.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1A1F3A),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppTheme.glowWhite),
                ),
                content: const Text(
                  'Are you sure you want to sign out?',
                  style: TextStyle(color: AppTheme.glowWhite),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.glowWhite.withOpacity(0.7)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to login screen
                      context.go('/login');
                    },
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppTheme.dangerRed),
                    ),
                  ),
                ],
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: AppTheme.dangerRed,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}