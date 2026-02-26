import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class DataLinkScreen extends StatefulWidget {
  final String? nodeId;
  final String? epsilon;
  
  const DataLinkScreen({super.key, this.nodeId, this.epsilon});

  @override
  State<DataLinkScreen> createState() => _DataLinkScreenState();
}

class _DataLinkScreenState extends State<DataLinkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _analysisController;
  
  String? _selectedFilePath;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  Map<String, dynamic>? _analysisResults;
  bool _isNonIID = false;
  double _uniquenessScore = 0.0;
  List<String> _statusLogs = [];
  List<Map<String, dynamic>> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _analysisController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // In a real app, this would use file_picker package
    // For now, simulate file selection
    setState(() {
      _selectedFilePath = 'train.csv';
    });
    
    // Start analysis
    _startAnalysis();
  }

  void _addAuditLog(String category, String message, {bool isSecure = true}) {
    if (mounted) {
      setState(() {
        _auditLogs.add({
          'category': category,
          'message': message,
          'isSecure': isSecure,
          'timestamp': DateTime.now(),
        });
        // Keep only last 10 logs
        if (_auditLogs.length > 10) {
          _auditLogs.removeAt(0);
        }
      });
    }
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _statusLogs = ['[STATUS] Analyzing local distribution...'];
      _auditLogs = [];
    });
    
    _analysisController.repeat();
    
    // File Access Verification
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _addAuditLog(
        'File Access',
        'Sentinel initialized in read-only mode for train.csv. File move/write permissions denied by OS sandbox.',
        isSecure: true,
      );
      setState(() {
        _statusLogs.add('[SECURE] No outbound data detected');
      });
    }
    
    // Local Training Telemetry
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      final random = math.Random();
      final ramUsage = 0.8 + random.nextDouble() * 0.8; // 0.8-1.6 GB
      final cpuLoad = 30 + random.nextInt(30); // 30-60%
      _addAuditLog(
        'Local Training',
        'Epoch 1/5: Computing gradients on local device. RAM usage: ${ramUsage.toStringAsFixed(1)}GB. CPU load: $cpuLoad%.',
        isSecure: true,
      );
      setState(() {
        _statusLogs.add('[SECURE] Local processing only');
      });
    }
    
    // Differential Privacy Application
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      _addAuditLog(
        'Differential Privacy',
        'DP-SGD noise injection active. Gradient clipping applied at C=1.0. Privacy budget ε=${widget.epsilon ?? "0.5"}.',
        isSecure: true,
      );
      setState(() {
        _statusLogs.add('[STATUS] Computing data distribution...');
      });
    }
    
    // Outbound Data Inspection
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      final random = math.Random();
      final payloadSize = 35 + random.nextInt(15); // 35-50 KB
      _addAuditLog(
        'Outbound Data',
        'Packet ready for transmission. Payload size: ${payloadSize}KB (Model Weights). Raw data content: 0%.',
        isSecure: true,
      );
    }
    
    // Simulate Non-IID analysis
    await Future.delayed(const Duration(milliseconds: 500));
    
    final random = math.Random();
    final uniqueness = 0.3 + random.nextDouble() * 0.5; // 30-80% uniqueness
    final isNonIID = uniqueness > 0.5;
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _analysisComplete = true;
        _uniquenessScore = uniqueness;
        _isNonIID = isNonIID;
        _statusLogs.add('[COMPLETE] Analysis finished. Data ready for local training.');
        _analysisController.stop();
        _analysisResults = {
          'totalSamples': 10000 + random.nextInt(50000),
          'fraudCases': 100 + random.nextInt(500),
          'features': 20 + random.nextInt(10),
          'uniqueness': uniqueness,
          'isNonIID': isNonIID,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          // Background particles
          Positioned.fill(
            child: CustomPaint(
              painter: ParticleBackgroundPainter(),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/onboarding/scan?nodeId=${widget.nodeId}&epsilon=${widget.epsilon}'),
                      ),
                      const Spacer(),
                      Text(
                        'Step 4 of 5',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  const Text(
                    'Local Data Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Grant Sentinel Node read-only access to your local training set',
                    style: TextStyle(
                      color: AppTheme.cyberCyan.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Privacy Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.cyberCyan.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          color: AppTheme.cyberCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data remains on-device. Only encrypted updates shared.',
                          style: TextStyle(
                            color: AppTheme.cyberCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Security Handshake - Local Data Link
                  if (_selectedFilePath == null)
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.cyberCyan.withOpacity(0.4),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.cyberCyan.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Shield over Folder Icon (Trust-Based Design)
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Folder icon
                                Icon(
                                  Icons.folder,
                                  color: AppTheme.cyberCyan.withOpacity(0.6),
                                  size: 80,
                                ),
                                // Shield overlay
                                Positioned(
                                  top: 0,
                                  child: Icon(
                                    Icons.verified_user,
                                    color: AppTheme.cyberCyan,
                                    size: 40,
                                  ),
                                ),
                                // Lock animation
                                AnimatedBuilder(
                                  animation: _analysisController,
                                  builder: (context, child) {
                                    return Positioned(
                                      bottom: 10,
                                      child: Transform.scale(
                                        scale: 0.8 + 0.2 * _analysisController.value,
                                        child: Icon(
                                          Icons.lock,
                                          color: AppTheme.cyberCyan,
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Link Local Secure Data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Grant read-only access to train.csv',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.cyberCyan,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Data stays on your device',
                                    style: TextStyle(
                                      color: AppTheme.cyberCyan,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Selected File with Security Status
                  if (_selectedFilePath != null && !_analysisComplete)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.cyberCyan.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Icon(
                                    Icons.folder,
                                    color: AppTheme.cyberCyan.withOpacity(0.6),
                                    size: 32,
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Icon(
                                      Icons.verified_user,
                                      color: AppTheme.cyberCyan,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'train.csv',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Local file path linked',
                                      style: TextStyle(
                                        color: AppTheme.cyberCyan.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isAnalyzing)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.cyberCyan,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Real-time Security Status Log
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.cyberCyan.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: AppTheme.cyberCyan,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Security Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._statusLogs.map((log) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _buildStatusLog(log, true),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  
                  // Analysis Results
                  if (_analysisComplete && _analysisResults != null)
                    Column(
                      children: [
                            // Non-IID Analysis Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isNonIID 
                                      ? AppTheme.cyberCyan.withOpacity(0.5)
                                      : Colors.orange.withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isNonIID ? Icons.trending_up : Icons.info,
                                        color: _isNonIID 
                                            ? AppTheme.cyberCyan 
                                            : Colors.orange,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Non-IID Analysis',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Data Uniqueness:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${(_uniquenessScore * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: _isNonIID 
                                              ? AppTheme.cyberCyan 
                                              : Colors.orange,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: _uniquenessScore,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isNonIID 
                                          ? AppTheme.cyberCyan 
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isNonIID
                                        ? 'Your data distribution is unique. This will improve global model diversity.'
                                        : 'Your data is similar to other nodes. Standard federated learning will work well.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  
                            const SizedBox(height: 24),
                  
                            // Data Statistics
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dataset Statistics',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatRow('Total Samples', _analysisResults!['totalSamples'].toString()),
                                  _buildStatRow('Fraud Cases', _analysisResults!['fraudCases'].toString()),
                                  _buildStatRow('Features', _analysisResults!['features'].toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                  
                  // Real-Time Privacy Audit Log
                  if (_isAnalyzing || _auditLogs.isNotEmpty)
                    _buildPrivacyAuditLog(),
                  
                  const SizedBox(height: 20),
                  
                  // Connect Button
                  if (_analysisComplete)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64FFDA), Color(0xFF48CAE4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/onboarding/sync?nodeId=${widget.nodeId}&epsilon=${widget.epsilon}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Connect to Federation',
                          style: TextStyle(
                            color: Color(0xFF0A192F),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLog(String message, bool isSecure) {
    final isStatus = message.startsWith('[STATUS]');
    final isSecureMsg = message.startsWith('[SECURE]');
    final isComplete = message.startsWith('[COMPLETE]');
    
    IconData icon;
    Color color;
    
    if (isComplete) {
      icon = Icons.check_circle;
      color = AppTheme.cyberCyan;
    } else if (isSecureMsg) {
      icon = Icons.verified_user;
      color = AppTheme.cyberCyan;
    } else if (isStatus) {
      icon = Icons.info;
      color = Colors.white70;
    } else {
      icon = isSecure ? Icons.check_circle : Icons.error;
      color = isSecure ? AppTheme.cyberCyan : Colors.red;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyAuditLog() {
    if (_auditLogs.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppTheme.cyberCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Real-Time Privacy Audit Log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Zero-Trust',
                  style: TextStyle(
                    color: AppTheme.cyberCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Colors.white24,
            height: 1,
          ),
          const SizedBox(height: 12),
          ..._auditLogs.map((log) => _buildAuditLogEntry(log)),
        ],
      ),
    );
  }

  Widget _buildAuditLogEntry(Map<String, dynamic> log) {
    final category = log['category'] as String;
    final message = log['message'] as String;
    final isSecure = log['isSecure'] as bool;
    final timestamp = log['timestamp'] as DateTime;
    
    IconData categoryIcon;
    Color categoryColor;
    
    switch (category) {
      case 'File Access':
        categoryIcon = Icons.folder_open;
        categoryColor = AppTheme.cyberCyan;
        break;
      case 'Local Training':
        categoryIcon = Icons.memory;
        categoryColor = Colors.blue;
        break;
      case 'Differential Privacy':
        categoryIcon = Icons.shield;
        categoryColor = Colors.purple;
        break;
      case 'Outbound Data':
        categoryIcon = Icons.network_check;
        categoryColor = Colors.green;
        break;
      default:
        categoryIcon = Icons.info;
        categoryColor = Colors.white70;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
                if (isSecure)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppTheme.cyberCyan,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified: No raw data transmission',
                          style: TextStyle(
                            color: AppTheme.cyberCyan,
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParticleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.1);
    final random = math.Random(42);
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) => false;
}

