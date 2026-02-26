import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/api_service.dart';

class IdentityInitializationScreen extends StatefulWidget {
  const IdentityInitializationScreen({super.key});

  @override
  State<IdentityInitializationScreen> createState() => _IdentityInitializationScreenState();
}

class _IdentityInitializationScreenState extends State<IdentityInitializationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _confirmPasscodeController = TextEditingController();
  
  // Form state
  bool _obscurePasscode = true;
  bool _obscureConfirmPasscode = true;
  bool _isSigningUp = false;
  String? _signupError;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passcodeController.dispose();
    _confirmPasscodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B18), // Deep Sentinel Navy
      body: Stack(
        children: [
          // 1. Cinematic Background (Skyscrapers - Center/Cover)
          Positioned.fill(
            child: kIsWeb
                ? Image.network(
                    '/assets/images/identity%20initialization.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackBackground();
                    },
                  )
                : Image.asset(
                    'assets/images/identity initialization.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackBackground();
                    },
                  ),
          ),

          // 2. Very Subtle Radial Gradient Overlay (Minimal darkening for text readability)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // 3. Animated Background Particles (Digital Rain) - Wrapped in RepaintBoundary
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: TechParticlePainter(animation: _controller)),
            ),
          ),

          // 4. Main UI Content (Centered)
          SafeArea(
            child: Stack(
              children: [
                // Back button at top - return to login screen
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    tooltip: 'Back',
                  ),
                ),
                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hexagon, color: Color(0xFF00E5FF), size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'PrivFed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Premium Glass Card (Fixed Width: 450px)
                        _buildGlassCard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return Container(
      width: 450, // Fixed width for premium look
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Subtle glowing cyan border
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.4),
          width: 1.5,
        ),
        // Outer glow effect
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Stronger blur for better text readability
            child: Container(
            decoration: BoxDecoration(
              // Completely transparent with subtle inner glow
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.02),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // High-contrast bold title with shadow for readability
                Text(
                  'Join the Federation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Muted metadata subtitle with shadow
                Text(
                  'Create your secure account',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Signup Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'your.email@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                ),
                      const SizedBox(height: 16),
                      
                      // Passcode Field
                      _buildInputField(
                        controller: _passcodeController,
                        label: 'Secure Passcode',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePasscode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasscode ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePasscode = !_obscurePasscode;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Passcode is required';
                          }
                          if (value.length < 8) {
                            return 'Must be at least 8 characters';
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                            return 'Must contain uppercase, lowercase, and number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm Passcode Field
                      _buildInputField(
                        controller: _confirmPasscodeController,
                        label: 'Confirm Passcode',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscureConfirmPasscode,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPasscode ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPasscode = !_obscureConfirmPasscode;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your passcode';
                          }
                          if (value != _passcodeController.text) {
                            return 'Passcodes do not match';
                          }
                          return null;
                        },
                      ),
                      
                      // Error Message
                      if (_signupError != null) ...[
                        const SizedBox(height: 16),
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
                                  _signupError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                      ),
                    ],
                  ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Signup Button
                      _buildSignupButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 4,
                offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(prefixIcon, color: Colors.white70, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
            ),
                ),
              ),
            ],
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isSigningUp ? null : () => _handleSignup(context),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _isSigningUp ? Colors.grey : const Color(0xFF00E5FF),
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isSigningUp ? null : [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _isSigningUp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF030B18)),
                    ),
                  )
                : const Text(
                    '[Join the Federation]',
              style: TextStyle(
                color: Color(0xFF030B18),
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFederationIdDialog(BuildContext context, String federationId) async {
    bool hasConfirmed = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false, // User must confirm
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A192F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 2),
        ),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFC107), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Save Your Federation ID',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Prominently displayed Federation ID
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF64FFDA)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'YOUR FEDERATION ID',
                            style: TextStyle(
                              color: Color(0xFF0A192F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                    ),
                  ),
                          const SizedBox(height: 12),
                          Text(
                            federationId,
                            style: const TextStyle(
                              color: Color(0xFF0A192F),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                      fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Warning message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'This ID cannot be recovered',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                      ],
                    ),
                          SizedBox(height: 8),
                          Text(
                            '• You need this ID to log in\n• It\'s required for federated learning\n• Store it securely',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
                    const SizedBox(height: 20),
                    // Confirmation checkbox
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1),
                      ),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'I have saved my Federation ID securely',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        value: hasConfirmed,
                        activeColor: const Color(0xFF00E5FF),
                        checkColor: const Color(0xFF0A192F),
                        onChanged: (value) {
                          setDialogState(() {
                            hasConfirmed = value ?? false;
                          });
                        },
                      ),
            ),
          ],
        ),
      ),
              actions: [
                TextButton(
                  onPressed: hasConfirmed
                      ? () {
                          Navigator.of(dialogContext).pop();
                          if (context.mounted) {
                            context.go('/onboarding/privacy?nodeId=$federationId');
                          }
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5FF),
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSignup(BuildContext context) async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSigningUp = true;
      _signupError = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.signup(
        email: _emailController.text.trim(),
        passcode: _passcodeController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Signup successful - show Federation ID dialog
        final federationId = result['federationId'] ?? result['user']?['federationId'];
        if (federationId != null) {
          await _showFederationIdDialog(context, federationId);
        } else {
          // Fallback if Federation ID is missing
          context.go('/onboarding/privacy');
        }
      } else {
        // Signup failed - show error
        setState(() {
          _signupError = result['error'] ?? 'Signup failed. Please try again.';
          _isSigningUp = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _signupError = 'Signup failed: ${e.toString()}';
        _isSigningUp = false;
      });
    }
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF030B18),
            const Color(0xFF0A192F),
            const Color(0xFF030B18),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Digital Tech Particles
class TechParticlePainter extends CustomPainter {
  final Animation<double> animation;
  TechParticlePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00E5FF).withOpacity(0.2);
    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      double x = random.nextDouble() * size.width;
      double y = (random.nextDouble() * size.height + (animation.value * 100)) % size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}