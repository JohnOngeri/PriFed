import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class ApiService extends ChangeNotifier {
  /// Auth (Node.js :3000) - login, signup, logout, refresh
  late final Dio _dioAuth;
  /// AI (FastAPI :8000) - fraud predict, metrics, health, etc.
  late final Dio _dioAi;
  
  bool _isConnected = false;
  String _connectionStatus = 'Connecting...';
  bool _authHealthy = false;
  bool _aiHealthy = false;
  DateTime? _lastSync;
  bool _isLoading = false;
  String? _error;
  PrivacyMetrics? _privacyMetrics;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser; // Store current user data including role
  final List<String> _privacyAuditLog = [];
  int? _authLatencyMs;
  int? _aiLatencyMs;

  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  bool get authHealthy => _authHealthy;
  bool get aiHealthy => _aiHealthy;
  DateTime? get lastSync => _lastSync;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PrivacyMetrics? get privacyMetrics => _privacyMetrics;
  bool get isAuthenticated => _accessToken != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userRole => _currentUser?['role'] as String?;
  bool get isAdmin => userRole == 'ADMIN' || userRole == 'BANK_ADMIN';
  List<String> get privacyAuditLog => List.unmodifiable(_privacyAuditLog);
  int? get authLatencyMs => _authLatencyMs;
  int? get aiLatencyMs => _aiLatencyMs;

  Dio _createDio(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  ApiService() {
    _dioAuth = _createDio(ApiConfig.authBaseUrl);
    _dioAi = _createDio(ApiConfig.aiBaseUrl);

    // Auth interceptor: add token + 401 retry (Auth backend only)
    _dioAuth.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          final originalRequest = error.requestOptions;
          if (originalRequest.headers['X-Retry'] == 'true') {
            handler.next(error);
            return;
          }
          try {
            final refreshResponse = await _dioAuth.post('/auth/refresh', data: {
              'refreshToken': _refreshToken,
            });
            final newTokens = refreshResponse.data;
            if (newTokens['accessToken'] != null) {
              await _saveTokens(newTokens['accessToken'], _refreshToken ?? '');
              originalRequest.headers['Authorization'] = 'Bearer ${newTokens['accessToken']}';
              originalRequest.headers['X-Retry'] = 'true';
              final response = await _dioAuth.fetch(originalRequest);
              handler.resolve(response);
              return;
            }
          } catch (refreshError) {
            await _clearTokens();
            _isConnected = false;
            _connectionStatus = 'Authentication expired';
            notifyListeners();
          }
        }
        handler.next(error);
      },
    ));

    // AI interceptor: add token for future protected routes
    _dioAi.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
    ));

    void logPrint(Object obj) {
      String logMessage = obj.toString();
      if (_accessToken != null) logMessage = logMessage.replaceAll(_accessToken!, '***TOKEN***');
      if (_refreshToken != null) logMessage = logMessage.replaceAll(_refreshToken!, '***REFRESH_TOKEN***');
      debugPrint(logMessage);
    }
    _dioAuth.interceptors.add(LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode, logPrint: logPrint));
    _dioAi.interceptors.add(LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode, logPrint: logPrint));

    _loadTokens();
    _checkConnection();
  }

  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      
      // Load user data if available
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        // Note: SharedPreferences doesn't support Map directly, so we'd need to use JSON
        // For now, we'll fetch user data on next login
      }
      
      if (_accessToken != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load tokens: $e');
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store user role for quick access
      if (user['role'] != null) {
        await prefs.setString('user_role', user['role'].toString());
      }
      // Store other user data as needed
      if (user['federationId'] != null) {
        await prefs.setString('user_federation_id', user['federationId'].toString());
      }
    } catch (e) {
      debugPrint('Failed to save user data: $e');
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save tokens: $e');
    }
  }

  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_role');
      await prefs.remove('user_federation_id');
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear tokens: $e');
    }
  }

  Future<void> _checkConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString('api_base_url');
      if (override != null && override.isNotEmpty) {
        ApiConfig.setOverride(override);
        _dioAuth.options.baseUrl = ApiConfig.authBaseUrl;
        _dioAi.options.baseUrl = ApiConfig.aiBaseUrl;
      }
      // FastAPI health (AI backend)
      final aiStart = DateTime.now();
      final aiResponse = await _dioAi.get('/health');
      _aiLatencyMs = DateTime.now().difference(aiStart).inMilliseconds;
      if (aiResponse.statusCode == 200) {
        _aiHealthy = true;
        _isConnected = true;
        _connectionStatus = 'Connected to PrivFed Backend';
        _lastSync = DateTime.now();
      } else {
        _aiHealthy = false;
      }

      // Node.js health (auth/backend API)
      try {
        final authStart = DateTime.now();
        final authResponse = await _dioAuth.get('/health');
        _authLatencyMs = DateTime.now().difference(authStart).inMilliseconds;
        _authHealthy = authResponse.statusCode == 200;
      } catch (_) {
        _authHealthy = false;
        _authLatencyMs = null;
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatus = 'Using Simulated Data';
      debugPrint('API connection failed: $e');
    }
    notifyListeners();
  }

  /// Update API base URL (e.g. for physical device: http://192.168.1.5:8000/api)
  /// Pass null to revert to platform default.
  Future<void> updateBaseUrl(String? url) async {
    if (url != null && url.trim().isEmpty) url = null;
    ApiConfig.setOverride(url);
    _dioAuth.options.baseUrl = ApiConfig.authBaseUrl;
    _dioAi.options.baseUrl = ApiConfig.aiBaseUrl;
    await _checkConnection();
  }

  // System Status
  Future<SystemStatus> getSystemStatus() async {
    try {
      if (!_isConnected) return _getMockSystemStatus();
      
      final response = await _dioAi.get('/status');
      return SystemStatus.fromJson(response.data);
    } catch (e) {
      debugPrint('Failed to get system status: $e');
      return _getMockSystemStatus();
    }
  }

  // Global Metrics
  Future<BankMetrics> getGlobalMetrics({int? roundNum}) async {
    try {
      if (!_isConnected) return _getMockGlobalMetrics();
      
      final response = await _dioAi.get('/metrics/global', 
        queryParameters: roundNum != null ? {'round_num': roundNum} : null);
      
      final metrics = response.data['metrics'];
      return BankMetrics.fromJson(metrics);
    } catch (e) {
      debugPrint('Failed to get global metrics: $e');
      return _getMockGlobalMetrics();
    }
  }

  // Bank Metrics
  Future<Map<String, BankMetrics>> getBankMetrics({int? roundNum}) async {
    try {
      if (!_isConnected) return _getMockBankMetrics();
      
      final response = await _dioAi.get('/metrics/banks',
        queryParameters: roundNum != null ? {'round_num': roundNum} : null);
      
      final bankMetricsData = response.data['bank_metrics'];
      final result = <String, BankMetrics>{};
      
      for (final entry in bankMetricsData.entries) {
        result[entry.key] = BankMetrics.fromJson(entry.value);
      }
      
      return result;
    } catch (e) {
      debugPrint('Failed to get bank metrics: $e');
      return _getMockBankMetrics();
    }
  }

  // Privacy Metrics
  Future<PrivacyMetrics> getPrivacyMetrics() async {
    try {
      if (!_isConnected) return _getMockPrivacyMetrics();
      
      final response = await _dioAi.get('/privacy');
      final privacyData = response.data['privacy_metrics'];
      return PrivacyMetrics.fromJson(privacyData);
    } catch (e) {
      debugPrint('Failed to get privacy metrics: $e');
      return _getMockPrivacyMetrics();
    }
  }

  // Training Rounds History
  Future<List<TrainingRound>> getTrainingRounds({int limit = 50, int offset = 0}) async {
    try {
      if (!_isConnected) return _getMockTrainingRounds();
      
      final response = await _dioAi.get('/rounds',
        queryParameters: {'limit': limit, 'offset': offset});
      
      final roundsData = response.data['rounds'] as List;
      return roundsData.map((r) => TrainingRound.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Failed to get training rounds: $e');
      return _getMockTrainingRounds();
    }
  }

  // Fraud Prediction
  /// [bankId] - User's bank (Bank_A, Bank_B, Bank_C) from logged-in context. Routes to specialist model for Bank_C.
  /// [highPrivacyMode] - Use DP model (Config 4) when true. Pass from settings.
  Future<FraudTransaction> predictFraud(
    Map<String, dynamic> transactionFeatures, {
    String? bankId,
    bool? highPrivacyMode,
  }) async {
    try {
      if (!_isConnected) return _getMockFraudPrediction();
      
      final body = <String, dynamic>{
        'transaction_features': transactionFeatures,
      };
      if (bankId != null && bankId.isNotEmpty) {
        body['bank_id'] = bankId;
      }
      if (highPrivacyMode != null) {
        body['high_privacy_mode'] = highPrivacyMode;
      }

      // Privacy audit: log masked feature vector for last few predictions
      final masked = <String, dynamic>{};
      transactionFeatures.forEach((key, value) {
        final lower = key.toLowerCase();
        if (lower == 'amount' ||
            lower == 'transactionamt' ||
            lower == 'hour' ||
            lower == 'day') {
          masked[key] = value;
        } else {
          masked[key] = '***MASKED***';
        }
      });
      final logEntry = '[PREDICT] Features: ${jsonEncode(masked)}';
      _privacyAuditLog.insert(0, logEntry);
      if (_privacyAuditLog.length > 5) {
        _privacyAuditLog.removeLast();
      }
      
      final response = await _dioAi.post('/fraud/predict', data: body);
      return FraudTransaction.fromJson(response.data);
    } catch (e) {
      debugPrint('Failed to predict fraud: $e');
      return _getMockFraudPrediction();
    }
  }

  /// Benchmark multiple models on the same transaction features (backend /fraud/benchmark).
  /// Returns map with keys e.g. config_5_global, config_4_dp, config_8_bank_c (double scores).
  Future<Map<String, dynamic>> benchmarkModels(Map<String, dynamic> transactionFeatures) async {
    try {
      if (!_isConnected) return _getMockBenchmarkResults();
      final response = await _dioAi.post(
        '/fraud/benchmark',
        data: {'transaction_features': transactionFeatures},
      );
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : _getMockBenchmarkResults();
    } catch (e) {
      debugPrint('Benchmark failed: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _getMockBenchmarkResults() {
    return {
      'config_5_global': 0.48,
      'config_4_dp': 0.51,
      'config_8_bank_c': 0.49,
      'local_baseline': 0.52,
    };
  }

  /// Resolve bank_id in API format (Bank_A, Bank_B, Bank_C) from user/context
  String? get bankIdForPredict {
    final bank = _currentUser?['bankId'] ?? _currentUser?['bank_id'];
    if (bank == null) return null;
    final s = bank.toString().trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == 'bank_a' || lower == 'banka') return 'Bank_A';
    if (lower == 'bank_b' || lower == 'bankb') return 'Bank_B';
    if (lower == 'bank_c' || lower == 'bankc') return 'Bank_C';
    return s.length > 1 ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s.toUpperCase();
  }

  // Dataset Info
  Future<Map<String, dynamic>> getDatasetInfo() async {
    try {
      if (!_isConnected) return _getMockDatasetInfo();
      
      final response = await _dioAi.get('/dataset/info');
      return response.data;
    } catch (e) {
      debugPrint('Failed to get dataset info: $e');
      return _getMockDatasetInfo();
    }
  }

  // Fairness Analysis
  Future<Map<String, dynamic>> getFairnessAnalysis() async {
    try {
      if (!_isConnected) return _getMockFairnessAnalysis();
      
      final response = await _dioAi.get('/analytics/fairness');
      return response.data;
    } catch (e) {
      debugPrint('Failed to get fairness analysis: $e');
      return _getMockFairnessAnalysis();
    }
  }

  /// Technical audit sample for Research Verdict (training history, hyperparameters, model repo).
  /// Returns null on failure so UI can show fallback.
  Future<Map<String, dynamic>?> getTechnicalAudit() async {
    try {
      final response = await _dioAi.get('/audit');
      if (response.data is Map<String, dynamic>) return response.data;
      return null;
    } catch (e) {
      debugPrint('Failed to get technical audit: $e');
      return null;
    }
  }

  // Mock Data Methods (for offline/demo mode)
  SystemStatus _getMockSystemStatus() {
    return SystemStatus(
      trainingStatus: 'running',
      currentRound: 47,
      totalRounds: 100,
      participatingBanks: 3,
      privacyEnabled: true,
      lastUpdate: DateTime.now(),
      mode: 'simulation',
    );
  }

  BankMetrics _getMockGlobalMetrics() {
    return BankMetrics(
      auc: 0.962,
      accuracy: 0.948,
      precision: 0.943,
      recall: 0.950,
      f1: 0.946,
    );
  }

  Map<String, BankMetrics> _getMockBankMetrics() {
    return {
      'bank_a': BankMetrics(auc: 0.958, accuracy: 0.942, precision: 0.938, recall: 0.945, f1: 0.941),
      'bank_b': BankMetrics(auc: 0.963, accuracy: 0.948, precision: 0.944, recall: 0.951, f1: 0.947),
      'bank_c': BankMetrics(auc: 0.965, accuracy: 0.951, precision: 0.947, recall: 0.954, f1: 0.950),
    };
  }

  PrivacyMetrics _getMockPrivacyMetrics() {
    return PrivacyMetrics(
      currentEpsilon: 8.0,
      targetEpsilon: 8.0,
      delta: 1e-5,
      noiseMultiplier: 1.1,
      privacyStrength: 'Strong',
      budgetUsedPercentage: 85.2,
    );
  }

  List<TrainingRound> _getMockTrainingRounds() {
    return List.generate(47, (index) {
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
          'bank_a': BankMetrics(auc: baseAuc + 0.005, accuracy: baseAuc - 0.025, precision: baseAuc - 0.015, recall: baseAuc - 0.02, f1: baseAuc - 0.017),
          'bank_b': BankMetrics(auc: baseAuc + 0.008, accuracy: baseAuc - 0.018, precision: baseAuc - 0.008, recall: baseAuc - 0.012, f1: baseAuc - 0.01),
          'bank_c': BankMetrics(auc: baseAuc + 0.01, accuracy: baseAuc - 0.015, precision: baseAuc - 0.005, recall: baseAuc - 0.008, f1: baseAuc - 0.007),
        },
        timestamp: DateTime.now().subtract(Duration(hours: 47 - round)),
      );
    });
  }

  FraudTransaction _getMockFraudPrediction() {
    return FraudTransaction(
      id: 'TXN_847293',
      amount: 4532.89,
      timestamp: DateTime.now(),
      fraudProbability: 0.947,
      riskLevel: 'High',
      features: {
        'card_present': false,
        'location': 'Lagos, Nigeria',
        'device': 'iPhone 12',
        'merchant_category': 'Online Retail',
      },
      riskFactors: ['Unusual amount', 'Foreign transaction', 'New device', 'High-risk merchant'],
      bankPredictions: {
        'bank_a': 0.962,
        'bank_b': 0.938,
        'bank_c': 0.941,
      },
    );
  }

  Map<String, dynamic> _getMockDatasetInfo() {
    return {
      'dataset_name': 'IEEE-CIS Fraud Detection',
      'total_samples': 590540,
      'fraud_samples': 20663,
      'safe_samples': 569877,
      'fraud_rate': 0.035,
      'features_count': 433,
    };
  }

  Map<String, dynamic> _getMockFairnessAnalysis() {
    return {
      'fairness_score': 0.92,
      'auc_variance': 0.0012,
      'max_auc_difference': 0.007,
      'assessment': 'Excellent',
    };
  }

  // Retry connection
  Future<void> retryConnection() async {
    _connectionStatus = 'Reconnecting...';
    notifyListeners();
    await _checkConnection();
  }

  // Simulate real-time updates
  void startRealTimeUpdates() {
    // In a real app, this would establish WebSocket connection
    // For demo, we'll simulate periodic updates
  }

  void stopRealTimeUpdates() {
    // Stop WebSocket connection
  }
  
  // Missing methods that screens are calling
  Future<void> testConnection() async {
    await _checkConnection();
  }
  
  Future<void> refreshDashboardData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<TrainingRound>> getRoundsHistory({int limit = 50}) async {
    return getTrainingRounds(limit: limit);
  }
  
  Future<PrivacyMetrics> fetchPrivacyMetrics() async {
    final metrics = await getPrivacyMetrics();
    _privacyMetrics = metrics;
    notifyListeners();
    return metrics;
  }
  
  Future<BankMetrics> fetchGlobalMetrics() async {
    return getGlobalMetrics();
  }
  
  Future<Map<String, BankMetrics>> fetchBankMetrics() async {
    return getBankMetrics();
  }

  // ============================================
  // AUTHENTICATION METHODS
  // ============================================

  /// Login with Federation ID and passcode
  Future<Map<String, dynamic>> login(String federationId, String passcode) async {
    try {
      final response = await _dioAuth.post('/auth/login', data: {
        'federationId': federationId,
        'passcode': passcode,
      });
      
      final tokens = response.data['tokens'];
      final user = response.data['user'];
      
      if (tokens != null && tokens['accessToken'] != null) {
        await _saveTokens(tokens['accessToken'], tokens['refreshToken'] ?? '');
      }
      
      // Store current user data including role
      if (user != null) {
        _currentUser = Map<String, dynamic>.from(user);
        await _saveUserData(_currentUser!);
      }
      
      _isConnected = true;
      _connectionStatus = 'Connected to PrivFed Backend';
      _lastSync = DateTime.now();
      notifyListeners();
      
      return {
        'success': true,
        'user': user,
        'tokens': tokens,
      };
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Login failed';
      debugPrint('Login error: $errorMessage');
      _error = errorMessage;
      notifyListeners();
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Login error: $e');
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': 'Login failed: $e',
      };
    }
  }

  /// Signup (create new account)
  /// Federation ID is auto-generated by backend and returned in response
  Future<Map<String, dynamic>> signup({
    required String email,
    required String passcode,
    String? bankName,
    String? bankId,
  }) async {
    try {
      final response = await _dioAuth.post('/auth/signup', data: {
        'email': email,
        'passcode': passcode,
        if (bankName != null) 'bankName': bankName,
        if (bankId != null) 'bankId': bankId,
      });
      
      final tokens = response.data['tokens'];
      final user = response.data['user'];
      final federationId = response.data['federationId'] ?? user?['federationId'];
      
      if (tokens != null && tokens['accessToken'] != null) {
        await _saveTokens(tokens['accessToken'], tokens['refreshToken'] ?? '');
      }
      
      // Store current user data including role
      if (user != null) {
        _currentUser = Map<String, dynamic>.from(user);
        await _saveUserData(_currentUser!);
      }
      
      _isConnected = true;
      _connectionStatus = 'Connected to PrivFed Backend';
      _lastSync = DateTime.now();
      notifyListeners();
      
      return {
        'success': true,
        'user': user,
        'tokens': tokens,
        'federationId': federationId,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Signup failed';
      debugPrint('Signup error: $errorMessage');
      _error = errorMessage;
      notifyListeners();
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Signup error: $e');
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': 'Signup failed: $e',
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _dioAuth.post('/auth/logout');
      }
    } catch (e) {
      debugPrint('Logout error (non-critical): $e');
    } finally {
      await _clearTokens();
      _isConnected = false;
      _connectionStatus = 'Disconnected';
      notifyListeners();
    }
  }

  /// Forgot Password - Request password reset email
  Future<Map<String, dynamic>> forgotPassword({String? email, String? federationId}) async {
    try {
      final response = await _dioAuth.post('/auth/forgot-password', data: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (federationId != null && federationId.isNotEmpty) 'federationId': federationId,
      });
      
      return {
        'success': true,
        'message': response.data['message'] ?? 'Password reset email sent',
      };
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Failed to send password reset email';
      debugPrint('Forgot password error: $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return {
        'success': false,
        'error': 'Failed to send password reset email: $e',
      };
    }
  }

  /// Reset Password - Reset password using token
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dioAuth.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      
      return {
        'success': true,
        'message': response.data['message'] ?? 'Password reset successfully',
      };
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Failed to reset password';
      debugPrint('Reset password error: $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Reset password error: $e');
      return {
        'success': false,
        'error': 'Failed to reset password: $e',
      };
    }
  }
}