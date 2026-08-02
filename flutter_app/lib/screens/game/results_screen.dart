import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/confetti_painter.dart';
import '../../widgets/doodle_painter.dart';
import '../../services/audio_service.dart';
import '../../services/prompt_service.dart';

enum ResultStage {
  judging,
  winnerReveal,
  scoreReveal,
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  ResultStage _stage = ResultStage.judging;

  int _myScore = 0;
  String _prompt = '';
  String _grade = 'F';

  bool _isMultiplayer = false;
  String? _gameId;
  Map<String, dynamic>? _drawingsData;
  bool _isSinglePlayerChallenge = false;
  int _currentRound = 1;
  int _totalRounds = 5;
  int _cumulativeScore = 0;
  bool _scoreSaved = false;

  bool _stageInitialized = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stageInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _stageInitialized = true;

      _myScore = args['score'] as int? ?? 0;
      _prompt = args['prompt'] as String? ?? '';
      _grade = args['grade'] as String? ?? 'F';

      _isMultiplayer = args['isMultiplayer'] == true;
      _gameId = args['gameId'] as String?;
      if (args.containsKey('drawingsData') && args['drawingsData'] is Map<String, dynamic>) {
        _drawingsData = args['drawingsData'] as Map<String, dynamic>;
      }

      _isSinglePlayerChallenge = args['isSinglePlayerChallenge'] == true;
      _currentRound = args['currentRound'] as int? ?? 1;
      _totalRounds = args['totalRounds'] as int? ?? 5;
      _cumulativeScore = args['cumulativeScore'] as int? ?? _myScore;

      _saveMatchScoreIfNeeded();
      _startResultFlow();

