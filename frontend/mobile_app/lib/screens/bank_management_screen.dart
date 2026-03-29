import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/animated_background.dart';
import '../providers/api_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// Data models used only within this screen
// ─────────────────────────────────────────────
enum VoteStatus { approved, rejected, awaiting }

class _Official {
  final String initials;
  final String name;
  final String role;
  final Color avatarColor;
  final VoteStatus status;

  _Official copyWith({VoteStatus? status}) => _Official(
    initials: initials,
    name: name,
    role: role,
    avatarColor: avatarColor,
    status: status ?? this.status,
  );

  const _Official({
    required this.initials,
    required this.name,
    required this.role,
    required this.avatarColor,
    required this.status,
  });
}

class _ActiveBank {
  final String emoji;
  final String name;
  final String meta;
  final Color accentColor;
  final String auc;
  final String round;
  final String admin;
  final bool flagged;

  _ActiveBank copyWith({bool? flagged}) => _ActiveBank(
    emoji: emoji,
    name: name,
    meta: meta,
    accentColor: accentColor,
    auc: auc,
    round: round,
    admin: admin,
    flagged: flagged ?? this.flagged,
  );

  const _ActiveBank({
    required this.emoji,
    required this.name,
    required this.meta,
    required this.accentColor,
    required this.auc,
    required this.round,
    required this.admin,
    this.flagged = false,
  });
}

class _NotifItem {
  final String icon;
  final Color iconBg;
  final Color borderColor;
  final Color dotColor;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  _NotifItem copyWith({bool? isRead}) => _NotifItem(
    icon: icon,
    iconBg: iconBg,
    borderColor: borderColor,
    dotColor: dotColor,
    title: title,
    body: body,
    time: time,
    isRead: isRead ?? this.isRead,
  );

  const _NotifItem({
    required this.icon,
    required this.iconBg,
    required this.borderColor,
    required this.dotColor,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────
// Colours (matching the HTML/CSS design)
// ─────────────────────────────────────────────
const _bgDeep     = Color(0xFF070C1A);
const _teal       = Color(0xFF00C9A7);
const _tealDark   = Color(0xFF028090);
const _gold       = Color(0xFFF5C518);
const _red        = Color(0xFFEF4444);
const _green      = Color(0xFF34D399);
const _purple     = Color(0xFFA78BFA);
const _cardBg     = Color(0xFF0D1B3E);
const _divider    = Color(0xFF1E3370);
const _muted      = Color(0xFF8899BB);

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});

  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Mutable vote state (senior official can tap Approve/Reject)
  VoteStatus _kwameVote = VoteStatus.awaiting;
  String _pendingBankName = 'Equity Microfinance';

  late List<_ActiveBank> _localBanks;
  late List<_NotifItem> _localNotifications;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _localBanks = List.from(_banks);
    _localNotifications = List.from(_notifications);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addLocalNotification(String icon, Color color, String title, String body) {
    setState(() {
      _localNotifications.insert(0, _NotifItem(
        icon: icon,
        iconBg: color.withOpacity(0.1),
        borderColor: color.withOpacity(0.3),
        dotColor: color,
        title: title,
        body: body,
        time: 'Just now · Governance Engine · INFO',
      ));
    });
  }

  // ── Initial data ───────────
  final List<_Official> _officials = const [
    _Official(
      initials: 'JO',
      name: 'Dr. James Ochieng',
      role: 'Chief Risk Officer · Bank Alpha',
      avatarColor: _green,
      status: VoteStatus.approved,
    ),
    _Official(
      initials: 'AM',
      name: 'Amina Mutuku',
      role: 'Head of Compliance · Bank Beta',
      avatarColor: _green,
      status: VoteStatus.approved,
    ),
    _Official(
      initials: 'KN',
      name: 'Kwame Nkrumah',
      role: 'CISO · Bank Gamma',
      avatarColor: _muted,
      status: VoteStatus.awaiting,  // updated dynamically
    ),
  ];

  final List<_ActiveBank> _banks = const [
    _ActiveBank(
      emoji: '🏦',
      name: 'Bank Alpha',
      meta: '354,231 SAMPLES · NAIROBI HQ · LARGE',
      accentColor: _teal,
      auc: '0.730',
      round: '50',
      admin: 'Dr. Ochieng',
    ),
    _ActiveBank(
      emoji: '🏛️',
      name: 'Bank Beta',
      meta: '246,192 SAMPLES · MOMBASA · MEDIUM',
      accentColor: _purple,
      auc: '0.725',
      round: '50',
      admin: 'Mutuku',
    ),
    _ActiveBank(
      emoji: '🏧',
      name: 'Bank Gamma',
      meta: '108,225 SAMPLES · KISUMU · SMALL',
      accentColor: _gold,
      auc: '0.779',
      round: '48',
      admin: 'Nkrumah',
      flagged: true,
    ),
  ];

