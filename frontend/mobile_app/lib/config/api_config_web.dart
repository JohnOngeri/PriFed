/// Platform-specific API config for web
/// Parallel ports: Auth (Node) = 3000, AI (FastAPI) = 8000
String getHost() => 'localhost';

String getDefaultAuthBaseUrl() => 'http://localhost:3000/api';
String getDefaultAiBaseUrl() => 'http://localhost:8000/api';

String getDefaultBaseUrl() => getDefaultAiBaseUrl();
