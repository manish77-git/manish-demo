import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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

  int _objScore = 0;
  int _featScore = 0;
  int _compScore = 0;
  int _creatScore = 0;
  int _strokeScore = 0;
  List<String> _strengths = [];
  List<String> _weaknesses = [];

  // Multiplayer variables
  bool _isMultiplayer = false;
  String? _gameId;
  Map<String, dynamic>? _drawingsData;
  bool _loadingDrawings = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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

        _objScore = args['objectRecognitionScore'] as int? ?? (_myScore * 0.9).round();
        _featScore = args['requiredFeaturesScore'] as int? ?? (_myScore * 0.85).round();
        _compScore = args['compositionScore'] as int? ?? (_myScore * 0.95).round();
        _creatScore = args['creativityScore'] as int? ?? (_myScore * 0.88).round();
        _strokeScore = args['strokeQualityScore'] as int? ?? (_myScore * 0.9).round();

        _strengths = List<String>.from(args['strengths'] as List? ?? []);
        _weaknesses = List<String>.from(args['weaknesses'] as List? ?? []);

        _isMultiplayer = args['isMultiplayer'] == true;
        _gameId = args['gameId'] as String?;

        _scoreAnimation = Tween<double>(begin: 0, end: _myScore.toDouble()).animate(
          CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
        );
        _scoreController.forward();
      });

      if (_isMultiplayer && _gameId != null) {
        _fetchGameDrawings();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _fetchGameDrawings() async {
    if (_gameId == null) return;
    setState(() => _loadingDrawings = true);
    try {
      final auth = context.read<AuthProvider>();
      final response = await http.get(
        Uri.parse('${ApiConfig.serverUrl}/api/drawings/$_gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.idToken}',
        },
      );
      final json = jsonDecode(response.body);
      if (json['success'] == true && mounted) {
        setState(() {
          _drawingsData = json['data'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error fetching game drawings: $e');
    } finally {
      if (mounted) setState(() => _loadingDrawings = false);
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'S':
      case 'A+':
      case 'A':
        return AppTheme.accentLight;
      case 'B+':
      case 'B':
        return AppTheme.accentCyan;
      case 'C+':
      case 'C':
        return AppTheme.accentYellow;
      default:
        return AppTheme.accentCoral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    final myUid = context.read<AuthProvider>().uid;

    // Resolve multiplayer winner & opponent data
    Map<String, dynamic>? opponentStats;
    String winnerText = '';
    Color winnerColor = primaryColor;

    if (_drawingsData != null) {
      final drawingsMap = _drawingsData!['drawings'] as Map<String, dynamic>;
      final opponentId = drawingsMap.keys.firstWhere((uid) => uid != myUid, orElse: () => '');
      if (opponentId.isNotEmpty) {
        opponentStats = drawingsMap[opponentId] as Map<String, dynamic>?;
      }

      final myScoreVal = drawingsMap[myUid]?['score'] as int? ?? _myScore;
      final opponentScoreVal = opponentStats?['score'] as int? ?? 0;

      if (myScoreVal > opponentScoreVal) {
        winnerText = 'Victory! You Won! 🏆';
        winnerColor = AppTheme.accentLight;
      } else if (opponentScoreVal > myScoreVal) {
        final oppName = opponentStats?['displayName'] ?? 'Opponent';
        winnerText = '$oppName Won! 👑';
        winnerColor = AppTheme.accentCoral;
      } else {
        winnerText = "It's a Tie! 🤝";
        winnerColor = AppTheme.accentYellow;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Stack(
        children: [
          // Sketchpad background grid
          Positioned.fill(
            child: CustomPaint(
              painter: SketchpadBackgroundPainter(
                gridColor: textColor,
                isDark: isDark,
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header panel
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isMultiplayer ? 'Match Results' : 'Practice Evaluation',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    'Prompt: ${_prompt.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Grade Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: AppTheme.gameCardDecoration(
                                color: _gradeColor(_grade).withOpacity(0.12),
                                borderColor: borderColor,
                                shadowColor: borderColor,
                                radius: AppTheme.radiusSmall,
                              ),
                              child: Text(
                                'GRADE $_grade',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _gradeColor(_grade),
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Winner declaration card if multiplayer
                        if (_isMultiplayer && winnerText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: AppTheme.gameCardDecoration(
                              color: winnerColor.withOpacity(0.08),
                              borderColor: borderColor,
                              shadowColor: winnerColor,
                              radius: AppTheme.radiusMedium,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.trophy, color: winnerColor, size: 24),
                                const SizedBox(width: AppTheme.space12),
                                Text(
                                  winnerText,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),
                        ],

                        // Leaderboard / Final Standings
                        if (_isMultiplayer && _drawingsData != null) ...[
                          _buildLeaderboardCard(
                            _drawingsData!['drawings'] as Map<String, dynamic>,
                            myUid,
                            cardBg,
                            borderColor,
                            textColor,
                            primaryColor,
                          ),
                          const SizedBox(height: AppTheme.space24),
                        ],

                        // Main Score and Judges side-by-side
                        if (!_isMultiplayer)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: _buildMainScoreCard(
                                cardBg,
                                borderColor,
                                primaryColor,
                                textColor,
                                textMuted,
                                isDark,
                              ),
                            ),
                          )
                        else
                          MediaQuery.of(context).size.width > 620
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildMainScoreCard(
                                        cardBg,
                                        borderColor,
                                        primaryColor,
                                        textColor,
                                        textMuted,
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space24),
                                    Expanded(
                                      flex: 3,
                                      child: _buildJudgesDashboard(
                                        cardBg,
                                        borderColor,
                                        primaryColor,
                                        textMuted,
                                        textColor,
                                        isDark,
                                        opponentStats: opponentStats,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildMainScoreCard(
                                      cardBg,
                                      borderColor,
                                      primaryColor,
                                      textColor,
                                      textMuted,
                                      isDark,
                                    ),
                                    const SizedBox(height: AppTheme.space24),
                                    _buildJudgesDashboard(
                                      cardBg,
                                      borderColor,
                                      primaryColor,
                                      textMuted,
                                      textColor,
                                      isDark,
                                      opponentStats: opponentStats,
                                    ),
                                  ],
                                ),
                        const SizedBox(height: AppTheme.space24),

                        // Strengths & Weaknesses Cards
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildFeedbackCard(
                                title: 'Strengths',
                                items: _strengths.isNotEmpty ? _strengths : ['Good basic outlines', 'Recognizable form'],
                                icon: LucideIcons.checkCircle,
                                iconColor: isDark ? AppTheme.accentDark : AppTheme.accentLight,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                isDark: isDark,
                                shadowColor: isDark ? AppTheme.accentDark : AppTheme.accentLight,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space16),
                            Expanded(
                              child: _buildFeedbackCard(
                                title: 'Improvement',
                                items: _weaknesses.isNotEmpty ? _weaknesses : ['Add secondary details', 'Outline consistency'],
                                icon: LucideIcons.alertTriangle,
                                iconColor: AppTheme.accentYellow,
                                cardBg: cardBg,
                                borderColor: borderColor,
                                textColor: textColor,
                                isDark: isDark,
                                shadowColor: AppTheme.accentYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Analysis bubble
                        if (_explanation.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: AppTheme.gameCardDecoration(
                              color: cardBg,
                              borderColor: borderColor,
                              shadowColor: primaryColor.withOpacity(0.2),
                              radius: AppTheme.radiusLarge,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.sparkles, color: primaryColor, size: 16),
                                    const SizedBox(width: AppTheme.space8),
                                    Text(
                                      'AI Judge Feedback',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.space12),
                                ..._explanation.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '· $e',
                                        style: TextStyle(fontSize: 13, height: 1.5, color: textColor, fontWeight: FontWeight.bold),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space32),
                        ],

                        // Play CTA
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                                child: const Text('Back to Home'),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space16),
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: AppTheme.gameCardDecoration(
                                  color: primaryColor,
                                  borderColor: borderColor,
                                  shadowColor: borderColor,
                                  radius: AppTheme.radiusMedium,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_isMultiplayer) {
                                      Navigator.pushReplacementNamed(context, '/matchmaking');
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/drawing');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                  ),
                                  child: Text(
                                    _isMultiplayer ? 'Find Duel' : 'Play Again',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _buildMainScoreCard(Color cardBg, Color borderColor, Color primaryColor, Color textColor, Color textMuted, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              final scoreVal = _scoreAnimation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: scoreVal / 100,
                      strokeWidth: 8,
                      backgroundColor: borderColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scoreVal.round()}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textMuted, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Text(
              'Confidence: $_confidence%',
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJudgesDashboard(
    Color cardBg,
    Color borderColor,
    Color primaryColor,
    Color textMuted,
    Color textColor,
    bool isDark, {
    Map<String, dynamic>? opponentStats,
  }) {
    final opponentName = opponentStats?['displayName'] ?? 'Opponent';

    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evaluation Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
              if (_isMultiplayer)
                Text(
                  'vs $opponentName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.accentCyan),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space24),
          _buildDuelScoreBar(
            'Object Recognition (40%)',
            _objScore,
            opponentStats?['objectRecognitionScore'] as int?,
            primaryColor,
            borderColor,
            textColor,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildDuelScoreBar(
            'Required Features (25%)',
            _featScore,
            opponentStats?['requiredFeaturesScore'] as int?,
            primaryColor,
            borderColor,
            textColor,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildDuelScoreBar(
            'Composition (15%)',
            _compScore,
            opponentStats?['compositionScore'] as int?,
            primaryColor,
            borderColor,
            textColor,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildDuelScoreBar(
            'Creativity (10%)',
            _creatScore,
            opponentStats?['creativityScore'] as int?,
            primaryColor,
            borderColor,
            textColor,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildDuelScoreBar(
            'Stroke Quality (10%)',
            _strokeScore,
            opponentStats?['strokeQualityScore'] as int?,
            primaryColor,
            borderColor,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDuelScoreBar(
    String label,
    int myVal,
    int? oppVal,
    Color color,
    Color borderColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
            Text(
              oppVal == null ? '$myVal/100' : 'YOU: $myVal  |  THEM: $oppVal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              LinearProgressIndicator(
                value: myVal / 100,
                minHeight: 8,
                backgroundColor: borderColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              if (oppVal != null)
                Positioned(
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: oppVal / 100,
                      child: Container(
                        height: 2,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ),
            ],
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
    required Color textColor,
    required bool isDark,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: shadowColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: AppTheme.space8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '· $item',
                  style: TextStyle(fontSize: 12, height: 1.5, color: textColor, fontWeight: FontWeight.bold),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(
    Map<String, dynamic> drawingsMap,
    String myUid,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
  ) {
    final sortedPlayers = drawingsMap.entries.toList()
      ..sort((a, b) => ((b.value['score'] as num? ?? 0).toInt()).compareTo((a.value['score'] as num? ?? 0).toInt()));

    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor.withOpacity(0.15),
        radius: AppTheme.radiusLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listOrdered, color: primaryColor, size: 18),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Final Standings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          ...sortedPlayers.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final pUid = item.key;
            final pData = item.value as Map<String, dynamic>;
            final pName = pData['displayName'] ?? 'Player';
            final pScore = (pData['score'] as num? ?? 0).toInt();
            final pGrade = pData['grade'] as String? ?? 'F';
            final isMe = pUid == myUid;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? primaryColor.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isMe ? Border.all(color: primaryColor, width: 1.5) : null,
              ),
              child: Row(
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: rank == 1 ? AppTheme.accentYellow : textColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (rank == 1)
                    const Icon(LucideIcons.trophy, size: 16, color: AppTheme.accentYellow)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMe ? '$pName (You)' : pName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    'Grade $pGrade',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _gradeColor(pGrade),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$pScore pts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
