import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // Theme and Accessibility
  ThemeMode _themeMode = ThemeMode.dark;
  AppSettings _settings = AppSettings();
  
  // System State
  SystemStatus _systemStatus = SystemStatus(
    trainingStatus: 'simulation',
    currentRound: 47,
    totalRounds: 100,
    participatingBanks: 3,
    privacyEnabled: true,
    lastUpdate: DateTime.now(),
    mode: 'simulation',
  );

  // Training Data
  List<TrainingRound> _trainingRounds = [];
  PrivacyMetrics _privacyMetrics = PrivacyMetrics(
    currentEpsilon: 8.0,
    targetEpsilon: 8.0,
    delta: 1e-5,
    noiseMultiplier: 1.1,
    privacyStrength: 'Strong',
    budgetUsedPercentage: 85.2,
  );

  // Banks Data
  List<BankData> _banks = [
    BankData(
      id: 'bank_a',
      name: 'Bank A',
      subtitle: 'The Pioneer',
      color: 'blue',
      icon: 'building_modern',
      metrics: BankMetrics(auc: 0.958, accuracy: 0.942, precision: 0.938, recall: 0.945, f1: 0.941),
      samples: 45231,
      fraudRate: 0.032,
      timeRange: 'Jan-Apr 2024',
    ),
    BankData(
      id: 'bank_b',
      name: 'Bank B',
      subtitle: 'The Guardian',
      color: 'green',
      icon: 'building_classical',
      metrics: BankMetrics(auc: 0.963, accuracy: 0.948, precision: 0.944, recall: 0.951, f1: 0.947),
      samples: 38947,
      fraudRate: 0.028,
      timeRange: 'May-Aug 2024',
    ),
    BankData(
      id: 'bank_c',
      name: 'Bank C',
      subtitle: 'The Innovator',
      color: 'purple',
      icon: 'building_futuristic',
      metrics: BankMetrics(auc: 0.965, accuracy: 0.951, precision: 0.947, recall: 0.954, f1: 0.950),
      samples: 42156,
      fraudRate: 0.035,
      timeRange: 'Sep-Dec 2024',
    ),
  ];

  // Fraud Transactions
  List<FraudTransaction> _fraudTransactions = [];

  // Demo Mode
  bool _isDemoMode = false;
  bool _isJudgeDemoRunning = false;
  int _currentDemoStep = 0;
  
  // Authentication
  bool _isAuthenticated = false;
  String? _currentBank;
  
  // Accessibility
  String _accessibilityAnnouncement = '';
  
  // System Status
  String _systemMode = 'simulation'; // 'live', 'simulation', 'replay', 'offline'
  
  // Loading and Error States
  bool _isLoading = false;
  String? _errorMessage;
  
  // Training Status
  TrainingStatus _trainingStatus = TrainingStatus.running;
  bool _autoRefreshEnabled = true;
  
  // Additional computed properties
  bool _hasData = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  AppSettings get settings => _settings;
  SystemStatus get systemStatus => _systemStatus;
  List<TrainingRound> get trainingRounds => _trainingRounds;
  PrivacyMetrics get privacyMetrics => _privacyMetrics;
  List<BankData> get banks => _banks;
  List<FraudTransaction> get fraudTransactions => _fraudTransactions;
  bool get isDemoMode => _isDemoMode;
  bool get isJudgeDemoRunning => _isJudgeDemoRunning;
  int get currentDemoStep => _currentDemoStep;
  String get accessibilityAnnouncement => _accessibilityAnnouncement;
  String get systemMode => _systemMode;
  
  // Additional getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TrainingStatus get trainingStatus => _trainingStatus;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  bool get hasData => _hasData;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentBank => _currentBank;
  
  // Training progress getters
  int get currentRound => _systemStatus.currentRound;
  int get totalRounds => _systemStatus.totalRounds;
  double get trainingProgress => _systemStatus.currentRound / _systemStatus.totalRounds;
  
  // Status text getter
  String get statusText {
    switch (_trainingStatus) {
      case TrainingStatus.idle:
        return 'Ready to start';
      case TrainingStatus.running:
        return 'Training in progress';
      case TrainingStatus.completed:
        return 'Training completed';
      case TrainingStatus.paused:
        return 'Training paused';
      case TrainingStatus.error:
        return 'Training error';
    }
  }
  
  // Privacy level getters
  String get privacyLevelDescription {
    final epsilon = _privacyMetrics.currentEpsilon;
    if (epsilon <= 1.0) return 'Maximum Privacy';
    if (epsilon <= 3.0) return 'High Privacy';
    if (epsilon <= 8.0) return 'Balanced Privacy';
    if (epsilon <= 15.0) return 'Moderate Privacy';
    return 'Low Privacy';
  }
  
  Color get privacyLevelColor {
    final epsilon = _privacyMetrics.currentEpsilon;
    if (epsilon <= 1.0) return const Color(0xFF4CAF50); // Green
    if (epsilon <= 3.0) return const Color(0xFF8BC34A); // Light Green
    if (epsilon <= 8.0) return const Color(0xFFFF9800); // Orange
    if (epsilon <= 15.0) return const Color(0xFFFF5722); // Deep Orange
    return const Color(0xFFF44336); // Red
  }
  
  // Bank metrics getter
  List<BankMetrics> get bankMetrics => _banks.map((b) => b.metrics).toList();
  
  // Fairness score getter
  double get fairnessScore => getFairnessScore();
  
  // Accessibility helpers
  bool get isHighContrast => _settings.highContrastMode;
  bool get isReducedMotion => _settings.reducedMotion;
  bool get isScreenReaderMode => _settings.screenReaderMode;
  double get textScaleFactor => _settings.textScale;

  // Global metrics computed from banks
  BankMetrics get globalMetrics {
    if (_banks.isEmpty) return BankMetrics(auc: 0, accuracy: 0, precision: 0, recall: 0, f1: 0);
    
    final avgAuc = _banks.map((b) => b.metrics.auc).reduce((a, b) => a + b) / _banks.length;
    final avgAcc = _banks.map((b) => b.metrics.accuracy).reduce((a, b) => a + b) / _banks.length;
    final avgPrec = _banks.map((b) => b.metrics.precision).reduce((a, b) => a + b) / _banks.length;
    final avgRec = _banks.map((b) => b.metrics.recall).reduce((a, b) => a + b) / _banks.length;
    final avgF1 = _banks.map((b) => b.metrics.f1).reduce((a, b) => a + b) / _banks.length;
    
    return BankMetrics(auc: avgAuc, accuracy: avgAcc, precision: avgPrec, recall: avgRec, f1: avgF1);
  }

  AppState() {
    _loadSettings();
    _generateMockData();
  }

  // Settings Management
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _settings = AppSettings(
      highContrastMode: prefs.getBool('high_contrast') ?? false,
      reducedMotion: prefs.getBool('reduced_motion') ?? false,
      textScale: prefs.getDouble('text_scale') ?? 1.0,
      hapticFeedback: prefs.getBool('haptic_feedback') ?? true,
      userMode: prefs.getString('user_mode') ?? 'public',
      demoMode: prefs.getBool('demo_mode') ?? false,
      judgeDemoMode: prefs.getBool('judge_demo_mode') ?? false,
      screenReaderMode: prefs.getBool('screen_reader_mode') ?? false,
      highPrivacyMode: prefs.getBool('high_privacy_mode') ?? false,
      apiBaseUrlOverride: prefs.getString('api_base_url'),
    );
    
    _themeMode = _settings.highContrastMode ? ThemeMode.dark : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', newSettings.highContrastMode);
    await prefs.setBool('reduced_motion', newSettings.reducedMotion);
    await prefs.setDouble('text_scale', newSettings.textScale);
    await prefs.setBool('haptic_feedback', newSettings.hapticFeedback);
    await prefs.setString('user_mode', newSettings.userMode);
    await prefs.setBool('demo_mode', newSettings.demoMode);
    await prefs.setBool('judge_demo_mode', newSettings.judgeDemoMode);
    await prefs.setBool('screen_reader_mode', newSettings.screenReaderMode);
    await prefs.setBool('high_privacy_mode', newSettings.highPrivacyMode);
    if (newSettings.apiBaseUrlOverride != null) {
      await prefs.setString('api_base_url', newSettings.apiBaseUrlOverride!);
    } else {
      await prefs.remove('api_base_url');
    }
    
    _themeMode = newSettings.highContrastMode ? ThemeMode.dark : ThemeMode.dark;
    notifyListeners();
  }

  // Haptic Feedback
  void triggerHaptic(HapticFeedbackType type) {
    if (_settings.hapticFeedback) {
      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
      }
    }
  }

  // Demo Mode Management
  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    notifyListeners();
  }

  void startJudgeDemo() {
    _isJudgeDemoRunning = true;
    _currentDemoStep = 0;
    notifyListeners();
  }

  void stopJudgeDemo() {
    _isJudgeDemoRunning = false;
    _currentDemoStep = 0;
    notifyListeners();
  }

  void nextDemoStep() {
    if (_isJudgeDemoRunning) {
      _currentDemoStep++;
      notifyListeners();
    }
  }
  
  // Accessibility Methods
  void announceForAccessibility(String message) {
    _accessibilityAnnouncement = message;
    notifyListeners();
    // Clear after announcement
    Future.delayed(const Duration(milliseconds: 100), () {
      _accessibilityAnnouncement = '';
      notifyListeners();
    });
  }
  
  void setSystemMode(String mode) {
    _systemMode = mode;
    notifyListeners();
  }
  
  // Judge Demo Sequence
  void startJudgeDemoSequence() async {
    _isJudgeDemoRunning = true;
    _currentDemoStep = 0;
    notifyListeners();
    
    // 3-minute automated demo sequence
    await _runDemoSequence();
  }
  
  Future<void> _runDemoSequence() async {
    // Introduction (0:00-0:15)
    announceForAccessibility('Starting PrivFed demonstration. Privacy-preserving federated fraud detection.');
    await Future.delayed(const Duration(seconds: 15));
    
    // Problem demonstration (0:15-0:45)
    _currentDemoStep = 1;
    announceForAccessibility('Demonstrating fraud detection challenges across multiple banks.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 30));
    
    // Federated Learning (0:45-1:15)
    _currentDemoStep = 2;
    announceForAccessibility('Banks collaborate through federated learning while keeping data private.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 30));
    
    // Privacy Shield (1:15-1:45)
    _currentDemoStep = 3;
    announceForAccessibility('Differential privacy with epsilon equals 8.0 provides strong protection.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 30));
    
    // Performance Comparison (1:45-2:15)
    _currentDemoStep = 4;
    announceForAccessibility('Federated learning with differential privacy achieves best balance.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 30));
    
    // Real-World Impact (2:15-2:45)
    _currentDemoStep = 5;
    announceForAccessibility('97.2% detection rate with less than 0.1% false positives.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 30));
    
    // Conclusion (2:45-3:00)
    _currentDemoStep = 6;
    announceForAccessibility('Demo complete. PrivFed: Secure, Federated, Intelligent.');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 15));
    
    stopJudgeDemo();
  }

  // System Status Updates
  void updateSystemStatus(SystemStatus status) {
    _systemStatus = status;
    notifyListeners();
  }

  void updatePrivacyMetrics(PrivacyMetrics metrics) {
    _privacyMetrics = metrics;
    notifyListeners();
  }

  // Training Progress Simulation
  void simulateTrainingProgress() {
    if (_systemStatus.currentRound < _systemStatus.totalRounds) {
      _systemStatus = SystemStatus(
        trainingStatus: 'running',
        currentRound: _systemStatus.currentRound + 1,
        totalRounds: _systemStatus.totalRounds,
        participatingBanks: _systemStatus.participatingBanks,
        privacyEnabled: _systemStatus.privacyEnabled,
        lastUpdate: DateTime.now(),
        mode: _systemStatus.mode,
      );
      
      // Update privacy budget
      _privacyMetrics = PrivacyMetrics(
        currentEpsilon: _privacyMetrics.currentEpsilon + 0.08,
        targetEpsilon: _privacyMetrics.targetEpsilon,
        delta: _privacyMetrics.delta,
        noiseMultiplier: _privacyMetrics.noiseMultiplier,
        privacyStrength: _getPrivacyStrength(_privacyMetrics.currentEpsilon + 0.08),
        budgetUsedPercentage: ((_privacyMetrics.currentEpsilon + 0.08) / _privacyMetrics.targetEpsilon) * 100,
      );
      
      notifyListeners();
    }
  }

  String _getPrivacyStrength(double epsilon) {
    if (epsilon <= 1.0) return 'Very Strong';
    if (epsilon <= 3.0) return 'Strong';
    if (epsilon <= 8.0) return 'Moderate';
    if (epsilon <= 15.0) return 'Weak';
    return 'Very Weak';
  }

  // Mock Data Generation
  void _generateMockData() {
    // Generate training rounds
    _trainingRounds = List.generate(47, (index) {
      final round = index + 1;
      final baseAuc = 0.85 + (round * 0.002);
      
      return TrainingRound(
        round: round,
        globalMetrics: BankMetrics(
          auc: baseAuc + (0.01 * (index % 3)),
          accuracy: baseAuc - 0.02,
          precision: baseAuc - 0.01,
          recall: baseAuc - 0.015,
          f1: baseAuc - 0.012,
        ),
        clientMetrics: {
          'bank_a': BankMetrics(
            auc: baseAuc + (0.005 * (index % 2)),
            accuracy: baseAuc - 0.025,
            precision: baseAuc - 0.015,
            recall: baseAuc - 0.02,
            f1: baseAuc - 0.017,
          ),
          'bank_b': BankMetrics(
            auc: baseAuc + (0.008 * (index % 3)),
            accuracy: baseAuc - 0.018,
            precision: baseAuc - 0.008,
            recall: baseAuc - 0.012,
            f1: baseAuc - 0.01,
          ),
          'bank_c': BankMetrics(
            auc: baseAuc + (0.01 * (index % 2)),
            accuracy: baseAuc - 0.015,
            precision: baseAuc - 0.005,
            recall: baseAuc - 0.008,
            f1: baseAuc - 0.007,
          ),
        },
        timestamp: DateTime.now().subtract(Duration(hours: 47 - round)),
      );
    });

    // Generate fraud transactions
    _fraudTransactions = List.generate(20, (index) {
      final riskLevels = ['High', 'Medium', 'Low'];
      final riskLevel = riskLevels[index % 3];
      final fraudProb = riskLevel == 'High' ? 0.85 + (index % 10) * 0.01 
                      : riskLevel == 'Medium' ? 0.45 + (index % 10) * 0.02
                      : 0.15 + (index % 10) * 0.01;

      return FraudTransaction(
        id: 'TXN_${847293 + index}',
        amount: 1000 + (index * 234.56),
        timestamp: DateTime.now().subtract(Duration(hours: index)),
        fraudProbability: fraudProb,
        riskLevel: riskLevel,
        features: {
          'card_present': index % 2 == 0,
          'location': index % 3 == 0 ? 'Lagos, Nigeria' : 'New York, USA',
          'device': 'iPhone ${12 + (index % 3)}',
          'merchant_category': 'Online Retail',
        },
        riskFactors: riskLevel == 'High' 
          ? ['Unusual amount', 'Foreign transaction', 'New device', 'High-risk merchant']
          : riskLevel == 'Medium'
          ? ['Unusual time', 'New merchant']
          : [],
        bankPredictions: {
          'bank_a': fraudProb + 0.02,
          'bank_b': fraudProb - 0.01,
          'bank_c': fraudProb + 0.005,
        },
      );
    });
  }

  // Utility Methods
  double getFairnessScore() {
    if (_banks.length < 2) return 1.0;
    
    final aucs = _banks.map((b) => b.metrics.auc).toList();
    final variance = _calculateVariance(aucs);
    return 1.0 - variance; // Lower variance = higher fairness
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  List<FraudTransaction> getHighRiskTransactions() {
    return _fraudTransactions.where((t) => t.isHighRisk).toList();
  }

  int getTotalTransactionsToday() => 12847;
  int getFraudsDetectedToday() => 243;
  double getDetectionAccuracy() => 96.2;
  
  // Missing methods that screens are calling
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> refreshAllData() async {
    setLoading(true);
    try {
      // Simulate data refresh
      await Future.delayed(const Duration(seconds: 1));
      _generateMockData();
      clearError();
    } catch (e) {
      setError('Failed to refresh data: $e');
    } finally {
      setLoading(false);
    }
  }
  
  void updateGlobalMetrics(BankMetrics metrics) {
    // Update global metrics if needed
    notifyListeners();
  }
  
  void updateBankMetrics(Map<String, BankMetrics> metrics) {
    // Update bank metrics if needed
    notifyListeners();
  }
  
  void startAutoRefresh() {
    _autoRefreshEnabled = true;
    notifyListeners();
  }
  
  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    notifyListeners();
  }
  
  void updateTrainingStatus(TrainingStatus status) {
    _trainingStatus = status;
    notifyListeners();
  }
  
  void reset() {
    _trainingStatus = TrainingStatus.idle;
    _systemStatus = SystemStatus(
      trainingStatus: 'idle',
      currentRound: 0,
      totalRounds: 100,
      participatingBanks: 3,
      privacyEnabled: true,
      lastUpdate: DateTime.now(),
      mode: 'simulation',
    );
    notifyListeners();
  }
  
  // Authentication methods
  void signIn(String bankId) {
    _isAuthenticated = true;
    _currentBank = bankId;
    notifyListeners();
  }
  
  void signOut() {
    _isAuthenticated = false;
    _currentBank = null;
    notifyListeners();
  }
  
  // Bank management methods
  void addNewBank(String name, String id) {
    final colors = ['blue', 'green', 'purple', 'cyan', 'pink'];
    final newBank = BankData(
      id: id.toLowerCase().replaceAll(' ', '_'),
      name: name,
      subtitle: 'New Member',
      color: colors[_banks.length % colors.length],
      icon: 'building_modern',
      metrics: BankMetrics(auc: 0.85, accuracy: 0.82, precision: 0.80, recall: 0.84, f1: 0.82),
      samples: 15000 + (_banks.length * 5000),
      fraudRate: 0.025 + (_banks.length * 0.005),
      timeRange: 'New',
    );
    
    _banks.add(newBank);
    _systemStatus = SystemStatus(
      trainingStatus: _systemStatus.trainingStatus,
      currentRound: _systemStatus.currentRound,
      totalRounds: _systemStatus.totalRounds,
      participatingBanks: _banks.length,
      privacyEnabled: _systemStatus.privacyEnabled,
      lastUpdate: DateTime.now(),
      mode: _systemStatus.mode,
    );
    notifyListeners();
  }
  
  void removeBank(String bankId) {
    _banks.removeWhere((bank) => bank.id == bankId);
    _systemStatus = SystemStatus(
      trainingStatus: _systemStatus.trainingStatus,
      currentRound: _systemStatus.currentRound,
      totalRounds: _systemStatus.totalRounds,
      participatingBanks: _banks.length,
      privacyEnabled: _systemStatus.privacyEnabled,
      lastUpdate: DateTime.now(),
      mode: _systemStatus.mode,
    );
    notifyListeners();
  }
  
  // Decentralized bank application system
  List<BankApplication> _pendingApplications = [];
  List<String> _notifications = [];
  Map<String, Map<String, bool>> _votes = {}; // applicationId -> {bankId: vote}
  
  List<BankApplication> get pendingApplications => _pendingApplications;
  List<String> get notifications => _notifications;
  
  void submitBankApplication({
    required String bankName,
    required String bankId,
    required String licenseNumber,
    required String contactEmail,
    required String contactPhone,
    required String address,
  }) {
    final application = BankApplication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bankName: bankName,
      bankId: bankId,
      licenseNumber: licenseNumber,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      address: address,
      submittedAt: DateTime.now(),
      status: 'pending',
    );
    
    _pendingApplications.add(application);
    _addNotification('New bank application received from $bankName');
    notifyListeners();
  }
  
  // Decentralized voting system (like Bitcoin consensus)
  void voteOnApplication(String applicationId, bool approve) {
    if (!_votes.containsKey(applicationId)) {
      _votes[applicationId] = {};
    }
    
    // Current bank votes
    _votes[applicationId]![_currentBank ?? 'unknown'] = approve;
    
    // Check if we have 2/3 majority (decentralized consensus)
    final totalBanks = _banks.length;
    final votes = _votes[applicationId]!;
    final approveVotes = votes.values.where((v) => v).length;
    final rejectVotes = votes.values.where((v) => !v).length;
    
    // Need 2/3 majority to approve or reject
    final requiredVotes = (totalBanks * 2 / 3).ceil();
    
    if (approveVotes >= requiredVotes) {
      _approveApplication(applicationId);
    } else if (rejectVotes >= requiredVotes) {
      _rejectApplication(applicationId);
    } else {
      _addNotification('Vote recorded. Need ${requiredVotes - approveVotes} more approvals or ${requiredVotes - rejectVotes} more rejections.');
    }
    
    notifyListeners();
  }
  
  void _approveApplication(String applicationId) {
    final app = _pendingApplications.firstWhere((a) => a.id == applicationId);
    addNewBank(app.bankName, app.bankId);
    _pendingApplications.removeWhere((a) => a.id == applicationId);
    _votes.remove(applicationId);
    _addNotification('🎉 ${app.bankName} approved by consensus and joined the federation!');
  }
  
  void _rejectApplication(String applicationId) {
    final app = _pendingApplications.firstWhere((a) => a.id == applicationId);
    _pendingApplications.removeWhere((a) => a.id == applicationId);
    _votes.remove(applicationId);
    _addNotification('❌ Application from ${app.bankName} rejected by consensus');
  }
  
  void _addNotification(String message) {
    _notifications.insert(0, message);
    if (_notifications.length > 10) {
      _notifications.removeLast();
    }
  }
  
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}

// Training Status Enum
enum TrainingStatus {
  idle,
  running,
  completed,
  paused,
  error,
}