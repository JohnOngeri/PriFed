/// Platform-specific API config for mobile/desktop (uses dart:io)
/// Parallel ports: Auth (Node) = 3000, AI (FastAPI) = 8000
import 'dart:io';

String getHost() {
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}

String getDefaultAuthBaseUrl() => 'http://${getHost()}:3000/api';
String getDefaultAiBaseUrl() => 'http://${getHost()}:8000/api';

/// Legacy - returns AI URL
String getDefaultBaseUrl() => getDefaultAiBaseUrl();
