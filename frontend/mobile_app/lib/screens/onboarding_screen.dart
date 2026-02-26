import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

// Conditional imports for web vs mobile
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'ui_web_stub.dart' if (dart.library.html) 'dart:ui_web' as ui_web;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _videoError = false;
  bool _videoRenderError = false;
  bool _videoDisabled = false; // Flag to completely disable video
  html.VideoElement? _webVideoElement;
  String? _videoViewId;
  
  // Check if we should disable video (only as last resort after errors)
  bool get _shouldDisableVideo {
    // Only disable if we've encountered rendering errors
    return _videoRenderError;
  }

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize Video Background IMMEDIATELY (don't await)
    _initializeVideo();

    // 2. Pulse Animation for Diagram
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
          _videoViewId = 'video_${DateTime.now().millisecondsSinceEpoch}';
          _webVideoElement = html.VideoElement()
            ..src = 'assets/videos/Video_Generation_for_Onboarding_Splash.mp4'
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

          // Wait for video to load
          _webVideoElement!.onLoadedData.listen((_) {
            if (mounted) {
              setState(() {});
            }
          });

          // Start playing
          _webVideoElement!.play();

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('Web video initialization error: $e');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        }
      } else {
        // For mobile/desktop, use video_player - START IMMEDIATELY
        debugPrint('Initializing video player for onboarding...');
        _videoController = VideoPlayerController.asset(
          'assets/videos/Video_Generation_for_Onboarding_Splash.mp4',
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
              // Configure video settings
              _videoController!.setLooping(true);
              _videoController!.setVolume(0);
              
              // Add listener before playing
              _videoController!.addListener(_videoListener);
              
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
              // Update state to show video
              if (mounted) {
                setState(() {});
              }
            }).catchError((e) {
              debugPrint('Error playing video: $e');
              if (mounted) {
                setState(() {
                  _videoError = true;
                });
              }
            });
            
            // Update state immediately to show video widget
            if (mounted) {
              setState(() {});
            }
            } else {
              debugPrint('Video has invalid dimensions: ${size.width}x${size.height}');
              if (mounted) {
                setState(() {
                  _videoError = true;
                });
              }
            }
          }
        }).catchError((e) {
          debugPrint('Video initialization error: $e');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && 
        mounted && 
        _videoController!.value.isInitialized) {
      // Ensure video keeps looping
      if (_videoController!.value.position >= _videoController!.value.duration &&
          !_videoController!.value.isLooping) {
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
      // If video stops unexpectedly, restart it
      if (!_videoController!.value.isPlaying && 
          !_videoController!.value.isBuffering &&
          _videoController!.value.position < _videoController!.value.duration) {
        _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    // CRITICAL: Stop and dispose video IMMEDIATELY to prevent rendering during navigation
    // This must happen synchronously before the widget is removed from tree
    debugPrint('OnboardingScreen dispose: stopping video');
    
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
          // Remove listener first to prevent callbacks during disposal
          _videoController!.removeListener(_videoListener);
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
    
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND VIDEO LAYER - Show immediately
          if (_videoDisabled)
            // Fallback gradient background when video is disabled
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
          else if (!_videoError)
            Container(
              color: const Color(0xFF0A192F),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF64FFDA),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF0A192F),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Color(0xFF64FFDA),
                  size: 64,
                ),
              ),
            ),

          // LIGHTER OVERLAY FOR READABILITY (reduced opacity so video is more visible)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),

          // UI LAYER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const Spacer(),

                  // MIDDLE SECTION: TEXT LEFT, DIAGRAM RIGHT
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;
                      if (isSmallScreen) {
                        // Stack vertically on small screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroText(),
                            const SizedBox(height: 12),
                            _buildSubText(),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: CollaborationPainter(
                                      pulse: _pulseAnimation.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      // Side by side on larger screens
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // TEXT BLOCK (Left)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeroText(),
                                const SizedBox(height: 12),
                                _buildSubText(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // NETWORK DIAGRAM (Right/Centered Right)
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 200,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: CollaborationPainter(
                                      pulse: _pulseAnimation.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // BOTTOM ACTIONS
                  _buildActionButton(),
                  const SizedBox(height: 12),
                  _buildPrivacyLink(),
                  const SizedBox(height: 20),
                  _buildBottomMetricsRow(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text('PrivFed', 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Flexible(
          child: _buildStatusIndicator(),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: const BoxDecoration(
            color: Color(0xFF64FFDA), 
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              'Network Secure', 
              style: TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return const Text(
      'Collaborative\nIntelligence.\nAbsolute Privacy.',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }

  Widget _buildSubText() {
    return Text(
      'Train smarter models without sharing data.',
      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF64FFDA), Color(0xFF48CAE4)]),
        borderRadius: BorderRadius.circular(12),
      ),
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text('[ Initialize Local Node ]', 
          style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPrivacyLink() {
    return const Text(
      'View Privacy Protocol (ε = 0.5)',
      style: TextStyle(color: Color(0xFF64FFDA), decoration: TextDecoration.underline, fontSize: 12),
    );
  }

  Widget _buildBottomMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _metricTile('Accuracy', '94%'),
        ),
        Expanded(
          child: _metricTile('Privacy', 'DP-SGD'),
        ),
        Expanded(
          child: _metricTile('Lift', '+4.2%'),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label, 
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          val, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Network Diagram Painter - More visible with brighter colors
class CollaborationPainter extends CustomPainter {
  final double pulse;
  CollaborationPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Connection lines - brighter and more visible
    final connectionPaint = Paint()
      ..color = const Color(0xFF64FFDA).withOpacity(0.7 + pulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Node positions around center
    final nodes = [
      Offset(center.dx - 50, center.dy - 50),
      Offset(center.dx + 50, center.dy - 50),
      Offset(center.dx - 50, center.dy + 50),
      Offset(center.dx + 50, center.dy + 50),
    ];

    // Draw connection lines with glow effect
    for (var node in nodes) {
      // Outer glow
      final glowPaint = Paint()
        ..color = const Color(0xFF64FFDA).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(center, node, glowPaint);
      
      // Main line
      canvas.drawLine(center, node, connectionPaint);
      
      // Animated dots along the line
      final dotCount = 3;
      for (int i = 0; i < dotCount; i++) {
        final t = (i / (dotCount + 1)) + (pulse * 0.3);
        if (t > 1.0) continue;
        final dotX = center.dx + (node.dx - center.dx) * t;
        final dotY = center.dy + (node.dy - center.dy) * t;
        final dotPaint = Paint()
          ..color = const Color(0xFF64FFDA).withOpacity(0.9 + pulse * 0.1)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
      }
    }

    // Draw peripheral nodes (banks)
    final nodePaint = Paint()
      ..color = const Color(0xFF64FFDA).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFF64FFDA).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var node in nodes) {
      // Glow around node
      final nodeGlow = Paint()
        ..color = const Color(0xFF64FFDA).withOpacity(0.3 + pulse * 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(node, 12, nodeGlow);
      
      // Node circle
      canvas.drawCircle(node, 10, nodePaint);
      canvas.drawCircle(node, 10, nodeBorderPaint);
    }

    // Central Global Model node - brighter and more prominent
    final centerGlow = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.4 + pulse * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, 20 + (pulse * 8), centerGlow);
    
    final centerPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, centerPaint);
    
    final centerBorder = Paint()
      ..color = const Color(0xFF64FFDA).withOpacity(1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 18, centerBorder);
    
    // Inner glow
    final innerGlow = Paint()
      ..color = const Color(0xFF64FFDA).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, innerGlow);
  }

  @override
  bool shouldRepaint(CollaborationPainter oldDelegate) => 
      oldDelegate.pulse != pulse;
}