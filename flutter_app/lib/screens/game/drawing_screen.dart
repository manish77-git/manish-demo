import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../widgets/mascot_painter.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../widgets/drawing_canvas.dart';
import '../../widgets/custom_color_picker.dart';
import '../../services/drawing_service.dart';
import '../../services/api_service.dart';
import '../../services/prompt_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/drawing_submission.dart';
import '../../services/audio_service.dart';

const List<String> _practicePrompts = [
  'cat', 'dog', 'house', 'tree', 'sun', 'car', 'flower', 'fish',
  'bird', 'star', 'moon', 'apple', 'pizza', 'robot', 'rocket',
  'umbrella', 'guitar', 'cake', 'hat', 'boat', 'dragon', 'castle',
  'rainbow', 'butterfly', 'snowman', 'dinosaur', 'penguin', 'sword',
  'crown', 'diamond',
];

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  String _currentPrompt = 'Loading...';
  int _timeLeft = 80;
  Timer? _timer;
  bool _isEvaluating = false;
  bool _isMultiplayer = false;
  bool _isSpectator = false;
  bool _hasFetchedPrompt = false;

  // Live Score State
  int _lastStrokeCount = 0;
  Timer? _analysisDebounce;
  bool _isAnalyzing = false;
  int _aiConfidence = 0;
  String _aiDetectedObject = 'nothing';
  String _aiSuggestion = 'Start drawing to get live suggestions.';

  final Map<String, Map<String, dynamic>> _opponentLiveMetrics = {};
  int _evaluatingMsgIndex = 0;
  Timer? _evaluatingMsgTimer;

  static const List<String> _evaluatingMessages = [
    'Analyzing your drawing...',
    'Comparing with the prompt...',
    'Generating feedback...',
    'Calculating score...',
  ];

  bool _isSinglePlayerChallenge = false;
  int _currentRound = 1;
  int _totalRounds = 5;
  int _cumulativeScore = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasFetchedPrompt) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _prompt = args['prompt'] as String?;
      final duration = args['duration'] as int?;
      _isMultiplayer = args['isMultiplayer'] == true;
      _isSpectator = args['isSpectator'] == true;
      _isSinglePlayerChallenge = args['isSinglePlayerChallenge'] == true;
      _currentRound = args['currentRound'] as int? ?? 1;
      _totalRounds = args['totalRounds'] as int? ?? 5;
      _cumulativeScore = args['cumulativeScore'] as int? ?? 0;

      if (duration != null && duration > 0) {
        _timeLeft = duration;
      }
    }

    if (_prompt != null && _prompt!.isNotEmpty) {
      _currentPrompt = _prompt!;
      _hasFetchedPrompt = true;
    } else {
      _fetchRandomPrompt();
      _hasFetchedPrompt = true;
    }
  }

  String? _prompt;
  final math.Random _random = math.Random();

  Future<void> _fetchRandomPrompt() async {
    try {
      final promptObj = PromptService().getRandomPrompt();
      if (mounted) {
        setState(() {
          _currentPrompt = promptObj.text;
        });
      }
    } catch (e) {
      debugPrint('[DrawingScreen] Error fetching random prompt: $e');
      if (mounted) {
        setState(() {
          _currentPrompt = _practicePrompts[_random.nextInt(_practicePrompts.length)];
        });
      }
    }
  }

  Future<void> _syncTimerWithServer() async {
    try {
      final socketProvider = context.read<SocketProvider>();
      final gameId = socketProvider.roomCode;
      if (gameId == null || gameId.isEmpty) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.serverUrl}/api/games/$gameId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        final sessionData = data['data']['session'] as Map<String, dynamic>;
        final serverTimeStr = data['data']['serverTime'] as String?;
        if (serverTimeStr != null && sessionData.containsKey('startedAt')) {
          final startedAt = DateTime.parse(sessionData['startedAt'] as String);
          final serverTime = DateTime.parse(serverTimeStr);
          final drawingTimeSeconds = sessionData['drawingTimeSeconds'] as int? ?? 80;

          final elapsedSeconds = serverTime.difference(startedAt).inSeconds;
          final remaining = drawingTimeSeconds - elapsedSeconds;

          setState(() {
            _timeLeft = math.max(0, remaining);
            if (_timeLeft == 0) {
              _timer?.cancel();
              _handleTimeUp();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[DrawingScreen] Error syncing timer: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPrompt = 'Loading...';

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
            // Play tick sounds
            if (_timeLeft <= 10 && _timeLeft > 0) {
              AudioService().playTick(isLowTime: true);
            } else if (_timeLeft <= 30 && _timeLeft > 0 && _timeLeft % 5 == 0) {
              AudioService().playTick();
            }
          } else {
            _timer?.cancel();
            AudioService().playRoundEnd();
            _handleTimeUp();
          }
        });
      }
    });

    // Play round start sound
    AudioService().playRoundStart();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawing = context.read<DrawingProvider>();
      drawing.reset();
      drawing.addListener(_onStrokesChanged);

      Timer.periodic(const Duration(seconds: 10), (t) {
        if (mounted && _isMultiplayer && _timeLeft > 0) {
          _syncTimerWithServer();
        } else {
          t.cancel();
        }
      });

      if (_isMultiplayer) {
        final socketProvider = context.read<SocketProvider>();

        if (!_isSpectator) {
          drawing.onLocalStrokesChanged = (strokesJson) {
            socketProvider.emitStroke(strokesJson);
          };
          drawing.onLocalCursorMoved = (x, y) {
            socketProvider.emitCursor(x, y);
          };
          drawing.onLocalCanvasCleared = () {
            socketProvider.emitClear();
          };
        }

        socketProvider.onDrawingHistory = (history) {
          drawing.loadDrawingHistory(history);
        };
        socketProvider.onDrawingStroke = (userId, strokes) {
          final name = socketProvider.roomPlayers.firstWhere(
            (p) => p['uid'] == userId,
            orElse: () => {'displayName': 'Opponent'},
          )['displayName'] as String;
          drawing.updateOpponentStrokes(userId, name, strokes);
        };
        socketProvider.onDrawingClear = (userId) {
          drawing.clearOpponent(userId);
        };
        socketProvider.onDrawingCursor = (userId, x, y) {
          drawing.updateOpponentCursor(userId, x, y);
        };
        socketProvider.onLiveMetrics = (userId, metrics) {
          if (mounted) {
            setState(() {
              _opponentLiveMetrics[userId] = metrics;
            });
          }
        };
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _analysisDebounce?.cancel();
    _evaluatingMsgTimer?.cancel();
    try {
      final drawing = context.read<DrawingProvider>();
      drawing.removeListener(_onStrokesChanged);
      drawing.onLocalStrokesChanged = null;
      drawing.onLocalCursorMoved = null;
      drawing.onLocalCanvasCleared = null;

      final socketProvider = context.read<SocketProvider>();
      socketProvider.onDrawingHistory = null;
      socketProvider.onDrawingStroke = null;
      socketProvider.onDrawingClear = null;
      socketProvider.onDrawingCursor = null;
      socketProvider.onLiveMetrics = null;
    } catch (_) {}
    super.dispose();
  }

  void _onStrokesChanged() {
    if (!mounted) return;
    final drawing = context.read<DrawingProvider>();
    if (drawing.strokes.length > _lastStrokeCount) {
      final lastStroke = drawing.strokes.last;
      if (lastStroke.toolType == DrawingToolType.fill) {
        AudioService().playFillBucket();
      } else if (lastStroke.isEraser) {
        AudioService().playErase();
      } else {
        AudioService().playBrushDraw();
      }
      _lastStrokeCount = drawing.strokes.length;
      _triggerLiveAnalysisDebounced();
    } else if (drawing.strokes.length != _lastStrokeCount) {
      _lastStrokeCount = drawing.strokes.length;
      _triggerLiveAnalysisDebounced();
    }
  }

  void _triggerLiveAnalysisDebounced() {
    _analysisDebounce?.cancel();
    _analysisDebounce = Timer(const Duration(milliseconds: 2500), () {
      _runLiveAnalysis();
    });
  }

  Future<void> _runLiveAnalysis() async {
    if (!mounted || _isEvaluating || _isAnalyzing) return;
    final drawing = context.read<DrawingProvider>();
    final auth = context.read<AuthProvider>();

    if (drawing.strokes.isEmpty) {
      setState(() {
        _aiConfidence = 0;
        _aiDetectedObject = 'nothing';
        _aiSuggestion = 'Draw something to begin.';
      });
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await drawing.exportToPng(const Size(200, 200));
      if (bytes == null || !mounted) return;

      final service = DrawingService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => auth.idToken,
      );

      final result = await service.analyzeLiveDrawing(
        prompt: _currentPrompt,
        drawingBytes: bytes,
      );

      if (mounted) {
        setState(() {
          _aiConfidence = result['recognitionRate'] as int? ?? 0;
          _aiDetectedObject = result['detectedObject'] as String? ?? 'unknown';
          _aiSuggestion = result['suggestions'] as String? ?? '';
        });

        if (_isMultiplayer) {
          final socketProvider = context.read<SocketProvider>();
          socketProvider.emitLiveMetrics({
            'score': _aiConfidence,
            'detectedObject': _aiDetectedObject,
            'suggestions': _aiSuggestion,
          });
        }
      }
    } catch (e) {
      debugPrint('[DrawingScreen] Error in live analysis: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _handleTimeUp() {
    if (_isEvaluating) return;
    _handleSubmit();
  }

  void _pickNewWord() {
    if (_isMultiplayer) return;
    context.read<DrawingProvider>().reset();
    _fetchRandomPrompt();
  }

  Future<void> _handleSubmit() async {
    if (_isEvaluating) return;

    setState(() {
      _isEvaluating = true;
      _evaluatingMsgIndex = 0;
    });

    _evaluatingMsgTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (mounted && _isEvaluating) {
        setState(() {
          _evaluatingMsgIndex = (_evaluatingMsgIndex + 1) % _evaluatingMessages.length;
        });
      } else {
        t.cancel();
      }
    });

    final drawing = context.read<DrawingProvider>();
    final auth = context.read<AuthProvider>();

    try {
      final bytes = await drawing.exportToPng(const Size(400, 400));
      final socketProvider = context.read<SocketProvider>();
      final roomCode = socketProvider.roomCode;

      final service = DrawingService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => auth.idToken,
      );

      DrawingResult result;
      if (_isMultiplayer && roomCode != null && roomCode.isNotEmpty) {
        result = await service.submitDrawing(
          gameId: roomCode,
          drawingBytes: bytes ?? Uint8List(0),
        );
      } else {
        result = await service.evaluateSoloDrawing(
          prompt: _currentPrompt,
          drawingBytes: bytes ?? Uint8List(0),
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: {
            'score': result.score,
            'grade': result.grade,
            'confidence': result.confidence,
            'explanation': result.explanation,
            'labels': result.labels,
            'objectRecognitionScore': result.objectRecognitionScore,
            'requiredFeaturesScore': result.requiredFeaturesScore,
            'compositionScore': result.compositionScore,
            'creativityScore': result.creativityScore,
            'strokeQualityScore': result.strokeQualityScore,
            'strengths': result.strengths,
            'weaknesses': result.weaknesses,
            'prompt': _currentPrompt,
            'isMultiplayer': _isMultiplayer,
            'gameId': roomCode,
            'isSinglePlayerChallenge': _isSinglePlayerChallenge,
            'currentRound': _currentRound,
            'totalRounds': _totalRounds,
            'cumulativeScore': _cumulativeScore + result.score,
          },
        );
      }
    } catch (e) {
      debugPrint('[DrawingScreen] Evaluation error: $e');
      if (mounted) {
        setState(() => _isEvaluating = false);
        _showEvaluationErrorDialog();
      }
    }
  }

  void _showEvaluationErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: const Row(
            children: [
              Icon(LucideIcons.alertCircle, color: AppColors.coral, size: 24),
              SizedBox(width: 10),
              Text('Evaluation Error', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          content: const Text(
            'AI evaluation failed. Please try again.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _handleSubmit();
              },
              icon: const Icon(LucideIcons.rotateCw, size: 16, color: Colors.white),
              label: const Text('Retry Evaluation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                _buildTopBar(isDark, borderColor, textColor, textMuted, primaryColor, cardBg),

                // Workspace
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isSpectator) ...[
                                _buildLeftToolbar(isDark, cardBg, borderColor, textColor, textMuted, primaryColor),
                                const SizedBox(width: AppTheme.space16),
                              ],
                              Expanded(
                                flex: 3,
                                child: _buildCanvasArea(borderColor, primaryColor, cardBg),
                              ),
                              const SizedBox(width: AppTheme.space16),
                              Expanded(
                                flex: 2,
                                child: _buildRightMultipurposePanel(cardBg, borderColor, textColor, textMuted, primaryColor, isDark),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildCanvasArea(borderColor, primaryColor, cardBg),
                              ),
                              const SizedBox(height: AppTheme.space12),
                              if (!_isSpectator) ...[
                                Row(
                                  children: [
                                    Expanded(child: _buildLeftToolbar(isDark, cardBg, borderColor, textColor, textMuted, primaryColor)),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.space12),
                              ],
                              Expanded(
                                flex: 1,
                                child: _buildRightMultipurposePanel(cardBg, borderColor, textColor, textMuted, primaryColor, isDark),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            // Evaluating overlay with Inky Mascot
            if (_isEvaluating)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: AppTheme.space24),
                    decoration: AppTheme.gameCard(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AnimatedInky(size: 85, expression: InkyExpression.thinking),
                        const SizedBox(height: AppTheme.space16),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          _evaluatingMessages[_evaluatingMsgIndex],
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'Evaluating prompt: "$_currentPrompt"',
                          style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasArea(Color borderColor, Color primaryColor, Color cardBg) {
    final ignoreTouch = _timeLeft == 0 || _isSpectator;

    return IgnorePointer(
      ignoring: ignoreTouch,
      child: const DrawingCanvas(),
    );
  }

  Widget _buildTopBar(bool isDark, Color borderColor, Color textColor, Color textMuted, Color primaryColor, Color cardBg) {
    final dangerColor = AppColors.coral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
            decoration: BoxDecoration(
              color: _timeLeft <= 10 ? dangerColor.withOpacity(0.12) : primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: _timeLeft <= 10 ? dangerColor : borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.timer, color: _timeLeft <= 10 ? dangerColor : primaryColor, size: 16),
                const SizedBox(width: AppTheme.space8),
                Text(
                  '$_timeLeft',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space24),

          // Prompt Display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SKETCH THIS PROMPT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.0),
                    ),
                    if (_isSinglePlayerChallenge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.sunny.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _totalRounds == -1 ? 'Round $_currentRound' : 'Round $_currentRound of $_totalRounds',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _currentPrompt.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (!_isMultiplayer) ...[
            IconButton(
              onPressed: _pickNewWord,
              icon: Icon(LucideIcons.shuffle, size: 18, color: textColor),
              tooltip: 'New Prompt',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
          ],
          if (_isSpectator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Text(
                'Spectating',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            )
          else
            Container(
              height: 44,
              decoration: AppTheme.gradientButton(
                startColor: AppColors.teal,
                endColor: AppColors.mint,
                radius: AppTheme.radiusSmall,
              ),
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                ),
                child: Text(
                  _isMultiplayer ? 'Submit Match' : 'Submit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftToolbar(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
  ) {
    final drawing = context.watch<DrawingProvider>();

    return Container(
      width: MediaQuery.of(context).size.width > 900 ? 60 : double.infinity,
      height: MediaQuery.of(context).size.width > 900 ? double.infinity : 60,
      decoration: AppTheme.gameCard(context, radius: AppTheme.radiusMedium),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8, horizontal: 6),
      child: Flex(
        direction: MediaQuery.of(context).size.width > 900 ? Axis.vertical : Axis.horizontal,
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomColorPicker(
                  initialColor: drawing.currentColor,
                  onColorChanged: drawing.setColor,
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: drawing.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: drawing.currentColor.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8, width: AppTheme.space8),

          Expanded(
            child: ListView(
              scrollDirection: MediaQuery.of(context).size.width > 900 ? Axis.vertical : Axis.horizontal,
              children: [
                _buildToolbarIcon(LucideIcons.brush, DrawingToolType.brush, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.penTool, DrawingToolType.pen, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.pencil, DrawingToolType.pencil, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.edit3, DrawingToolType.marker, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.droplet, DrawingToolType.watercolor, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.sparkles, DrawingToolType.neon, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.paintBucket, DrawingToolType.fill, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.eraser, DrawingToolType.eraser, drawing, primaryColor, borderColor),
                _buildToolbarIcon(LucideIcons.mousePointer, DrawingToolType.select, drawing, primaryColor, borderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(
    IconData icon,
    DrawingToolType tool,
    DrawingProvider drawing,
    Color activeColor,
    Color borderColor,
  ) {
    final isSelected = drawing.currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: isSelected ? Colors.white : Colors.grey,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? activeColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? borderColor : Colors.transparent, width: 2),
          ),
          padding: const EdgeInsets.all(8),
        ),
        onPressed: () => drawing.setTool(tool),
      ),
    );
  }

  Widget _buildRightMultipurposePanel(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isMultiplayer) ...[
            _buildLiveScoreboard(cardBg, borderColor, textColor, textMuted, primaryColor),
            const SizedBox(height: AppTheme.space16),
          ],
          _buildRightAssistantPanel(cardBg, borderColor, textColor, textMuted, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildLiveScoreboard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
  ) {
    final opponentLive = _opponentLiveMetrics.values.firstOrNull ?? {
      'score': 0,
      'detectedObject': 'nothing',
      'suggestions': 'Awaiting opponent strokes...'
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: AppTheme.accentCard(context, AppColors.skyBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.swords, color: AppColors.skyBlue, size: 16),
              const SizedBox(width: AppTheme.space8),
              const Text(
                'LIVE DUEL METER',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '$_aiConfidence%',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text('Detected: $_aiDetectedObject', style: TextStyle(fontSize: 9, color: textMuted)),
                  ],
                ),
              ),
              Container(width: 1.5, height: 48, color: borderColor),
              Expanded(
                child: Column(
                  children: [
                    const Text('OPPONENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${opponentLive['score']}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.skyBlue),
                    ),
                    const SizedBox(height: 2),
                    Text('Detected: ${opponentLive['detectedObject']}', style: TextStyle(fontSize: 9, color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightAssistantPanel(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textMuted,
    Color primaryColor,
    bool isDark,
  ) {
    final drawing = context.watch<DrawingProvider>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: AppTheme.gameCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bot, color: primaryColor, size: 16),
              const SizedBox(width: AppTheme.space8),
              const Text(
                'AI ASSISTANT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Stabilization', style: TextStyle(fontSize: 11)),
                selected: drawing.stabilization,
                onSelected: (_) => drawing.toggleStabilization(),
              ),
              ChoiceChip(
                label: const Text('Grid Snap', style: TextStyle(fontSize: 11)),
                selected: drawing.snapGrid,
                onSelected: (_) => drawing.toggleSnapGrid(),
              ),
              ChoiceChip(
                label: const Text('Mirror Mode', style: TextStyle(fontSize: 11)),
                selected: drawing.mirrorDrawing,
                onSelected: (_) => drawing.toggleMirrorDrawing(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          const Text('Shape & Line Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildShapeButton('Line', DrawingToolType.line, drawing),
              _buildShapeButton('Rect', DrawingToolType.rectangle, drawing),
              _buildShapeButton('Circle', DrawingToolType.circle, drawing),
              _buildShapeButton('Oval', DrawingToolType.ellipse, drawing),
              _buildShapeButton('Triangle', DrawingToolType.triangle, drawing),
              _buildShapeButton('Hexagon', DrawingToolType.polygon, drawing),
              _buildShapeButton('Star', DrawingToolType.star, drawing),
              _buildShapeButton('Arrow', DrawingToolType.arrow, drawing),
            ],
          ),
          const SizedBox(height: 12),

          if (drawing.currentTool == DrawingToolType.select) ...[
            const Text('Selection Manipulations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ElevatedButton.icon(
                  onPressed: drawing.selectedStrokeIndex != null ? () => drawing.rotateSelectedStroke(45) : null,
                  icon: const Icon(LucideIcons.rotateCw, size: 12),
                  label: const Text('Rotate 45°', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  onPressed: drawing.selectedStrokeIndex != null ? () => drawing.scaleSelectedStroke(1.2) : null,
                  icon: const Icon(LucideIcons.maximize2, size: 12),
                  label: const Text('Scale 1.2x', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  onPressed: drawing.selectedStrokeIndex != null ? () => drawing.scaleSelectedStroke(0.8) : null,
                  icon: const Icon(LucideIcons.minimize2, size: 12),
                  label: const Text('Scale 0.8x', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  onPressed: drawing.selectedStrokeIndex != null ? () => drawing.duplicateSelectedStroke() : null,
                  icon: const Icon(LucideIcons.copy, size: 12),
                  label: const Text('Duplicate', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: drawing.canUndo ? drawing.undo : null,
                  icon: const Icon(LucideIcons.undo2, size: 14),
                  label: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: drawing.canRedo ? drawing.redo : null,
                  icon: const Icon(LucideIcons.redo2, size: 14),
                  label: const Text('Redo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: drawing.strokes.isNotEmpty ? drawing.clear : null,
            icon: const Icon(LucideIcons.trash2, size: 14),
            label: const Text('Clear Canvas'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
          ),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 8),
          const Text('Live Analysis Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recognition Confidence:', style: TextStyle(fontSize: 12, color: textMuted)),
              Text('$_aiConfidence%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detected Object:', style: TextStyle(fontSize: 12, color: textMuted)),
              Text(_aiDetectedObject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          Text('AI Assistant Suggestion:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor)),
          const SizedBox(height: 4),
          Text(
            _aiSuggestion,
            style: TextStyle(fontSize: 12, color: textColor, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeButton(String label, DrawingToolType tool, DrawingProvider drawing) {
    final isSelected = drawing.currentTool == tool;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: isSelected,
      onSelected: (_) => drawing.setTool(tool),
    );
  }
}
