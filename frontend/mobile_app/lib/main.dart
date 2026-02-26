import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/api_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_dashboard.dart';
import 'screens/training_dashboard_cinematic.dart';
import 'screens/banks_cinematic.dart';
import 'screens/privacy_cinematic.dart';
import 'screens/fraud_explorer_cinematic.dart';
import 'screens/results_comparison_cinematic.dart';
import 'screens/learn_more_cinematic.dart';
import 'screens/settings_screen.dart';
import 'screens/live_demo_screen.dart';
import 'screens/login_screen.dart';
import 'screens/identity_initialization_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/privacy_protocol_screen.dart';
import 'screens/environment_scan_screen.dart';
import 'screens/data_link_screen.dart';
import 'screens/initial_sync_screen.dart';
import 'screens/bank_management_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/neural_network_architecture_screen.dart';
import 'screens/bank_hq_network_screen.dart';

// Throttle noisy layout/hit-test errors (overlay/MouseTracker) so they don't spam logs
// or trigger full-screen error overlays on desktop/web.
int _layoutHitTestErrorCount = 0;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handler to catch rendering errors (like texture mipmap issues)
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    // Overlay / MouseTracker can sometimes hit-test or paint routes before they
    // complete layout (size: MISSING / hasSize / RenderBox was not laid out).
    // Treat these as non-fatal so we don't show the red error screen.
    final isLayoutHitTestError = (
      msg.contains('Cannot hit test a render box with no size') ||
      msg.contains('RenderBox was not laid out') ||
      msg.contains("'hasSize'") ||
      msg.contains('size: MISSING') ||
      msg.contains('!_debugDuringDeviceUpdate')
    );
    if (isLayoutHitTestError) {
      // Only log the first few occurrences so the console stays readable.
      if (_layoutHitTestErrorCount < 3) {
        _layoutHitTestErrorCount++;
        debugPrint('Flutter layout/hit-test suppressed #$_layoutHitTestErrorCount: $msg');
      } else if (_layoutHitTestErrorCount == 3) {
        _layoutHitTestErrorCount++;
        debugPrint(
          'Flutter layout/hit-test suppressed: further similar errors are being muted.',
        );
      }
      return;
    }
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const PrivFedApp());
}

class PrivFedApp extends StatefulWidget {
  const PrivFedApp({super.key});

  @override
  State<PrivFedApp> createState() => _PrivFedAppState();
}

class _PrivFedAppState extends State<PrivFedApp> {
  @override
  void initState() {
    super.initState();
    // On web, request an extra frame so overlay entries get layout before hit-test.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SchedulerBinding.instance.scheduleFrame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            title: 'PrivFed',
            theme: AppTheme.lightTheme,
            darkTheme: appState.isHighContrast 
                ? AppTheme.highContrastTheme 
                : AppTheme.darkTheme,
            themeMode: appState.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Wraps route content so the route has an explicit size during layout.
/// Prevents Flutter Web hit-test errors when offstage routes (e.g. GoRouter)
/// are hit-tested before layout completes (size: MISSING).
Widget _sizedRoute(Widget child) => SizedBox.expand(child: child);

final GoRouter _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => _sizedRoute(const OnboardingScreen()),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => _sizedRoute(const LoginScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => _sizedRoute(const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return _sizedRoute(ResetPasswordScreen(token: token));
      },
    ),
    // Onboarding Flow - Step 1: Identity Initialization
    GoRoute(
      path: '/onboarding/identity',
      builder: (context, state) => _sizedRoute(const IdentityInitializationScreen()),
    ),
    // Onboarding Flow - Step 2: Privacy Protocol
    GoRoute(
      path: '/onboarding/privacy',
      builder: (context, state) {
        final nodeId = state.uri.queryParameters['nodeId'];
        return _sizedRoute(PrivacyProtocolScreen(nodeId: nodeId));
      },
    ),
    // Onboarding Flow - Step 3: Environment Scan
    GoRoute(
      path: '/onboarding/scan',
      builder: (context, state) {
        final nodeId = state.uri.queryParameters['nodeId'];
        final epsilon = state.uri.queryParameters['epsilon'];
        return _sizedRoute(EnvironmentScanScreen(nodeId: nodeId, epsilon: epsilon));
      },
    ),
    // Onboarding Flow - Step 4: Data Link
    GoRoute(
      path: '/onboarding/data-link',
      builder: (context, state) {
        final nodeId = state.uri.queryParameters['nodeId'];
        final epsilon = state.uri.queryParameters['epsilon'];
        return _sizedRoute(DataLinkScreen(nodeId: nodeId, epsilon: epsilon));
      },
    ),
    // Onboarding Flow - Step 5: Initial Sync
    GoRoute(
      path: '/onboarding/sync',
      builder: (context, state) {
        final nodeId = state.uri.queryParameters['nodeId'];
        final epsilon = state.uri.queryParameters['epsilon'];
        return _sizedRoute(InitialSyncScreen(nodeId: nodeId, epsilon: epsilon));
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => _sizedRoute(const MainDashboard()),
    ),
    GoRoute(
      path: '/training',
      builder: (context, state) => _sizedRoute(const TrainingDashboardCinematic()),
    ),
    GoRoute(
      path: '/banks',
      builder: (context, state) => _sizedRoute(const BanksCinematic()),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => _sizedRoute(const PrivacyCinematic()),
    ),
    GoRoute(
      path: '/fraud',
      builder: (context, state) => _sizedRoute(const FraudExplorerCinematic()),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => _sizedRoute(const ResultsComparisonCinematic()),
    ),
    GoRoute(
      path: '/learn',
      builder: (context, state) => _sizedRoute(const LearnMoreCinematic()),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => _sizedRoute(const SettingsScreen()),
    ),
    GoRoute(
      path: '/demo',
      builder: (context, state) => _sizedRoute(const LiveDemoScreen()),
    ),
    GoRoute(
      path: '/bank-management',
      builder: (context, state) => _sizedRoute(const BankManagementScreen()),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => _sizedRoute(const NotificationsScreen()),
    ),
    GoRoute(
      path: '/neural-network',
      builder: (context, state) => _sizedRoute(const NeuralNetworkArchitectureScreen()),
    ),
    GoRoute(
      path: '/bank-hq',
      builder: (context, state) => _sizedRoute(const BankHQNetworkScreen()),
    ),
  ],
);