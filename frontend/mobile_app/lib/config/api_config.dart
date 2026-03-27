/// API Configuration - Parallel Port Architecture
/// Auth (Node.js) = port 3000 | AI (FastAPI/ML) = port 8000
import 'api_config_io.dart' if (dart.library.html) 'api_config_web.dart' as platform;

class ApiConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: true);
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String? _overrideBaseUrl;
  static String? get overrideBaseUrl => _overrideBaseUrl;

  /// Parse host from override URL (e.g. http://192.168.1.5:8000/api -> 192.168.1.5)
  static String? _hostFromOverride(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : null;
    } catch (_) {
      return null;
    }
  }

  static void setOverride(String? url) {
    _overrideBaseUrl = (url != null && url.trim().isEmpty) ? null : url?.trim();
  }

  static String get authBaseUrl {
    if (_overrideBaseUrl != null) {
      final host = _hostFromOverride(_overrideBaseUrl!);
      if (host != null) return 'http://$host:3000/api';
    }
    if (isProduction) {
      return const String.fromEnvironment(
        'AUTH_BASE_URL',
        defaultValue: 'https://privfed-auth-node.onrender.com/api',
      );
    }
    final env = const String.fromEnvironment('AUTH_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return platform.getDefaultAuthBaseUrl();
  }

  static String get aiBaseUrl {
    if (_overrideBaseUrl != null) return _overrideBaseUrl!;
    if (isProduction) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://privfed-auth.onrender.com/api',
      );
    }
    final env = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return platform.getDefaultAiBaseUrl();
  }

  /// Legacy alias - AI URL
  static String get baseUrl => aiBaseUrl;

  static String get platformDefaultUrl => platform.getDefaultAiBaseUrl();

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
