import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/api_service.dart';
import 'package:video_player/video_player.dart';

// Conditional imports for web vs mobile
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'ui_web_stub.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  html.VideoElement? _webVideoElement;
  String? _videoViewId;
  bool _videoRenderError = false;
  bool _videoDisabled = false; // Flag to completely disable video
  late AnimationController _particleController;
  
  // Check if we should disable video (only as last resort after errors)
  bool get _shouldDisableVideo {
    // Only disable if we've encountered rendering errors
    return _videoRenderError;
  }
  
  // Controllers for authentication
  final TextEditingController _federationIdController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  bool _obscurePasscode = true;
  bool _isLoggingIn = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Cinematic Collaboration Video Background IMMEDIATELY
    _initializeVideo();

    // 2. Initialize Subtle Digital Particle Animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  Future<void> _initializeVideo() async {
    // Skip if already disabled due to errors
    if (_shouldDisableVideo) {
      if (mounted) {
        setState(() {
          _videoDisabled = true;
        });
      }
      return;
    }
    
    try {
      if (kIsWeb) {
        // For web, use HTML video element directly
        try {
          _videoViewId = 'login_video_${DateTime.now().millisecondsSinceEpoch}';
          _webVideoElement = html.VideoElement()
            ..src = 'assets/videos/Video_Generation_Global_and_Local_Models.mp4'
            ..autoplay = true
            ..loop = true
            ..muted = true
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover';

          // Register the video element with Flutter
          ui_web.platformViewRegistry.registerViewFactory(
            _videoViewId!,
            (int viewId) => _webVideoElement!,
          );

          // Start playing
          _webVideoElement!.play();

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('Web video initialization error: $e');
        }
      } else {
        // For mobile/desktop, use video_player - START IMMEDIATELY
        debugPrint('Initializing video player for login...');
        _videoController = VideoPlayerController.asset(
          'assets/videos/Video_Generation_Global_and_Local_Models.mp4',
        );
        
        // Update UI immediately to show video widget (even while loading)
        if (mounted) {
          setState(() {});
        }
        
        // Initialize and play asynchronously
        _videoController!.initialize().then((_) {
          debugPrint('Video initialized: ${_videoController!.value.isInitialized}');
          debugPrint('Video size: ${_videoController!.value.size}');
          debugPrint('Video duration: ${_videoController!.value.duration}');
          if (mounted && _videoController != null && _videoController!.value.isInitialized) {
            // Verify video has valid dimensions before proceeding
            final size = _videoController!.value.size;
            if (size.width > 0 && size.height > 0) {
              _videoController!.setLooping(true);
              _videoController!.setVolume(0);
              
            // Add comprehensive listener to track video state
            bool _loggedPlaying = false;
            _videoController!.addListener(() {
              final value = _videoController!.value;
              
              // Log video state changes (once when playback starts to avoid console spam)
              if (value.isPlaying && !_loggedPlaying) {
                _loggedPlaying = true;
                debugPrint('Video is playing');
              }
              if (value.hasError) {
                debugPrint('Video player error detected: ${value.errorDescription}');
                // On emulator, audio codec often fails (MediaCodecAudioRenderer); keep showing video (last frame)
                final desc = value.errorDescription ?? '';
                final isEmulatorAudioError = desc.contains('MediaCodecAudioRenderer') ||
                    desc.contains('ExoPlaybackException') ||
                    desc.contains('audio/mp4a');
                if (mounted && !isEmulatorAudioError) {
                  setState(() {
                    _videoRenderError = true;
                    _videoDisabled = true;
                  });
                }
              }
            });
              
              // Start playing immediately and ensure it keeps playing
              _videoController!.play().then((_) {
                debugPrint('Video started playing successfully');
                if (mounted) {
                  setState(() {});
                }
              }).catchError((e) {
                debugPrint('Error playing video: $e');
              });
              
              // Update state immediately to show video widget
              if (mounted) {
                setState(() {});
              }
            } else {
              debugPrint('Video has invalid dimensions: ${size.width}x${size.height}');
            }
          }
        }).catchError((e) {
          debugPrint('Video initialization error: $e');
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    // CRITICAL: Stop and dispose video IMMEDIATELY to prevent rendering during navigation
    // This must happen synchronously before the widget is removed from tree
    debugPrint('LoginScreen dispose: stopping video');
    
    if (kIsWeb) {
      try {
        if (_webVideoElement != null) {
          (_webVideoElement as html.VideoElement).pause();
          (_webVideoElement as html.VideoElement).src = '';
        }
        _webVideoElement = null;
        _videoViewId = null;
      } catch (e) {
        debugPrint('Error disposing web video: $e');
      }
    } else {
      try {
        if (_videoController != null) {
          // Pause immediately
          _videoController!.pause();
          // Dispose synchronously
          _videoController!.dispose();
          _videoController = null;
        }
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
    }
    
    // Mark video as disabled to prevent any further rendering attempts
    _videoDisabled = true;
    _videoRenderError = true;
    
    _particleController.dispose();
    _federationIdController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F), // Project theme navy
      body: Stack(
        children: [
          // LAYER A: CINEMATIC COLLABORATION VIDEO - Show immediately
          // CRITICAL: Only show video if widget is still mounted and video is not disabled
          if (_videoDisabled || !mounted)
            // Fallback gradient background when video is disabled or widget is disposing
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A192F),
                      const Color(0xFF112240),
                      const Color(0xFF0A192F),
                    ],
                  ),
                ),
              ),
            )
          else if (kIsWeb && _videoViewId != null && _webVideoElement != null)
            Positioned.fill(
              child: HtmlElementView(
                viewType: _videoViewId!,
              ),
            )
          else if (!kIsWeb && _videoController != null && !_videoRenderError && mounted)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  // CRITICAL: Double-check mounted and video state before rendering
                  if (!mounted || _videoDisabled || _videoRenderError) {
                    return Container(
                      color: const Color(0xFF0A192F),
                    );
                  }
                  
                  // Show video widget only if fully initialized and valid
                  if (_videoController != null &&
                      _videoController!.value.isInitialized && 
                      _videoController!.value.size.width > 0 && 
                      _videoController!.value.size.height > 0 &&
                      !_videoController!.value.hasError) {
                    return RepaintBoundary(
                      child: ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Show dark background while video loads or if there's an error
                    return Container(
                      color: const Color(0xFF0A192F),
                    );
                  }
                },
              ),
            )
          else
            Container(color: const Color(0xFF0A192F)),

          // LAYER B: GRADIENT OVERLAY FOR READABILITY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A192F).withOpacity(0.85), // Darker top for status bar
                    const Color(0xFF0A192F).withOpacity(0.60), // Lighter middle to show video
                    const Color(0xFF0A192F).withOpacity(0.90), // Heavy bottom for buttons
                  ],
                ),
              ),
            ),
          ),

          // LAYER C: ANIMATED PARTICLE OVERLAY
          Positioned.fill(
            child: CustomPaint(
              painter: ParticleBackgroundPainter(
                animation: _particleController,
              ),
            ),
          ),

          // LAYER D: MAIN UI CONTENT
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildWelcomeHeader(),
                    const SizedBox(height: 30),
                    _buildLoginCard(),
                    const SizedBox(height: 40),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                    _buildFooter(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildLogo() {
    return Column(
      children: [
        CustomPaint(
          size: const Size(70, 70),
          painter: HexagonLogoPainter(),
        ),
        const SizedBox(height: 12),
        const Text(
          'PrivFed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return const Column(
      children: [
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Re-authenticate to the Federated Network',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8892B0),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildInputField(
            controller: _federationIdController,
            hintText: 'Federation ID',
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passcodeController,
            hintText: 'Secure Passcode',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePasscode,
            suffixIcon: _obscurePasscode ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixTap: () => setState(() => _obscurePasscode = !_obscurePasscode),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
              context.push('/login/forgot-password');
              },
              child: Text(
                'Forgot ID/Passcode?',
                style: TextStyle(
                  color: AppTheme.cyberCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
          prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.6), size: 20),
          suffixIcon: suffixIcon != null 
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, color: Colors.white.withOpacity(0.6), size: 20),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary: Returning Member
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF64FFDA), Color(0xFF48CAE4)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: _isLoggingIn ? null : () => _handleLogin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoggingIn
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A192F)),
                    ),
                  )
                : const Text(
              'Access Secure Vault',
              style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        if (_loginError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text('OR', style: TextStyle(color: Color(0xFF8892B0), fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        // Secondary: New Member
        SizedBox(
          width: double.infinity,
          height: 56,
            child: OutlinedButton(
              onPressed: () => context.push('/login/signup'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF64FFDA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Join the Federation',
                style: TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Privacy Protected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          'DP-SGD Enabled',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final federationId = _federationIdController.text.trim();
    final passcode = _passcodeController.text.trim();

    // Validation
    if (federationId.isEmpty) {
      setState(() {
        _loginError = 'Please enter your Federation ID';
      });
      return;
    }

    if (passcode.isEmpty) {
      setState(() {
        _loginError = 'Please enter your passcode';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.login(federationId, passcode);

      if (!mounted) return;

      if (result['success'] == true) {
        // Login successful - navigate to dashboard
        context.go('/dashboard');
      } else {
        // Login failed - show error
        setState(() {
          _loginError = result['error'] ?? 'Login failed. Please check your credentials.';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = 'Login failed: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }
}

// --- Custom Painters ---

class ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  ParticleBackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF64FFDA).withOpacity(0.15);
    final random = math.Random(42);
    
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final yOffset = (animation.value * 200 * (random.nextDouble() + 0.5)) % size.height;
      final y = (random.nextDouble() * size.height + yOffset) % size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class HexagonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF64FFDA));
    
    final tp = TextPainter(
      text: const TextSpan(text: 'P', style: TextStyle(color: Color(0xFF0A192F), fontSize: 36, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}