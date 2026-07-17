import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/player_avatar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  int _myScore = 0;
  String _prompt = '';
  List<String> _labels = [];
  String _grade = 'F';
  int _confidence = 0;
  List<String> _explanation = [];

  // Multi-criteria subscores
  int _objScore = 0;
  int _featScore = 0;
  int _compScore = 0;
  int _creatScore = 0;
  int _strokeScore = 0;
  List<String> _strengths = [];
  List<String> _weaknesses = [];

  List<Map<String, dynamic>> _rankings = [];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _myScore = args['score'] as int? ?? 0;
        _prompt = args['prompt'] as String? ?? '';
        _labels = List<String>.from(args['labels'] as List? ?? []);
        _grade = args['grade'] as String? ?? 'F';
        _confidence = args['confidence'] as int? ?? 0;
        _explanation = List<String>.from(args['explanation'] as List? ?? []);

        // Retrieve subscores if available, otherwise fallback
        _objScore = args['objectRecognitionScore'] as int? ?? (_myScore * 0.9).round();
        _featScore = args['requiredFeaturesScore'] as int? ?? (_myScore * 0.85).round();
        _compScore = args['compositionScore'] as int? ?? (_myScore * 0.95).round();
        _creatScore = args['creativityScore'] as int? ?? (_myScore * 0.88).round();
        _strokeScore = args['strokeQualityScore'] as int? ?? (_myScore * 0.9).round();

        _strengths = List<String>.from(args['strengths'] as List? ?? []);
        _weaknesses = List<String>.from(args['weaknesses'] as List? ?? []);

        _rankings = [
          {'name': 'You', 'score': _myScore, 'rank': 1},
        ];

        // Trigger score counter animation
        _scoreAnimation = Tween<double>(begin: 0, end: _myScore.toDouble()).animate(
          CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
        );
        _scoreController.forward();
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  String _getEmoji(int score) {
    if (score >= 90) return '🌟';
    if (score >= 80) return '🎨';
    if (score >= 70) return '✨';
    if (score >= 60) return '👍';
    if (score >= 40) return '🤔';
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final secColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final accentColor = isDark ? AppTheme.accentDark : AppTheme.accentLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Round Results',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Prompt: ${_prompt.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Two Column Dashboard for Tablet/Web, Single for Mobile
                    MediaQuery.of(context).size.width > 600
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildMainScoreCard(cardBg, borderColor, primaryColor, secColor)),
                              const SizedBox(width: 24),
                              Expanded(flex: 3, child: _buildJudgesDashboard(cardBg, borderColor, primaryColor, textMuted)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildMainScoreCard(cardBg, borderColor, primaryColor, secColor),
                              const SizedBox(height: 24),
                              _buildJudgesDashboard(cardBg, borderColor, primaryColor, textMuted),
                            ],
                          ),
                    const SizedBox(height: 32),

                    // Strengths & Weaknesses Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFeedbackCard(
                            title: 'Strengths',
                            items: _strengths.isNotEmpty ? _strengths : ['Good basic outlines', 'Recognizable form'],
                            icon: LucideIcons.checkCircle,
                            iconColor: AppTheme.accentLight,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeedbackCard(
                            title: 'Improvement',
                            items: _weaknesses.isNotEmpty ? _weaknesses : ['Needs secondary details', 'Outline consistency'],
                            icon: LucideIcons.alertTriangle,
                            iconColor: Colors.orangeAccent,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // AI Suggestion bubble
                    if (_explanation.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: secColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: secColor.withOpacity(0.15), width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.sparkles, color: secColor, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Analysis Details',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: secColor, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._explanation.map((e) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• $e',
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            child: const Text('Back to Home'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/home'); // Re-host or back
                            },
                            child: const Text('Practice Again'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScoreCard(Color cardBg, Color borderColor, Color primaryColor, Color secColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated circular score ring
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final scoreVal = _scoreAnimation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: scoreVal / 100,
                      strokeWidth: 10,
                      backgroundColor: primaryColor.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scoreVal.round()}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 54,
                            ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Grade Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getEmoji(_myScore),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'GRADE $_grade',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Confidence: $_confidence%',
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJudgesDashboard(Color cardBg, Color borderColor, Color primaryColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
              Text(
                'AI Judging Scorecard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreBar('Object Recognition (40%)', _objScore, primaryColor),
          const SizedBox(height: 16),
          _buildScoreBar('Required Features (25%)', _featScore, primaryColor),
          const SizedBox(height: 16),
          _buildScoreBar('Composition (15%)', _compScore, primaryColor),
          const SizedBox(height: 16),
          _buildScoreBar('Creativity (10%)', _creatScore, primaryColor),
          const SizedBox(height: 16),
          _buildScoreBar('Stroke Quality (10%)', _strokeScore, primaryColor),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$value/100', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              )),
        ],
      ),
    );
  }
}