  final List<_NotifItem> _notifications = const [
    _NotifItem(
      icon: '🚨',
      iconBg: Color(0x26EF4444),
      borderColor: Color(0x40EF4444),
      dotColor: _red,
      title: 'Adversarial Gradient Detected',
      body:
          'Bank Gamma sent anomalous model update on Round 48. Deviation score: 4.7σ above normal. Gradient clipping engaged automatically.',
      time: '3 min ago · PrivFed Monitor · CRITICAL',
    ),
    _NotifItem(
      icon: '⚠️',
      iconBg: Color(0x1FF5C518),
      borderColor: Color(0x33F5C518),
      dotColor: _gold,
      title: 'Privacy Budget 87% Consumed',
      body:
          'ε spent: 6.96 / 8.0. At current round rate, budget will exhaust in ~7 rounds. Consider reducing noise multiplier.',
      time: '12 min ago · Privacy Accountant · WARNING',
    ),
    _NotifItem(
      icon: '✅',
      iconBg: Color(0x1A00C9A7),
      borderColor: Color(0x2E00C9A7),
      dotColor: _teal,
      title: 'Equity Microfinance Vote: 2/3 Reached',
      body:
          'Two of three consortium members have approved admission. Waiting on Bank Gamma\'s CISO (K. Nkrumah) to cast final vote.',
      time: '28 min ago · Governance Engine · INFO',
    ),
  ];

  // ── Computed vote counts ─────────────────────
  int get _approvedCount =>
      _officials.where((o) => o.status == VoteStatus.approved).length +
      (_kwameVote == VoteStatus.approved ? 1 : 0);

  int get _rejectedCount =>
      _officials.where((o) => o.status == VoteStatus.rejected).length +
      (_kwameVote == VoteStatus.rejected ? 1 : 0);

  int get _awaitingCount =>
      (_kwameVote == VoteStatus.awaiting ? 1 : 0);

