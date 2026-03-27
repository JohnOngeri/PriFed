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
  bool _videoError = false;
  bool _videoRenderError = false;
  bool _videoDisabled = false;
  html.VideoElement? _webVideoElement;
  String? _videoViewId;

  bool get _shouldDisableVideo => _videoRenderError;

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize Video Background
    _initializeVideo();
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
        _webVideoElement?.pause();
        _webVideoElement?.src = '';
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const Spacer(),
                  _buildHeroText(),
                  const SizedBox(height: 16),
                  _buildSubText(),
                  const Spacer(),
                  _buildActionButton(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
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
      'Fraud detection\nthat respects\nprivacy.',
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubText() {
    return Text(
      'Multiple banks. One shared model.\nZero shared data.',
      style: TextStyle(
        color: Colors.white.withOpacity(0.65),
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.push('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64FFDA),
          foregroundColor: const Color(0xFF0A192F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}