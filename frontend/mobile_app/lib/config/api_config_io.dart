/// Platform-specific API config for mobile/desktop (uses dart:io)
/// Parallel ports: Auth (Node) = 3000, AI (FastAPI) = 8000
import 'dart:io';

// ─── SET YOUR PC's LAN IP HERE ───────────────────────────────────────────────
// Run `ipconfig` on Windows and use the IPv4 address (e.g. 192.168.1.5)
// This is needed for real Android devices. Emulators use 10.0.2.2 automatically.
const String _lanIp = '10.110.11.178'; // <-- CHANGE THIS TO YOUR PC's IP
// ─────────────────────────────────────────────────────────────────────────────

String getHost() {
  if (Platform.isAndroid) {
    // 10.0.2.2 only works on emulator; real devices need the LAN IP
    return _lanIp;
  }
  return 'localhost';
}

String getDefaultAuthBaseUrl() => 'http://${getHost()}:3000/api';
String getDefaultAiBaseUrl() => 'http://${getHost()}:8000/api';

/// Legacy - returns AI URL
String getDefaultBaseUrl() => getDefaultAiBaseUrl();
