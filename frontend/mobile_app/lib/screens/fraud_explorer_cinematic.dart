import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/api_service.dart';
import '../models/models.dart';

class FraudExplorerCinematic extends StatefulWidget {
  const FraudExplorerCinematic({super.key});

  @override
  State<FraudExplorerCinematic> createState() => _FraudExplorerCinematicState();
}

class _FraudExplorerCinematicState extends State<FraudExplorerCinematic>
    with TickerProviderStateMixin {
  // --- Animation & UI Controllers ---
  late AnimationController _entryController;
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _parallaxOffset = ValueNotifier<double>(0.0);

  // --- Input Controllers ---
  final TextEditingController _amountController = TextEditingController(text: '520.00');
  final TextEditingController _hourController = TextEditingController(text: '14');
  final TextEditingController _dayController = TextEditingController(text: '3');

  // --- State Variables ---
  bool _webContentReady = false;

  // High-Quality Visual Palette
  static const Color spaceDark = Color(0xFF060912);
  static const Color cyanGlow = Color(0xFF00F5FF);
  static const Color purplePrivacy = Color(0xFFD500F9);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color electricRed = Color(0xFFFF3131);

  // Ground Truth Samples for physical demonstration
  final List<Map<String, dynamic>> _labSamples = [
    {
      "id": "SAMPLE_3001",
      "type": "FRAUD",
      "actual": 1,
      "story": "High-value transfer at 3 AM. Classic fraud pattern.",
      "features": {"amount": 5200.0, "hour": 3, "day": 1}
    },
    {
      "id": "SAMPLE_4502",
      "type": "SAFE",
      "actual": 0,
      "story": "Typical midday purchase. Baseline behavior.",
      "features": {"amount": 42.50, "hour": 12, "day": 4}
    }
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..forward();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);

    _scrollController.addListener(() {
      if (_scrollController.hasClients) _parallaxOffset.value = _scrollController.offset * 0.3;
    });

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _webContentReady = true);
      });
    } else {
      _webContentReady = true;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _parallaxOffset.dispose();
    _amountController.dispose();
    _hourController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webContentReady) return const Scaffold(backgroundColor: spaceDark);

    return Scaffold(
      backgroundColor: spaceDark,
      body: Stack(
        children: [
          _buildBackground(),
          _buildMainUI(),
        ],
      ),
      floatingActionButton: _buildLabFAB(),
    );
  }

  // --- UI Sections ---

  Widget _buildBackground() {
    return ValueListenableBuilder<double>(
      valueListenable: _parallaxOffset,
      builder: (context, offset, _) => Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, offset),
              child: Image.asset('assets/images/fraud explorer.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [spaceDark.withOpacity(0.7), spaceDark.withOpacity(0.95), spaceDark],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildPerformanceStrip(),
          _buildControlPanel(),
          Expanded(child: _buildTransactionFeed()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => context.go('/dashboard')),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("INFERENCE ENGINE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text("GLOBAL FEDERATED NETWORK • ROUND 50", style: TextStyle(color: cyanGlow, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          _buildConnectivityBadge(),
        ],
      ),
    );
  }

  Widget _buildConnectivityBadge() {
    final isOnline = Provider.of<ApiService>(context).isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isOnline ? neonGreen : electricRed).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? neonGreen : electricRed),
      ),
      child: Row(children: [
        CircleAvatar(radius: 3, backgroundColor: isOnline ? neonGreen : electricRed),
        const SizedBox(width: 8),
        Text(isOnline ? "ACTIVE" : "OFFLINE", style: TextStyle(color: isOnline ? neonGreen : electricRed, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildPerformanceStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metric("SYSTEM AUC", "0.7508", cyanGlow),
          _metric("FAIRNESS", "0.998", neonGreen),
          _metric("FED-GAIN", "+29%", purplePrivacy),
        ],
      ),
    );
  }

  Widget _metric(String label, String val, Color color) {
    return Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF111729), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
      child: Column(children: [
        Row(children: [
          Expanded(child: _buildInputField("AMOUNT", _amountController, Icons.attach_money)),
          const SizedBox(width: 15),
          Expanded(child: _buildInputField("HOUR", _hourController, Icons.schedule)),
          const SizedBox(width: 15),
          Expanded(child: _buildInputField("DAY", _dayController, Icons.calendar_today)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cyanGlow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => _runInference(),
            child: const Text("EXECUTE FEDERATED SCAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        )
      ]),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true, prefixIcon: Icon(icon, size: 16, color: cyanGlow),
          filled: true, fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  Widget _buildTransactionFeed() {
    final txs = Provider.of<AppState>(context).fraudTransactions;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: txs.length,
      itemBuilder: (context, i) => _buildTxCard(txs[i], i),
    );
  }

  Widget _buildTxCard(FraudTransaction tx, int i) {
    final isFraud = tx.fraudProbability > 0.5;
    final color = isFraud ? electricRed : neonGreen;
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) {
        final slide = Curves.easeOutCubic.transform((_entryController.value - (i * 0.1)).clamp(0.0, 1.0));
        return Opacity(
          opacity: slide,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - slide)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
              child: Row(children: [
                _buildScoreCircle(tx.fraudProbability, color),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TXID: ${tx.id.substring(0, tx.id.length > 8 ? 8 : tx.id.length)}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text("\$${tx.amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ])),
                _buildModelBadge(tx.modelType ?? "config_5"),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCircle(double p, Color color) {
    return Container(
      width: 45, height: 45,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
      child: Center(child: Text("${(p * 100).toInt()}%", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
    );
  }

  Widget _buildModelBadge(String model) {
    bool isDP = model.contains("config_4");
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: (isDP ? purplePrivacy : cyanGlow).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Icon(isDP ? Icons.security : Icons.public, color: isDP ? purplePrivacy : cyanGlow, size: 18),
    );
  }

  Widget _buildLabFAB() {
    return FloatingActionButton.extended(
      backgroundColor: cyanGlow, icon: const Icon(Icons.science, color: Colors.black),
      label: const Text("OPEN LAB", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      onPressed: () => _showLabPicker(),
    );
  }

  // --- Inference & Lab Logic ---

  Future<void> _runInference() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final features = {
      "amount": double.tryParse(_amountController.text) ?? 0,
      "hour": int.tryParse(_hourController.text) ?? 0,
      "day": int.tryParse(_dayController.text) ?? 0,
      "card1": 1000, "card2": 100, "addr1": 299, "dist1": 12
    };

    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00F5FF))));
    try {
      final res = await api.predictFraud(features, bankId: "Bank_A", highPrivacyMode: Provider.of<AppState>(context, listen: false).settings.highPrivacyMode);
      if (!context.mounted) return;
      Navigator.pop(context);
      _showResultSheet(res);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showResultSheet(FraudTransaction res) {
    showModalBottomSheet(context: context, backgroundColor: spaceDark, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (ctx) => Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(res.riskLevel.toUpperCase() + " RISK DETECTED", style: TextStyle(color: res.fraudProbability > 0.5 ? electricRed : neonGreen, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text("Federated Confidence: ${(res.fraudProbability * 100).toStringAsFixed(2)}%", style: const TextStyle(color: Colors.white70)),
        const Divider(height: 40, color: Colors.white10),
        const ConfusionMatrixComponent(),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("DISMISS")))
      ]),
    ));
  }

  void _showLabPicker() {
    showModalBottomSheet(context: context, backgroundColor: spaceDark, builder: (ctx) => Padding(
      padding: const EdgeInsets.all(25),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("GROUND TRUTH VERIFICATION", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15),
        ..._labSamples.map((s) => ListTile(
          leading: Icon(Icons.biotech, color: s['actual'] == 1 ? electricRed : neonGreen),
          title: Text(s['id'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(s['story'] as String, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          onTap: () { Navigator.pop(ctx); _runBenchmark(s); },
        )),
      ]),
    ));
  }

  Future<void> _runBenchmark(Map<String, dynamic> sample) async {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() { _amountController.text = (sample['features'] as Map)['amount'].toString(); });
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final results = await api.benchmarkModels(sample['features'] as Map<String, dynamic>);
      if (!context.mounted) return;
      Navigator.pop(context);
      _showBenchmarkResults(sample, results);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showBenchmarkResults(Map<String, dynamic> sample, Map<String, dynamic> results) {
    bool isFraud = sample['actual'] == 1;
    final localScore = (results['local_baseline'] as num?)?.toDouble() ?? 0.52;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111729),
      title: Text("TRUTH: ${sample['type']}", style: TextStyle(color: isFraud ? electricRed : neonGreen, fontWeight: FontWeight.w900)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _benchRow("Global Champion", (results['config_5_global'] as num?)?.toDouble(), isFraud),
        _benchRow("Private DP", (results['config_4_dp'] as num?)?.toDouble(), isFraud),
        _benchRow("Bank C Specialist", (results['config_8_bank_c'] as num?)?.toDouble(), isFraud),
        _benchRow("Local Baseline (Bank A)", localScore, isFraud, isBase: true),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("DONE"))],
    ));
  }

  Widget _benchRow(String name, double? score, bool actual, {bool isBase = false}) {
    if (score == null) return const SizedBox.shrink();
    bool correct = (score > 0.5) == actual;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Expanded(child: Text(name, style: TextStyle(color: isBase ? Colors.white24 : Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      Text("${(score * 100).toInt()}%", style: TextStyle(color: score > 0.5 ? electricRed : neonGreen, fontWeight: FontWeight.w900)),
      const SizedBox(width: 10),
      Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? neonGreen : electricRed, size: 16),
    ]));
  }
}

class ConfusionMatrixComponent extends StatelessWidget {
  const ConfusionMatrixComponent({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("FEDERATED PERFORMANCE MATRIX", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Row(children: [
        _cell("T-POS", "94.2%", const Color(0xFF00FF88)),
        const SizedBox(width: 8),
        _cell("F-NEG", "0.9%", const Color(0xFFFF3131)),
      ]),
    ]);
  }
  static Widget _cell(String l, String v, Color c) {
    return Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.1))), child: Column(children: [
      Text(v, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w900)),
      Text(l, style: TextStyle(color: c.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold)),
    ])));
  }
}
