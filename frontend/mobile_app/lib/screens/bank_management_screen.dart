import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/animated_background.dart';
import '../providers/app_state.dart';
import '../providers/api_service.dart';

class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});

  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final _bankNameController = TextEditingController();
  final _bankIdController = TextEditingController();
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bankNameController.dispose();
    _bankIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, ApiService>(
      builder: (context, appState, apiService, child) {
        // CRITICAL: Gate this screen to admin users only
        // Check actual user role from backend API, not local settings
        final isAdmin = apiService.isAdmin || 
                       apiService.userRole == 'ADMIN' || 
                       apiService.userRole == 'BANK_ADMIN' ||
                       // Fallback to local setting for testing (remove in production)
                       appState.settings.userMode == 'admin';
        
        if (!isAdmin) {
          // Show unauthorized access screen for non-admin users
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 80,
                              color: AppTheme.dangerRed,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Admin Access Required',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Bank Management is restricted to administrators only. '
                                'Regular users can view bank performance in the Banks Performance screen.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/banks'),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('View Banks Performance'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cyberCyan,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Admin users can access the full Bank Management screen
        return Scaffold(
          body: Stack(
            children: [
              AnimatedBackground(child: Container()),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStats(),
                            const SizedBox(height: 20),
                            _buildBanksList(),
                            const SizedBox(height: 20),
                            _buildAddBankSection(),
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
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          HolographicButton(
            onPressed: () {
              // Use Navigator.pop() first to properly dispose widgets and textures
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/dashboard');
              }
            },
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.cyberGradient.createShader(bounds),
                  child: const Text(
                    'Bank Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'Add or Remove Participating Banks',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return GlassmorphicContainer(
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard('Active Banks', '${appState.banks.length}', AppTheme.neuralGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Total Samples', '126K+', AppTheme.cyberCyan),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Avg Accuracy', '94.7%', AppTheme.electricBlue),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildBanksList() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return GlassmorphicContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Participating Banks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...appState.banks.map((bank) => _buildBankCard(bank, appState)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankCard(dynamic bank, AppState appState) {
    final colors = {
      'blue': AppTheme.electricBlue,
      'green': AppTheme.neuralGreen,
      'purple': AppTheme.privacyPurple,
      'cyan': AppTheme.cyberCyan,
      'pink': AppTheme.neonPink,
    };
    
    final color = colors[bank.color] ?? AppTheme.cyberCyan;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Icon(Icons.business, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${bank.samples} samples • ${(bank.fraudRate * 100).toStringAsFixed(1)}% fraud rate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'AUC: ${(bank.metrics.auc * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          HolographicButton(
            onPressed: () => _showRemoveBankDialog(bank, appState),
            child: const Icon(Icons.remove_circle, color: AppTheme.dangerRed),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankSection() {
    return GlassmorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add New Bank',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              HolographicButton(
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
                child: Icon(
                  _showAddForm ? Icons.close : Icons.add,
                  color: AppTheme.cyberCyan,
                ),
              ),
            ],
          ),
          if (_showAddForm) ...[
            const SizedBox(height: 16),
            _buildAddForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _bankNameController,
          label: 'Bank Name',
          icon: Icons.business,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _bankIdController,
          label: 'Bank ID',
          icon: Icons.fingerprint,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _addNewBank,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ).copyWith(
              backgroundColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppTheme.cyberGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Add Bank to Federation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: AppTheme.cyberCyan, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _addNewBank() {
    if (_bankNameController.text.isEmpty || _bankIdController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', AppTheme.dangerRed);
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addNewBank(_bankNameController.text, _bankIdController.text);
    
    _bankNameController.clear();
    _bankIdController.clear();
    setState(() => _showAddForm = false);
    
    _showSnackBar('Bank added successfully!', AppTheme.neuralGreen);
  }

  void _showRemoveBankDialog(dynamic bank, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Remove Bank', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove ${bank.name} from the federation?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.cyberCyan)),
          ),
          TextButton(
            onPressed: () {
              appState.removeBank(bank.id);
              Navigator.pop(context);
              _showSnackBar('Bank removed from federation', AppTheme.dangerRed);
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}