      if (_isMultiplayer && _gameId != null && _drawingsData == null) {
        _fetchGameDrawings();
      }
    }
  }

  void _startResultFlow() {
    // ─── Phase 1: Suspense Animation (2.2 seconds) ───────────
    setState(() => _stage = ResultStage.judging);

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;

      // ─── Phase 2: Winner Reveal Animation (2.8 seconds) ─────
      setState(() => _stage = ResultStage.winnerReveal);
      AudioService().playVictory();

      Future.delayed(const Duration(milliseconds: 2800), () {
        if (!mounted) return;

        // ─── Phase 3: Final Scores & Drawings Reveal ───────────
        setState(() => _stage = ResultStage.scoreReveal);
        AudioService().playScoreReveal();
      });
    });
  }

  void _saveMatchScoreIfNeeded({bool isLeavingEarly = false}) {
    if (_scoreSaved || _isMultiplayer) return;

    final isChallengeComplete = _isSinglePlayerChallenge && (_totalRounds > 0 && _currentRound >= _totalRounds);
    final isPracticeSoloMode = !_isSinglePlayerChallenge;

    if (isChallengeComplete || isPracticeSoloMode || isLeavingEarly) {
      _scoreSaved = true;
      final auth = context.read<AuthProvider>();
      final avgScore = (_currentRound > 0) ? (_cumulativeScore / _currentRound).round() : _myScore;
      auth.saveSinglePlayerScore(
        totalScore: _cumulativeScore,
        roundsCount: _currentRound,
        totalRounds: _totalRounds,
        averageScore: avgScore,
      );
    }
  }

  Future<void> _fetchGameDrawings() async {
    if (_gameId == null) return;
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
      debugPrint('[ResultsScreen] Error fetching drawings: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final drawingsMap = _drawingsData?['drawings'] as Map<String, dynamic>? ?? {};
    String myUid = context.read<AuthProvider>().uid;

    if (_isMultiplayer && drawingsMap.isNotEmpty) {
      if (!drawingsMap.containsKey(myUid)) {
        final myDisplayName = context.read<AuthProvider>().displayName;
        final match = drawingsMap.entries.firstWhere(
          (e) => (e.value as Map)['displayName'] == myDisplayName,
          orElse: () => const MapEntry('', {}),
        );
        if (match.key.isNotEmpty) {
          myUid = match.key;
        } else {
          final socketProvider = context.read<SocketProvider>();
          final roomPlayers = socketProvider.roomPlayers;
          final mySocketPlayer = roomPlayers.firstWhere((p) => p['displayName'] == myDisplayName, orElse: () => {});
          if (mySocketPlayer.containsKey('uid') && drawingsMap.containsKey(mySocketPlayer['uid'])) {
            myUid = mySocketPlayer['uid'] as String;
          } else if (drawingsMap.isNotEmpty) {
            myUid = drawingsMap.keys.first;
          }
        }
      }
    }

    Map<String, dynamic>? myData = drawingsMap[myUid] as Map<String, dynamic>?;
    final myScoreVal = (myData?['score'] as num? ?? _myScore).toInt();
    final myName = myData?['displayName'] as String? ?? context.read<AuthProvider>().displayName;

    Map<String, dynamic>? opponentData;
    String opponentUid = '';
    if (_isMultiplayer && drawingsMap.isNotEmpty) {
      opponentUid = drawingsMap.keys.firstWhere((uid) => uid != myUid, orElse: () => '');
      if (opponentUid.isNotEmpty) {
        opponentData = drawingsMap[opponentUid] as Map<String, dynamic>?;
      }
    }
    final opponentScoreVal = (opponentData?['score'] as num? ?? 0).toInt();
    final opponentName = opponentData?['displayName'] as String? ?? 'Opponent';

    // Winner calculations
    final isTie = _isMultiplayer && (myScoreVal == opponentScoreVal);
    final isIWon = _isMultiplayer && (myScoreVal > opponentScoreVal);
    final winnerName = isTie ? "It's a Draw!" : (isIWon ? myName : opponentName);

    return Scaffold(
      body: ConfettiOverlay(
        trigger: _stage == ResultStage.winnerReveal || _stage == ResultStage.scoreReveal,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DoodlePainter(primaryColor: primaryColor, isDark: isDark),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildStageContent(
                    context,
                    cardBg,
                    borderColor,
                    textColor,
                    primaryColor,
                    isDark,
                    myUid,
                    myName,
                    myScoreVal,
                    opponentUid,
                    opponentName,
                    opponentScoreVal,
                    winnerName,
                    isIWon,
                    isTie,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageContent(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
    bool isDark,
    String myUid,
    String myName,
    int myScore,
    String opponentUid,
    String opponentName,
    int opponentScore,
    String winnerName,
    bool isIWon,
    bool isTie,
  ) {
    switch (_stage) {
      case ResultStage.judging:
        return _buildJudgingPhase(context, cardBg, borderColor, textColor, primaryColor);
      case ResultStage.winnerReveal:
        return _buildWinnerRevealPhase(context, cardBg, borderColor, textColor, primaryColor, winnerName, isIWon, isTie);
      case ResultStage.scoreReveal:
        return _buildScoreRevealPhase(
          context,
          cardBg,
          borderColor,
          textColor,
          primaryColor,
          isDark,
          myUid,
          myName,
          myScore,
          opponentUid,
          opponentName,
          opponentScore,
          winnerName,
          isIWon,
          isTie,
        );
    }
  }

  // ─── PHASE 1: Suspense / Judging Animation ─────────────────────

  Widget _buildJudgingPhase(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
  ) {
    return KeyedSubtree(
      key: const ValueKey('stage_judging'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.gameCard(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _glowAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.12),
                      border: Border.all(color: primaryColor.withOpacity(0.5), width: 3),
                    ),
                    child: Icon(LucideIcons.sparkles, size: 54, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'AI IS JUDGING...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Evaluating drawing accuracy for prompt "${_prompt.toUpperCase()}"',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    backgroundColor: primaryColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── PHASE 2: Dramatic Winner Reveal ───────────────────────────

  Widget _buildWinnerRevealPhase(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
    String winnerName,
    bool isIWon,
    bool isTie,
  ) {
    final winnerColor = isTie ? AppColors.sunny : (isIWon ? AppColors.mint : AppColors.coral);

    return KeyedSubtree(
      key: const ValueKey('stage_winner_reveal'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: winnerColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: winnerColor.withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _glowAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: winnerColor.withOpacity(0.15),
                      border: Border.all(color: winnerColor, width: 3),
                    ),
                    child: Icon(
                      isTie ? LucideIcons.handshake : LucideIcons.trophy,
                      size: 64,
                      color: winnerColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isTie ? '🤝 IT\'S A DRAW!' : '🏆 WINNER 🏆',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: winnerColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  winnerName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: winnerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: winnerColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    isTie ? 'EQUAL SCORES!' : (isIWon ? 'VICTORY IS YOURS!' : 'WELL FOUGHT!'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: winnerColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── PHASE 3: Score & Side-by-Side Drawings Reveal ─────────────

  Widget _buildScoreRevealPhase(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
    bool isDark,
    String myUid,
    String myName,
    int myScore,
    String opponentUid,
    String opponentName,
    int opponentScore,
    String winnerName,
    bool isIWon,
    bool isTie,
  ) {
    return KeyedSubtree(
      key: const ValueKey('stage_score_reveal'),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Center(
                  child: Column(
                    children: [
                      Text(
                        _isMultiplayer ? 'MATCH RESULTS' : 'DRAWING SCORE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PROMPT: ${_prompt.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Winner Headline Card
                if (_isMultiplayer)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isTie ? AppColors.sunny.withOpacity(0.12) : (isIWon ? AppColors.mint.withOpacity(0.12) : AppColors.coral.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTie ? AppColors.sunny : (isIWon ? AppColors.mint : AppColors.coral),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTie ? LucideIcons.handshake : LucideIcons.crown,
                          color: isTie ? AppColors.sunny : (isIWon ? AppColors.mint : AppColors.coral),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isTie ? "It's a Draw! 🤝" : (isIWon ? "Victory! You Won! 🏆" : "$opponentName Won! 👑"),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Side by Side Sketches (or Single Player Canvas)
                if (_isMultiplayer)
                  _buildSideBySideDrawings(
                    context,
                    cardBg,
                    borderColor,
                    textColor,
                    primaryColor,
                    myUid,
                    myName,
                    myScore,
                    opponentUid,
                    opponentName,
                    opponentScore,
                    isIWon,
                    isTie,
                  )
                else
                  _buildSinglePlayerDrawingCard(
                    context,
                    cardBg,
                    borderColor,
                    textColor,
                    primaryColor,
                    myName,
                    myScore,
                  ),

                const SizedBox(height: 32),

                // Action Buttons Only: Play Again & Back to Home
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isMultiplayer) {
                            final socketProvider = context.read<SocketProvider>();
                            socketProvider.emitRematch();
                            Navigator.pushReplacementNamed(
                              context,
                              '/lobby',
                              arguments: socketProvider.roomCode,
                            );
                          } else if (_isSinglePlayerChallenge) {
                            if (_currentRound < _totalRounds) {
                              final nextRoundPrompt = PromptService().getRandomPrompt();
                              Navigator.pushReplacementNamed(
                                context,
                                '/drawing',
                                arguments: {
                                  'prompt': nextRoundPrompt,
                                  'isSinglePlayerChallenge': true,
                                  'currentRound': _currentRound + 1,
                                  'totalRounds': _totalRounds,
                                  'cumulativeScore': _cumulativeScore,
                                },
                              );
                            } else {
                              Navigator.pushReplacementNamed(context, '/single_player');
                            }
                          } else {
                            Navigator.pushReplacementNamed(context, '/drawing');
                          }
                        },
                        icon: const Icon(LucideIcons.rotateCcw, size: 20),
                        label: Text(
                          _isMultiplayer
                              ? 'Play Again'
                              : (_isSinglePlayerChallenge && _currentRound < _totalRounds ? 'Next Round' : 'Play Again'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        icon: const Icon(LucideIcons.home, size: 20),
                        label: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: borderColor, width: 2),
                          foregroundColor: textColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }

  // ─── Side-by-Side Drawings Card ─────────────────────────────────

  Widget _buildSideBySideDrawings(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
    String myUid,
    String myName,
    int myScore,
    String opponentUid,
    String opponentName,
    int opponentScore,
    bool isIWon,
    bool isTie,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;

        final myCard = _buildPlayerCanvasCard(
          context,
          uid: myUid,
          name: '$myName (You)',
          score: myScore,
          isWinner: isIWon && !isTie,
          isTie: isTie,
          accentColor: primaryColor,
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
        );

        final opponentCard = _buildPlayerCanvasCard(
          context,
          uid: opponentUid,
          name: opponentName,
          score: opponentScore,
          isWinner: !isIWon && !isTie,
          isTie: isTie,
          accentColor: AppColors.coral,
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: myCard),
              const SizedBox(width: 16),
              Expanded(child: opponentCard),
            ],
          );
        } else {
          return Column(
            children: [
              myCard,
              const SizedBox(height: 16),
              opponentCard,
            ],
          );
        }
      },
    );
  }

  // ─── Individual Player Canvas Card ──────────────────────────────

  Widget _buildPlayerCanvasCard(
    BuildContext context, {
    required String uid,
    required String name,
    required int score,
    required bool isWinner,
    required bool isTie,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    final goldColor = const Color(0xFFFFD700);
    final borderToUse = isWinner ? goldColor : borderColor;
    final borderWidth = isWinner ? 3.0 : 1.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderToUse, width: borderWidth),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: goldColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.crown, size: 14, color: goldColor),
                      const SizedBox(width: 4),
                      Text(
                        'WINNER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Canvas Box
          AspectRatio(
            aspectRatio: 1.2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black38 : Colors.grey[100],
                child: _buildDrawingImageWidget(uid, textColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Animated Score Count-Up
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isWinner ? goldColor.withOpacity(0.1) : accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWinner ? goldColor.withOpacity(0.4) : accentColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${val.round()}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isWinner ? goldColor : accentColor,
                      ),
                    ),
                    Text(
                      'POINTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: textColor.withOpacity(0.6),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Single Player Drawing Card ────────────────────────────────

  Widget _buildSinglePlayerDrawingCard(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryColor,
    String name,
    int score,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gameCard(context),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black38 : Colors.grey[100],
                child: _buildDrawingImageWidget(context.read<AuthProvider>().uid, textColor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Column(
                children: [
                  Text(
                    '${val.round()}',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryColor),
                  ),
                  Text(
                    'FINAL SCORE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textColor.withOpacity(0.6), letterSpacing: 1.0),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Drawing Image Renderer ────────────────────────────────────

  Widget _buildDrawingImageWidget(String uid, Color textColor) {
    try {
      final imgDataStr = _drawingsData?['drawings']?[uid]?['imageData'] as String?;
      if (imgDataStr != null && imgDataStr.startsWith('data:image')) {
        final base64Part = imgDataStr.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(textColor),
        );
      }
    } catch (e) {
      debugPrint('[ResultsScreen] Error decoding base64 image: $e');
    }

    if (_gameId != null && uid.isNotEmpty) {
      final fallbackUrl = '${ApiConfig.serverUrl}/api/drawings/$_gameId/image/$uid';
      return Image.network(
        fallbackUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(textColor),
      );
    }

    return _buildImagePlaceholder(textColor);
  }

  Widget _buildImagePlaceholder(Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.image, size: 36, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            'Canvas Sketch',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.4), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
