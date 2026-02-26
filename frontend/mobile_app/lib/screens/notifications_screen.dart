import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/futuristic_visuals.dart';
import '../components/animated_background.dart';
import '../providers/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
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
          AnimatedBackground(child: Container()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Consumer<AppState>(
                    builder: (context, appState, child) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (appState.pendingApplications.isNotEmpty) ...[
                              _buildPendingApplications(appState),
                              const SizedBox(height: 20),
                            ],
                            _buildNotificationsList(appState),
                          ],
                        ),
                      );
                    },
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
            onPressed: () => context.go('/dashboard'),
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
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'Federation Updates & Applications',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Consumer<AppState>(
            builder: (context, appState, child) {
              return HolographicButton(
                onPressed: () => appState.clearNotifications(),
                child: const Icon(Icons.clear_all, color: Colors.white70),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApplications(AppState appState) {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Bank Applications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Decentralized Voting Required (2/3 majority)',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...appState.pendingApplications.map((app) => _buildApplicationCard(app, appState)),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(dynamic app, AppState appState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cyberCyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business, color: AppTheme.cyberCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.bankName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${app.bankId} • License: ${app.licenseNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contact: ${app.contactEmail}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            'Address: ${app.address}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _voteOnApplication(app.id, true, appState),
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: const Text('Vote Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neuralGreen.withOpacity(0.2),
                    foregroundColor: AppTheme.neuralGreen,
                    side: BorderSide(color: AppTheme.neuralGreen.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _voteOnApplication(app.id, false, appState),
                  icon: const Icon(Icons.thumb_down, size: 16),
                  label: const Text('Vote Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed.withOpacity(0.2),
                    foregroundColor: AppTheme.dangerRed,
                    side: BorderSide(color: AppTheme.dangerRed.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(AppState appState) {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (appState.notifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            ...appState.notifications.map((notification) => _buildNotificationItem(notification)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String notification) {
    IconData icon = Icons.info;
    Color color = AppTheme.cyberCyan;
    
    if (notification.contains('joined')) {
      icon = Icons.add_circle;
      color = AppTheme.neuralGreen;
    } else if (notification.contains('rejected')) {
      icon = Icons.cancel;
      color = AppTheme.dangerRed;
    } else if (notification.contains('application')) {
      icon = Icons.business;
      color = AppTheme.electricBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            'now',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _voteOnApplication(String applicationId, bool approve, AppState appState) {
    appState.voteOnApplication(applicationId, approve);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Vote cast: Approve' : 'Vote cast: Reject'),
        backgroundColor: approve ? AppTheme.neuralGreen : AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}