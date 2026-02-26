// Core Data Models for PrivFed App

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

class BankData {
  final String id;
  final String name;
  final String subtitle;
  final String color;
  final String icon;
  final BankMetrics metrics;
  final int samples;
  final double fraudRate;
  final String timeRange;

  BankData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.metrics,
    required this.samples,
    required this.fraudRate,
    required this.timeRange,
  });

  factory BankData.fromJson(Map<String, dynamic> json) {
    return BankData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      color: json['color'] ?? 'blue',
      icon: json['icon'] ?? 'building',
      metrics: BankMetrics.fromJson(json['metrics'] ?? {}),
      samples: json['samples'] ?? 0,
      fraudRate: (json['fraud_rate'] ?? 0.0).toDouble(),
      timeRange: json['time_range'] ?? '',
    );
  }
}

class BankMetrics {
  final double auc;
  final double accuracy;
  final double precision;
  final double recall;
  final double f1;
  final String? bankId;
  final int? numSamples;
  final double? fraudRate;
  final double? loss;
  final DateTime? timestamp;

  BankMetrics({
    required this.auc,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1,
    this.bankId,
    this.numSamples,
    this.fraudRate,
    this.loss,
    this.timestamp,
  });

  factory BankMetrics.fromJson(Map<String, dynamic> json) {
    return BankMetrics(
      auc: (json['auc'] ?? 0.0).toDouble(),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      precision: (json['precision'] ?? 0.0).toDouble(),
      recall: (json['recall'] ?? 0.0).toDouble(),
      f1: (json['f1'] ?? 0.0).toDouble(),
      bankId: json['bank_id'],
      numSamples: json['num_samples'],
      fraudRate: json['fraud_rate']?.toDouble(),
      loss: json['loss']?.toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
    );
  }
}

class TrainingRound {
  final int round;
  final BankMetrics globalMetrics;
  final Map<String, BankMetrics> clientMetrics;
  final PrivacyMetrics? privacyMetrics;
  final DateTime timestamp;
  final double? duration;

  TrainingRound({
    required this.round,
    required this.globalMetrics,
    required this.clientMetrics,
    this.privacyMetrics,
    required this.timestamp,
    this.duration,
  });

  factory TrainingRound.fromJson(Map<String, dynamic> json) {
    final clientMetricsMap = <String, BankMetrics>{};
    // Backend may send bank_metrics or client_metrics
    final clientData = json['bank_metrics'] ?? json['client_metrics'] ?? {};
    
    for (final entry in clientData.entries) {
      clientMetricsMap[entry.key.toString()] = BankMetrics.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    return TrainingRound(
      round: json['round'] ?? 0,
      globalMetrics: BankMetrics.fromJson(json['global_metrics'] ?? {}),
      clientMetrics: clientMetricsMap,
      privacyMetrics: json['privacy_metrics'] != null 
          ? PrivacyMetrics.fromJson(json['privacy_metrics'])
          : null,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      duration: json['duration']?.toDouble(),
    );
  }
}

class PrivacyMetrics {
  final double currentEpsilon;
  final double targetEpsilon;
  final double delta;
  final double noiseMultiplier;
  final String privacyStrength;
  final double budgetUsedPercentage;

  PrivacyMetrics({
    required this.currentEpsilon,
    required this.targetEpsilon,
    required this.delta,
    required this.noiseMultiplier,
    required this.privacyStrength,
    required this.budgetUsedPercentage,
  });

