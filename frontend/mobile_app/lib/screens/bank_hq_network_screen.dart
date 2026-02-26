import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class BankHQNetworkScreen extends StatefulWidget {
  const BankHQNetworkScreen({super.key});

  @override
  State<BankHQNetworkScreen> createState() => _BankHQNetworkScreenState();
}

class _BankHQNetworkScreenState extends State<BankHQNetworkScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _mapController;

  final List<BankLocation> banks = [
    BankLocation(name: 'New York HQ', country: 'USA', lat: 40.7128, lon: -74.0060, participants: 1250),
    BankLocation(name: 'London HQ', country: 'UK', lat: 51.5074, lon: -0.1278, participants: 980),
    BankLocation(name: 'Tokyo HQ', country: 'Japan', lat: 35.6762, lon: 139.6503, participants: 1100),
    BankLocation(name: 'Singapore HQ', country: 'Singapore', lat: 1.3521, lon: 103.8198, participants: 750),
    BankLocation(name: 'Frankfurt HQ', country: 'Germany', lat: 50.1109, lon: 8.6821, participants: 850),
    BankLocation(name: 'Sydney HQ', country: 'Australia', lat: -33.8688, lon: 151.2093, participants: 620),
    BankLocation(name: 'Toronto HQ', country: 'Canada', lat: 43.6532, lon: -79.3832, participants: 720),
    BankLocation(name: 'Zurich HQ', country: 'Switzerland', lat: 47.3769, lon: 8.5417, participants: 580),
    BankLocation(name: 'Hong Kong HQ', country: 'Hong Kong', lat: 22.3193, lon: 114.1694, participants: 920),
    BankLocation(name: 'Dubai HQ', country: 'UAE', lat: 25.2048, lon: 55.2708, participants: 680),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _mapController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        title: const Text(
          'BANK HQ NETWORK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetworkOverview(),
            const SizedBox(height: 24),
            _buildWorldMap(),
            const SizedBox(height: 24),
            _buildBankList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOverview() {
    final totalParticipants = banks.fold<int>(0, (sum, bank) => sum + bank.participants);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppTheme.cyberCyan,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Bank Network',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Federated Learning Participants',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Total Banks', '${banks.length}', Icons.account_balance),
              const SizedBox(width: 16),
              _buildStatItem('Participants', '$totalParticipants', Icons.people),
              const SizedBox(width: 16),
              _buildStatItem('Countries', '${banks.map((b) => b.country).toSet().length}', Icons.public),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMedium.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.cyberCyan, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldMap() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: WorldMapPainter(
          banks: banks,
          pulseAnimation: _pulseController,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildBankList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Headquarters',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...banks.map((bank) => _buildBankCard(bank)),
      ],
    );
  }

  Widget _buildBankCard(BankLocation bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cyberCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.cyberCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bank.country,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${bank.participants} participants',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.cyberCyan,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class BankLocation {
  final String name;
  final String country;
  final double lat;
  final double lon;
  final int participants;

  BankLocation({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    required this.participants,
  });
}

class WorldMapPainter extends CustomPainter {
  final List<BankLocation> banks;
  final Animation<double> pulseAnimation;

  WorldMapPainter({
    required this.banks,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyberCyan
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.3 * pulseAnimation.value)
      ..style = PaintingStyle.fill;

    final connectionPaint = Paint()
      ..color = AppTheme.cyberCyan.withOpacity(0.2)
      ..strokeWidth = 1;

    // Convert lat/lon to screen coordinates (simplified Mercator projection)
    final points = banks.map((bank) {
      final x = (bank.lon + 180) / 360 * size.width;
      final y = (1 - (bank.lat + 90) / 180) * size.height;
      return Offset(x, y);
    }).toList();

    // Draw connections between banks
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        canvas.drawLine(points[i], points[j], connectionPaint);
      }
    }

    // Draw bank locations
    for (final point in points) {
      // Draw glow
      canvas.drawCircle(point, 12 + (4 * pulseAnimation.value), glowPaint);
      // Draw point
      canvas.drawCircle(point, 6, paint);
      // Draw inner dot
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(WorldMapPainter oldDelegate) => true;
}

