import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/api_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Subtle gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0E1A), Color(0xFF0D1528), Color(0xFF0A0E1A)],
                ),
              ),
            ),
          ),
          // Accent glow top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyberCyan.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConnectionStatus(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('SYSTEM'),
                        const SizedBox(height: 10),
                        _buildHighPrivacyToggle(),
                        const SizedBox(height: 8),
                        _buildNavTile(
                          icon: Icons.security_outlined,
                          color: AppTheme.privacyPurple,
                          title: 'Privacy Settings',
                          subtitle: 'Differential privacy configuration',
                          onTap: () => context.go('/privacy-shield'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavTile(
                          icon: Icons.tune_outlined,
                          color: AppTheme.electricBlue,
                          title: 'Training Parameters',
                          subtitle: 'Federated learning configuration',
                          onTap: () {},
                        ),
                        const SizedBox(height: 24),
                        _buildSectionLabel('NETWORK'),
                        const SizedBox(height: 10),
                        _buildApiSection(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('PRIVACY'),
                        const SizedBox(height: 10),
                        _buildPrivacyMetrics(),
                        const SizedBox(height: 8),
                        _buildPrivacyAudit(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('MORE'),
                        const SizedBox(height: 10),
                        _buildNavTile(
                          icon: Icons.school_outlined,
                          color: AppTheme.electricBlue,
                          title: 'Learn More',
                          subtitle: 'Educational content and tutorials',
                          onTap: () => context.go('/learn'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavTile(
                          icon: Icons.backup_outlined,
                          color: AppTheme.warningAmber,
                          title: 'Export & Backup',
                          subtitle: 'Data export and backup options',
                          onTap: () {},
                        ),
                        const SizedBox(height: 24),
                        _buildAboutCard(),
                        const SizedBox(height: 16),
                        _buildSignOutButton(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 4),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.cyberCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3)),
            ),
            child: const Text(
              'v1.0.0',
              style: TextStyle(color: AppTheme.cyberCyan, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        final connected = api.isConnected;
        final authOk = api.authHealthy;
        final aiOk = api.aiHealthy;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: connected
                ? AppTheme.neuralGreen.withOpacity(0.08)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: connected
                  ? AppTheme.neuralGreen.withOpacity(0.25)
                  : Colors.red.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? AppTheme.neuralGreen : Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? AppTheme.neuralGreen : Colors.red).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected ? 'Backend Connected' : 'Not Connected',
                      style: TextStyle(
                        color: connected ? AppTheme.neuralGreen : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auth: ${authOk ? "✓" : "✗"}  AI: ${aiOk ? "✓" : "✗"}  '
                      '${api.authLatencyMs != null ? "${api.authLatencyMs}ms" : "–"}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => api.retryConnection(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('Retry', style: TextStyle(color: AppTheme.cyberCyan, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildHighPrivacyToggle() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final enabled = appState.settings.highPrivacyMode;
        return _buildTileContainer(
          borderColor: AppTheme.privacyPurple.withOpacity(enabled ? 0.4 : 0.15),
          child: Row(
            children: [
              _buildIconBox(Icons.privacy_tip_outlined, AppTheme.privacyPurple),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('High Privacy Mode',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Routes predictions through DP model (ε=8.0)',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (v) => appState.updateSettings(appState.settings.copyWith(highPrivacyMode: v)),
                activeColor: AppTheme.privacyPurple,
                activeTrackColor: AppTheme.privacyPurple.withOpacity(0.3),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildTileContainer(
        borderColor: color.withOpacity(0.15),
        child: Row(
          children: [
            _buildIconBox(icon, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.25), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSection() {
    return Consumer2<AppState, ApiService>(
      builder: (context, appState, apiService, _) {
        final effectiveUrl = appState.settings.apiBaseUrlOverride ?? ApiConfig.platformDefaultUrl;
        return _buildTileContainer(
          borderColor: AppTheme.cyberCyan.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBox(Icons.dns_outlined, AppTheme.cyberCyan),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('API Server',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _apiUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: effectiveUrl,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.cyberCyan, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallButton(
                      label: 'Save & Connect',
                      icon: Icons.save_outlined,
                      color: AppTheme.cyberCyan,
                      onTap: () async {
                        final url = _apiUrlController.text.trim();
                        if (url.isEmpty) return;
                        await appState.updateSettings(appState.settings.copyWith(apiBaseUrlOverride: url));
                        await apiService.updateBaseUrl(url);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(apiService.isConnected ? 'Connected!' : 'Saved. Check backend.'),
                            backgroundColor: apiService.isConnected ? AppTheme.neuralGreen : AppTheme.warningAmber,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallButton(
                      label: 'Use Default',
                      icon: Icons.refresh_outlined,
                      color: Colors.white38,
                      onTap: () async {
                        _apiUrlController.clear();
                        await appState.updateSettings(appState.settings.copyWith(apiBaseUrlOverride: null));
                        await apiService.updateBaseUrl(null);
                      },
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

  Widget _buildPrivacyMetrics() {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        final m = api.privacyMetrics;
        final epsilon = m?.currentEpsilon ?? 8.0;
        final noise = m?.noiseMultiplier ?? 1.1;
        final budget = m?.budgetUsedPercentage ?? 85.2;
        return _buildTileContainer(
          borderColor: AppTheme.privacyPurple.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBox(Icons.shield_outlined, AppTheme.privacyPurple),
                  const SizedBox(width: 14),
                  const Text('Privacy Engine',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMetricChip('ε = ${epsilon.toStringAsFixed(1)}', AppTheme.privacyPurple),
                  const SizedBox(width: 8),
                  _buildMetricChip('σ = ${noise.toStringAsFixed(2)}', AppTheme.electricBlue),
                  const SizedBox(width: 8),
                  _buildMetricChip('${budget.toStringAsFixed(0)}% used', AppTheme.warningAmber),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: budget / 100,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budget > 80 ? AppTheme.warningAmber : AppTheme.privacyPurple,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyAudit() {
    return Consumer<ApiService>(
      builder: (context, api, _) {
        final entries = api.privacyAuditLog;
        return _buildTileContainer(
          borderColor: AppTheme.neuralGreen.withOpacity(0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconBox(Icons.receipt_long_outlined, AppTheme.neuralGreen),
                  const SizedBox(width: 14),
                  const Text('Privacy Audit Log',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Text('No recent prediction requests.',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))
              else
                ...entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(e,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return _buildTileContainer(
      borderColor: Colors.white.withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconBox(Icons.info_outline, AppTheme.cyberCyan),
              const SizedBox(width: 14),
              const Text('About PrivFed',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Privacy-Preserving Federated Learning for Fraud Detection across multiple financial institutions.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('License', 'MIT'),
          _buildInfoRow('Author', 'John Ongeri Ouma'),
          _buildInfoRow('Repository', 'github.com/JohnOngeri/PriFed'),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white.withOpacity(0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/login');
              },
              child: const Text('Sign Out', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppTheme.dangerRed, size: 18),
            SizedBox(width: 8),
            Text('Sign Out',
                style: TextStyle(color: AppTheme.dangerRed, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildTileContainer({required Widget child, required Color borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          Text(value,
              style: const TextStyle(color: AppTheme.cyberCyan, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