  factory PrivacyMetrics.fromJson(Map<String, dynamic> json) {
    return PrivacyMetrics(
      currentEpsilon: (json['current_epsilon'] ?? 0.0).toDouble(),
      targetEpsilon: (json['target_epsilon'] ?? 8.0).toDouble(),
      delta: (json['delta'] ?? 1e-5).toDouble(),
      noiseMultiplier: (json['noise_multiplier'] ?? 1.1).toDouble(),
      privacyStrength: json['privacy_strength'] ?? 'Strong',
      budgetUsedPercentage: (json['budget_used_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class FraudTransaction {
  final String id;
  final double amount;
  final DateTime timestamp;
  final double fraudProbability;
  final String riskLevel;
  final Map<String, dynamic> features;
  final List<String> riskFactors;
  final Map<String, double> bankPredictions;
  /// Model used for prediction (from Model Router: config_4_dp, config_5_global_champion, config_8_bank_c_specialist)
  final String? modelType;
  /// Raw explanation from API (includes model_type, bank_id, privacy_mode)
  final Map<String, dynamic>? explanation;

  FraudTransaction({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.fraudProbability,
    required this.riskLevel,
    required this.features,
    required this.riskFactors,
    required this.bankPredictions,
    this.modelType,
    this.explanation,
  });

  factory FraudTransaction.fromJson(Map<String, dynamic> json) {
    final explanation = json['explanation'] is Map
        ? Map<String, dynamic>.from(json['explanation'] as Map)
        : null;
    return FraudTransaction(
      id: json['id'] ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      amount: (json['amount'] ?? (json['transaction_features']?['amount'] ?? json['transaction_features']?['TransactionAmt']) ?? 0.0).toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      fraudProbability: (json['fraud_probability'] ?? 0.0).toDouble(),
      riskLevel: json['risk_level'] ?? 'Low',
      features: json['features'] ?? json['transaction_features'] ?? {},
      riskFactors: List<String>.from(json['risk_factors'] ?? []),
      bankPredictions: Map<String, double>.from(
        (json['bank_predictions'] ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0.0).toDouble()),
        ),
      ),
      modelType: explanation?['model_type'] as String?,
      explanation: explanation,
    );
  }

  bool get isHighRisk => fraudProbability > 0.7;
  bool get isMediumRisk => fraudProbability > 0.3 && fraudProbability <= 0.7;
  bool get isLowRisk => fraudProbability <= 0.3;
}

class SystemStatus {
  final String trainingStatus;
  final int currentRound;
  final int totalRounds;
  final int participatingBanks;
  final bool privacyEnabled;
  final DateTime lastUpdate;
  final String mode; // 'live', 'simulation', 'replay', 'offline'

  SystemStatus({
    required this.trainingStatus,
    required this.currentRound,
    required this.totalRounds,
    required this.participatingBanks,
    required this.privacyEnabled,
    required this.lastUpdate,
    required this.mode,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      trainingStatus: json['training_status'] ?? 'not_started',
      currentRound: json['current_round'] ?? 0,
      totalRounds: json['total_rounds'] ?? 50,
      participatingBanks: json['participating_banks'] ?? 3,
      privacyEnabled: json['privacy_enabled'] ?? false,
      lastUpdate: DateTime.tryParse(json['last_update'] ?? '') ?? DateTime.now(),
      mode: json['mode'] ?? 'simulation',
    );
  }

  bool get isTraining => trainingStatus == 'running';
  bool get isCompleted => trainingStatus == 'completed';
  double get progress => totalRounds > 0 ? currentRound / totalRounds : 0.0;
}

class ModelComparison {
  final String name;
  final BankMetrics metrics;
  final String privacyLevel;
  final Duration trainingTime;
  final int rank;

  ModelComparison({
    required this.name,
    required this.metrics,
    required this.privacyLevel,
    required this.trainingTime,
    required this.rank,
  });

  factory ModelComparison.fromJson(Map<String, dynamic> json) {
    return ModelComparison(
      name: json['name'] ?? '',
      metrics: BankMetrics.fromJson(json['metrics'] ?? {}),
      privacyLevel: json['privacy_level'] ?? 'None',
      trainingTime: Duration(seconds: json['training_time_seconds'] ?? 0),
      rank: json['rank'] ?? 0,
    );
  }
}

class AppSettings {
  final bool highContrastMode;
  final bool reducedMotion;
  final double textScale;
  final bool hapticFeedback;
  final String userMode; // 'public' or 'admin'
  final bool demoMode;
  final bool judgeDemoMode;
  final bool screenReaderMode;
  /// Use Differential Privacy model (Config 4) for fraud predictions
  final bool highPrivacyMode;
  /// Override API base URL (for physical device: http://YOUR_PC_IP:8000/api)
  final String? apiBaseUrlOverride;

  AppSettings({
    this.highContrastMode = false,
    this.reducedMotion = false,
    this.textScale = 1.0,
    this.hapticFeedback = true,
    this.userMode = 'public',
    this.demoMode = false,
    this.judgeDemoMode = false,
    this.screenReaderMode = false,
    this.highPrivacyMode = false,
    this.apiBaseUrlOverride,
  });

  static const _undefined = Object();

  AppSettings copyWith({
    bool? highContrastMode,
    bool? reducedMotion,
    double? textScale,
    bool? hapticFeedback,
    String? userMode,
    bool? demoMode,
    bool? judgeDemoMode,
    bool? screenReaderMode,
    bool? highPrivacyMode,
    Object? apiBaseUrlOverride = _undefined,
  }) {
    return AppSettings(
      highContrastMode: highContrastMode ?? this.highContrastMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      textScale: textScale ?? this.textScale,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      userMode: userMode ?? this.userMode,
      demoMode: demoMode ?? this.demoMode,
      judgeDemoMode: judgeDemoMode ?? this.judgeDemoMode,
      screenReaderMode: screenReaderMode ?? this.screenReaderMode,
      highPrivacyMode: highPrivacyMode ?? this.highPrivacyMode,
      apiBaseUrlOverride: apiBaseUrlOverride == _undefined
          ? this.apiBaseUrlOverride
          : apiBaseUrlOverride as String?,
    );
  }
}

// Demo sequence for judge mode
class DemoStep {
  final String title;
  final String description;
  final Duration duration;
  final String screenRoute;
  final List<String> highlights;
  final String? voiceover;

  DemoStep({
    required this.title,
    required this.description,
    required this.duration,
    required this.screenRoute,
    required this.highlights,
    this.voiceover,
  });
}

class BankApplication {
  final String id;
  final String bankName;
  final String bankId;
  final String licenseNumber;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final DateTime submittedAt;
  final String status; // 'pending', 'approved', 'rejected'

  BankApplication({
    required this.id,
    required this.bankName,
    required this.bankId,
    required this.licenseNumber,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.submittedAt,
    required this.status,
  });
}