  bool get _thresholdReached => _approvedCount >= 2;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, ApiService>(
      builder: (context, appState, apiService, _) {
        final isAdmin = apiService.isAdmin ||
            apiService.userRole == 'ADMIN' ||
            apiService.userRole == 'BANK_ADMIN' ||
            appState.settings.userMode == 'admin';

        if (!isAdmin) return _buildAccessDenied();

        return Scaffold(
          backgroundColor: _bgDeep,
          body: Stack(
            children: [
              // Static gradient background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_bgDeep, _cardBg, _bgDeep],
                    ),
                  ),
                ),
              ),
              // Removed AnimatedBackground and _GridBackground
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              _buildEmergencyBanner(),
                              const SizedBox(height: 14),
                              _buildConsortiumStats(),
                              const SizedBox(height: 14),
                              _buildSectionLabel('PENDING ADMISSION VOTE', 'REQUIRES 2/3 MAJORITY', _gold),
                              const SizedBox(height: 8),
                              _buildVoteCard(),
                              const SizedBox(height: 14),
                              _buildSectionLabel('ACTIVE CONSORTIUM BANKS', '3 NODES LIVE', _teal),
                              const SizedBox(height: 8),
                              ..._localBanks.map(_buildBankCard),
                              const SizedBox(height: 4),
                              _buildProposeBankButton(),
                              const SizedBox(height: 14),
                              _buildSectionLabel('SYSTEM NOTIFICATIONS', '${_localNotifications.where((n) => !n.isRead).length} UNREAD', _red),
                              const SizedBox(height: 8),
                              ..._localNotifications.map(_buildNotifItem),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════
  // ACCESS DENIED
  // ══════════════════════════════════════════════
  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _red.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.lock_outline, size: 40, color: _red),
                    ),
                    const SizedBox(height: 24),
                    const Text('Admin Access Required',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Bank Management is restricted to administrators only. '
                        'Regular users can view bank performance in the Banks Performance screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => context.go('/banks'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_teal, _tealDark]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_forward, color: _bgDeep, size: 18),
                            SizedBox(width: 8),
                            Text('View Banks Performance',
                                style: TextStyle(color: _bgDeep, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
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
    );
  }

  // ══════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go('/dashboard'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('BANK MANAGEMENT',
                    style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900,
                      letterSpacing: 2, fontFamily: 'monospace',
                    )),
                Text('SENIOR ADMIN CONSOLE · RESTRICTED',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 0.5, fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _red.withOpacity(0.35)),
                ),
                child: const Icon(Icons.notifications_outlined, color: _red, size: 20),
              ),
              Positioned(
                top: -5, right: -5,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _red, shape: BoxShape.circle,
                    border: Border.all(color: _bgDeep, width: 2),
                  ),
                  child: const Center(
                    child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // EMERGENCY BANNER
  // ══════════════════════════════════════════════
  Widget _buildEmergencyBanner() {
    return Container(
      decoration: BoxDecoration(
        color: _red.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red top bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_red, Color(0xFFDC2626), _red]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚡ EMERGENCY ALERT ACTIVE',
                          style: TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        'Bank Gamma (Small) reporting anomalous gradient updates. Possible adversarial injection detected on Round 48. Model integrity at risk.',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11.5, height: 1.55),
                      ),
                      const SizedBox(height: 5),
                      Text('⏱  3 minutes ago · Auto-flagged by PrivFed Monitor',
                          style: TextStyle(color: _red.withOpacity(0.6), fontSize: 10, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _red.withOpacity(0.4)),
                        ),
                        child: const Text('REVIEW LOGS →',
                            style: TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
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

  // ══════════════════════════════════════════════
  // CONSORTIUM STATS (4 cards)
  // ══════════════════════════════════════════════
  Widget _buildConsortiumStats() {
    final stats = [
      ('3', 'ACTIVE\nBANKS', _green),
      ('1', 'PENDING\nVOTE', _gold),
      ('50', 'ROUNDS\nDONE', _purple),
      ('2/3', 'VOTE\nRULE', _teal),
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              children: [
                Text(s.$1, style: TextStyle(color: s.$3, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(s.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8.5,
                        fontFamily: 'monospace', letterSpacing: 0.5, height: 1.3)),
              ],
            ),
          ).let((w) => s == stats.last ? Container(margin: EdgeInsets.zero, child: w) : w),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════
  // SECTION LABEL
  // ══════════════════════════════════════════════
  Widget _buildSectionLabel(String title, String badge, Color badgeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9,
                fontFamily: 'monospace', letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withOpacity(0.35)),
          ),
          child: Text(badge,
              style: TextStyle(color: badgeColor, fontSize: 9,
                  fontFamily: 'monospace', fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // VOTE CARD
  // ══════════════════════════════════════════════
  Widget _buildVoteCard() {
    final approvedCount = _approvedCount;
    final progress = approvedCount / 3.0; // 3 total voters

    return Container(
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.38), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold top bar
          Container(height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_gold, Color(0xFFE8A800)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank name row
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _gold.withOpacity(0.3)),
                      ),
                      child: const Center(child: Text('🏦', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_pendingBankName,
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('REGIONAL BANK · NAIROBI, KENYA',
                              style: TextStyle(color: Colors.white.withOpacity(0.38),
                                  fontSize: 9.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.4)),
                      ),
                      child: const Text('PENDING',
                          style: TextStyle(color: _gold, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress label
                Text('APPROVAL PROGRESS – ${approvedCount} OF 3 VOTES CAST (66.6% THRESHOLD)',
                    style: TextStyle(color: Colors.white.withOpacity(0.33), fontSize: 9, fontFamily: 'monospace')),
                const SizedBox(height: 14),

                // Progress bar with 2/3 marker
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Track
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_gold, Color(0xFFE8A800)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // 2/3 threshold marker line
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -16,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 2 / 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('2/3 threshold',
                              style: TextStyle(color: _gold, fontSize: 8.5, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Vote stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _voteStatCell(approvedCount.toString(), '✅ Approved', _green),
                    _voteStatCell(_rejectedCount.toString(), '❌ Rejected', _red),
                    _voteStatCell(_awaitingCount.toString(), '⏳ Awaiting', _gold),
                    _voteStatCell('3', 'Total Voters', Colors.white),
                  ],
                ),

                const SizedBox(height: 14),
                // Divider
                Divider(color: Colors.white.withOpacity(0.06), height: 1),
                const SizedBox(height: 12),

                // Individual votes
                _officialVoteRow(_officials[0]),
                _officialVoteRow(_officials[1]),
                _buildKwameRow(), // dynamic row

                const SizedBox(height: 12),

                // Threshold reached note
                if (_thresholdReached)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withOpacity(0.25)),
                    ),
                    child: Text(
                      '✅  Threshold Reached — ${approvedCount}/3 votes secured. Admission will be finalized once all votes are cast or timer expires (2h 14m remaining).',
                      style: TextStyle(color: _green.withOpacity(0.85), fontSize: 11, height: 1.5),
                    ),
                  ),

                const SizedBox(height: 14),

                // Approve / Reject buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _kwameVote == VoteStatus.awaiting
                            ? () {
                                setState(() => _kwameVote = VoteStatus.approved);
                                _addLocalNotification('✅', _green, 'Consortium Vote Finalized', 'CISO Kwame Nkrumah approved $_pendingBankName. Admission threshold reached.');
                              }
                            : null,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: _kwameVote == VoteStatus.awaiting
                                ? const LinearGradient(colors: [_green, Color(0xFF059669)])
                                : null,
                            color: _kwameVote != VoteStatus.awaiting ? _green.withOpacity(0.3) : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _kwameVote == VoteStatus.awaiting
                                ? [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: const Center(
                            child: Text('✅  CAST APPROVE',
                                style: TextStyle(color: _bgDeep, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _kwameVote == VoteStatus.awaiting
                            ? () {
                                setState(() => _kwameVote = VoteStatus.rejected);
                                _addLocalNotification('❌', _red, 'Consortium Vote Denied', 'CISO Kwame Nkrumah rejected $_pendingBankName. Admission denied.');
                              }
                            : null,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _red.withOpacity(0.5), width: 1.5),
                          ),
                          child: const Center(
                            child: Text('❌  REJECT',
                                style: TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteStatCell(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9.5, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _officialVoteRow(_Official o) {
    return _buildVoteRowContent(o.initials, o.name, o.role, o.avatarColor, o.status);
  }

  Widget _buildKwameRow() {
    final color = _kwameVote == VoteStatus.awaiting ? _muted : (_kwameVote == VoteStatus.approved ? _green : _red);
    return _buildVoteRowContent('KN', 'Kwame Nkrumah', 'CISO · Bank Gamma', color, _kwameVote);
  }

  Widget _buildVoteRowContent(String initials, String name, String role, Color avatarColor, VoteStatus status) {
    Widget chip;
    switch (status) {
      case VoteStatus.approved:
        chip = _statusChip('APPROVED', _green, _green.withOpacity(0.15), _green.withOpacity(0.4));
        break;
      case VoteStatus.rejected:
        chip = _statusChip('REJECTED', _red, _red.withOpacity(0.12), _red.withOpacity(0.35));
        break;
      case VoteStatus.awaiting:
        chip = _statusChip('AWAITING', Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.15));
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: avatarColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(initials, style: TextStyle(color: avatarColor, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(role, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9.5, fontFamily: 'monospace')),
              ],
            ),
          ),
          chip,
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color textColor, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
    );
  }

  // ══════════════════════════════════════════════
  // ACTIVE BANK CARD
  // ══════════════════════════════════════════════
  Widget _buildBankCard(_ActiveBank bank) {
    final borderColor = bank.flagged ? _red.withOpacity(0.3) : bank.accentColor.withOpacity(0.25);
    final cardColor = bank.flagged ? _red.withOpacity(0.04) : Colors.white.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: bank.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: bank.accentColor.withOpacity(0.3)),
            ),
            child: Center(child: Text(bank.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bank.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    // Status dot
                    if (bank.flagged)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _red.withOpacity(_pulseController.value * 0.7 + 0.3),
                          ),
                        ),
                      )
                    else
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: _green)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(bank.meta,
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9.5, fontFamily: 'monospace')),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _metaChip('AUC: ${bank.auc}', bank.accentColor),
                    const SizedBox(width: 5),
                    _metaChip('Round ${bank.round}', null),
                    const SizedBox(width: 5),
                    if (bank.flagged)
                      _metaChip('⚠ FLAGGED', _red)
                    else
                      _metaChip('Admin: ${bank.admin}', null),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons column
          Column(
            children: [
              _actionBtn(Icons.bar_chart, _teal, () => _showBankDetails(bank)),
              const SizedBox(height: 5),
              bank.flagged
                  ? _actionBtn(Icons.lock, _red, () => _confirmSuspend(bank))
                  : _actionBtn(Icons.pause, _gold, () => _confirmSuspend(bank)),
              const SizedBox(height: 5),
              _actionBtn(Icons.delete_outline, _red.withOpacity(0.7), () => _confirmRemove(bank)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, Color? color) {
    final c = color ?? Colors.white.withOpacity(0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: c, fontSize: 9, fontFamily: 'monospace')),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // PROPOSE NEW BANK BUTTON
  // ══════════════════════════════════════════════
  Widget _buildProposeBankButton() {
    return GestureDetector(
      onTap: _showProposeBankSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _teal.withOpacity(0.35), width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _teal.withOpacity(0.3)),
              ),
              child: const Icon(Icons.add, color: _teal, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Propose New Bank',
                    style: TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w800)),
                Text('TRIGGERS 2/3 MAJORITY VOTE · CONSORTIUM APPROVAL REQUIRED',
                    style: TextStyle(color: _teal.withOpacity(0.55), fontSize: 8.5, fontFamily: 'monospace')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // NOTIFICATION ITEM
  // ══════════════════════════════════════════════
  Widget _buildNotifItem(_NotifItem n) {
    return GestureDetector(
      onTap: () => setState(() {
        final idx = _localNotifications.indexOf(n);
        if (idx != -1) _localNotifications[idx] = n.copyWith(isRead: true);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.iconBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: n.iconBg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(n.icon, style: const TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(n.body, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10.5, height: 1.5)),
                  const SizedBox(height: 5),
                  Text(n.time, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!n.isRead)
              Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: n.dotColor)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // DIALOGS / SHEETS
  // ══════════════════════════════════════════════
  void _showBankDetails(_ActiveBank bank) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${bank.name} telemetry…'),
        backgroundColor: bank.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmSuspend(_ActiveBank bank) {
    _showConfirmDialog(
      icon: Icons.pause_circle_outline,
      iconColor: _gold,
      title: bank.flagged ? 'Lock Bank Node' : 'Suspend Bank',
      body: 'Are you sure you want to change status for ${bank.name}? '
          'This will remove it from the active federation round.',
      confirmLabel: bank.flagged ? 'LOCK' : 'SUSPEND',
      confirmColor: _gold,
      onConfirm: () {
        setState(() {
          final index = _localBanks.indexOf(bank);
          if (index != -1) {
            _localBanks[index] = bank.copyWith(flagged: !bank.flagged);
          }
        });
        _addLocalNotification(bank.flagged ? '🔓' : '🔒', bank.flagged ? _green : _gold, 
          'Security Status Updated', '${bank.name} has been ${bank.flagged ? 'unflagged' : 'flagged and suspended'} by admin.');
      },
    );
  }

  void _confirmRemove(_ActiveBank bank) {
    _showConfirmDialog(
      icon: Icons.remove_circle_outline,
      iconColor: _red,
      title: 'Remove ${bank.name}',
      body: 'Removing ${bank.name} will require a 2/3 consortium vote to re-admit. This action is logged.',
      confirmLabel: 'REMOVE',
      confirmColor: _red,
      onConfirm: () {
        setState(() {
          _localBanks.remove(bank);
        });
        _addLocalNotification('🚮', _red, 'Bank Removed', '${bank.name} has been removed from the active consortium.');
      },
    );
  }

  void _showProposeBankSheet() {
    final nameCtrl = TextEditingController();
    final idCtrl   = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B3E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Propose New Bank',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            Text('This will trigger a 2/3 majority vote across all consortium members.',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.6)),
            const SizedBox(height: 20),
            _sheetInput(nameCtrl, 'Bank Name', Icons.business),
            const SizedBox(height: 12),
            _sheetInput(idCtrl, 'Federation ID', Icons.fingerprint),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final newName = nameCtrl.text.trim();
                setState(() {
                  _pendingBankName = newName.isEmpty ? "New Bank" : newName;
                  _kwameVote = VoteStatus.awaiting;
                });
                Navigator.pop(context);
                _addLocalNotification('🏛️', _teal, 'Admission Proposed', 'A new admission request for $_pendingBankName has been initiated.');
                _showSnackBar('Vote initiated for $_pendingBankName', _gold);
              },
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_teal, _tealDark]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: const Center(
                  child: Text('INITIATE CONSORTIUM VOTE',
                      style: TextStyle(color: _bgDeep, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetInput(TextEditingController ctrl, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          prefixIcon: Icon(icon, color: _teal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0D1B3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withOpacity(0.4)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.55)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Center(child: Text('CANCEL',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { Navigator.pop(context); onConfirm(); },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: confirmColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: confirmColor.withOpacity(0.5), width: 1.5),
                        ),
                        child: Center(child: Text(confirmLabel,
                            style: TextStyle(color: confirmColor, fontWeight: FontWeight.w900, letterSpacing: 1))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────
// Dart 3 extension for inline widget transform
// ─────────────────────────────────────────────
extension _WidgetLet<T> on T {
  T let(T Function(T) fn) => fn(this);
}