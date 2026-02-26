import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class LearnMoreCinematic extends StatefulWidget {
  const LearnMoreCinematic({super.key});

  @override
  State<LearnMoreCinematic> createState() => _LearnMoreCinematicState();
}

class _LearnMoreCinematicState extends State<LearnMoreCinematic>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late PageController _pageController;

  final List<LearningModule> _modules = [
    LearningModule(
      title: 'Federated Learning Fundamentals',
      description: 'Learn the core concepts of federated learning and how it enables collaborative AI without data sharing.',
      icon: Icons.school,
      color: AppTheme.primaryBlue,
      lessons: [
        'What is Federated Learning?',
        'Client-Server Architecture',
        'Model Aggregation Strategies',
        'Non-IID Data Challenges',
      ],
    ),
    LearningModule(
      title: 'Differential Privacy Deep Dive',
      description: 'Understand the mathematical foundations of differential privacy and its implementation in ML systems.',
      icon: Icons.security,
      color: AppTheme.primaryPurple,
      lessons: [
        'Privacy Definitions & Guarantees',
        'Epsilon-Delta Framework',
        'DP-SGD Algorithm',
        'Privacy Accounting Methods',
      ],
    ),
    LearningModule(
      title: 'Fraud Detection in Finance',
      description: 'Explore machine learning techniques specifically designed for financial fraud detection.',
      icon: Icons.account_balance,
      color: AppTheme.dangerRed,
      lessons: [
        'Types of Financial Fraud',
        'Feature Engineering for Fraud',
        'Imbalanced Dataset Handling',
        'Real-time Detection Systems',
      ],
    ),
    LearningModule(
      title: 'System Architecture & Implementation',
      description: 'Technical deep dive into building production-ready federated learning systems.',
      icon: Icons.architecture,
      color: AppTheme.accentGreen,
      lessons: [
        'Scalable FL Infrastructure',
        'Communication Protocols',
        'Fault Tolerance & Recovery',
        'Performance Optimization',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pageController = PageController();
    
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      _buildLearningModules(),
                      _buildInteractiveDemo(),
                      _buildResources(),
                      _buildQuickFacts(),
                      const SizedBox(height: AppTheme.spacingXL),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Flexible(
            child: Text(
              'Learn More',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryCyan),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: AppTheme.primaryCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LEARN',
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryCyan.withOpacity(0.2),
            AppTheme.primaryPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            color: AppTheme.primaryCyan,
            size: 64,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          const Text(
            'Master Privacy-Preserving AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          Text(
            'Dive deep into federated learning, differential privacy, and fraud detection. Learn from industry experts and build production-ready systems.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroStat('4', 'Modules'),
              _buildHeroStat('16', 'Lessons'),
              _buildHeroStat('2h', 'Duration'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.primaryCyan,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLearningModules() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Modules',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          ..._modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            
            return AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                final delay = index * 0.2;
                final progress = (_cardController.value - delay).clamp(0.0, 1.0);
                
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - progress)),
                  child: Opacity(
                    opacity: progress,
                    child: _buildModuleCard(module),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModuleCard(LearningModule module) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            module.color.withOpacity(0.2),
            module.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: module.color.withOpacity(0.3),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: module.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            module.icon,
            color: module.color,
            size: 24,
          ),
        ),
        title: Text(
          module.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          module.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lessons:',
                  style: TextStyle(
                    color: module.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                ...module.lessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: module.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: module.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            lesson,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Icon(
                          Icons.play_circle_outline,
                          color: module.color,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: AppTheme.spacingL),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Start module
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: module.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Start Module',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildInteractiveDemo() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.2),
            AppTheme.accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: AppTheme.accentGold,
                size: 32,
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: Text(
                  'Interactive Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          Text(
            'Experience federated learning in action with our interactive simulation. Watch as three banks collaborate to train a fraud detection model while keeping their data private.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Launch interactive demo
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    'Launch Demo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Watch video
                  },
                  icon: Icon(Icons.video_library, color: AppTheme.accentGold),
                  label: Text(
                    'Watch Video',
                    style: TextStyle(color: AppTheme.accentGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.accentGold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResources() {
    final resources = [
      Resource(
        title: 'Research Papers',
        description: 'Latest academic papers on federated learning and differential privacy',
        icon: Icons.article,
        color: AppTheme.primaryBlue,
      ),
      Resource(
        title: 'Code Examples',
        description: 'Open-source implementations and code samples',
        icon: Icons.code,
        color: AppTheme.accentGreen,
      ),
      Resource(
        title: 'Best Practices',
        description: 'Industry guidelines and implementation recommendations',
        icon: Icons.checklist,
        color: AppTheme.primaryPurple,
      ),
      Resource(
        title: 'Community Forum',
        description: 'Connect with other practitioners and discuss ideas',
        icon: Icons.forum,
        color: AppTheme.primaryCyan,
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Resources',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 0.85, // Reduced from 1.1 to give more vertical space
            ),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              return _buildResourceCard(resources[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: resource.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: resource.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              resource.icon,
              color: resource.color,
              size: 24,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          Text(
            resource.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          Flexible(
            child: Text(
              resource.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFacts() {
    final facts = [
      '🔒 Differential privacy was invented at Microsoft Research in 2006',
      '🏦 Major banks are already using federated learning for fraud detection',
      '📊 FL can reduce communication costs by up to 100x compared to centralized training',
      '🛡️ ε = 1.0 is considered the gold standard for strong privacy',
      '🚀 Google uses federated learning for Gboard keyboard predictions',
      '⚖️ Fairness-aware FL ensures equitable performance across all participants',
    ];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              const Text(
                'Quick Facts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          ...facts.map((fact) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              fact,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class LearningModule {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> lessons;

  LearningModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lessons,
  });
}

class Resource {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Resource({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}