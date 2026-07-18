import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/drawing_canvas.dart';
import '../../widgets/custom_color_picker.dart';
import '../../services/drawing_service.dart';
import '../../services/api_service.dart';
import '../../services/game_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  late String _currentPrompt;
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
  List<String> _aiMissingItems = [];
  String _aiSuggestion = 'Start drawing to get live suggestions.';

  // Opponent Live Metrics
  final Map<String, Map<String, dynamic>> _opponentLiveMetrics = {};

  final _random = math.Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('prompt')) {
        _currentPrompt = args['prompt'] as String;
      }
      if (args.containsKey('duration')) {
        _timeLeft = args['duration'] as int;
      }
      _isMultiplayer = args['isMultiplayer'] == true;
      if (args.containsKey('isSpectator')) {
        _isSpectator = args['isSpectator'] == true;
      }
    }

    if (_isMultiplayer && _timeLeft > 0) {
      _syncTimerWithServer();
    } else if (!_isMultiplayer && !_hasFetchedPrompt) {
      _hasFetchedPrompt = true;
      _fetchSoloPrompt();
    }
  }

  Future<void> _fetchSoloPrompt({String? customCategory, String? customDifficulty}) async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final category = customCategory ?? args?['category'] as String? ?? 'all';
      final difficulty = customDifficulty ?? args?['difficulty'] as String? ?? 'all';

      final response = await http.get(
        Uri.parse('${ApiConfig.serverUrl}/api/drawings/random-prompt?category=$category&difficulty=$difficulty'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          _currentPrompt = data['data']['prompt'] as String;
        });
      }
    } catch (e) {
      debugPrint('[DrawingScreen] Error fetching random prompt: $e');
    }
  }

  Future<void> _syncTimerWithServer() async {
    try {
      final auth = context.read<AuthProvider>();
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
          } else {
            _timer?.cancel();
            _handleTimeUp();
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final drawing = context.read<DrawingProvider>();
      drawing.reset();
      drawing.addListener(_onStrokesChanged);

      // Periodically sync clock to ensure all timers are locked in step
      Timer.periodic(const Duration(seconds: 10), (t) {
        if (mounted && _isMultiplayer && _timeLeft > 0) {
          _syncTimerWithServer();
        } else {
          t.cancel();
        }
      });

      if (_isMultiplayer) {
        final socketProvider = context.read<SocketProvider>();

        // Spectators do not emit drawings
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

        // Link socket listeners to incoming strokes
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
    if (drawing.strokes.length != _lastStrokeCount) {
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
        _aiMissingItems = [];
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
          _aiMissingItems = List<String>.from(result['missingFeatures'] as List? ?? []);
          _aiSuggestion = result['suggestions'] as String? ?? '';
        });

        // Broadcast metrics to opponent if multiplayer
        if (_isMultiplayer) {
          context.read<SocketProvider>().emitLiveMetrics({
            'score': _aiConfidence,
            'detectedObject': _aiDetectedObject,
            'suggestions': _aiSuggestion,
          });
        }
      }
    } catch (e) {
      debugPrint('Live analysis error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _pickNewWord() {
    if (_isMultiplayer) return; // Prevent prompt picking in multiplayer
    setState(() {
      _aiConfidence = 0;
      _aiDetectedObject = 'nothing';
      _aiMissingItems = [];
      _aiSuggestion = 'Try drawing the new prompt.';
    });
    _fetchSoloPrompt();
    context.read<DrawingProvider>().clear();
  }

  void _handleTimeUp() {
    if (_isSpectator) {
      final socketProvider = context.read<SocketProvider>();
      Navigator.pushReplacementNamed(
        context,
        '/results',
        arguments: {
          'isMultiplayer': true,
          'gameId': socketProvider.roomCode ?? '',
          'isSpectator': true,
        },
      );
    } else {
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    final drawingProvider = context.read<DrawingProvider>();
    final auth = context.read<AuthProvider>();

    setState(() => _isEvaluating = true);

    try {
      final bytes = await drawingProvider.exportToPng(const Size(500, 500));
      if (bytes == null) throw Exception('Failed to export canvas');

      final drawingService = DrawingService(
        baseUrl: ApiConfig.serverUrl,
        getToken: () => auth.idToken,
      );

      if (_isMultiplayer) {
        final socketProvider = context.read<SocketProvider>();
        final response = await drawingService.submitDrawing(
          gameId: socketProvider.roomCode ?? '',
          drawingBytes: bytes,
        );

        // Listen for final results emitted by server
        final resultFuture = Completer<Map<String, dynamic>>();
        socketProvider.onLiveMetrics = null; // Clean up intermediate listener

        // The socket server emits 'game:results'
        final io = socketProvider;
        // In this implementation, drawing Service submitDrawing API call returns evaluation results.
        // If all players submitted, final scores are computed.
        // We will query the endpoint /api/drawings/:gameId to get results, or use response JSON directly.
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/results',
            arguments: {
              'score': response.score,
              'prompt': _currentPrompt,
              'labels': response.labels,
              'grade': response.grade,
              'confidence': response.confidence,
              'explanation': response.explanation,
              'objectRecognitionScore': response.objectRecognitionScore,
              'requiredFeaturesScore': response.requiredFeaturesScore,
              'compositionScore': response.compositionScore,
              'creativityScore': response.creativityScore,
              'strokeQualityScore': response.strokeQualityScore,
              'strengths': response.strengths,
              'weaknesses': response.weaknesses,
              'isMultiplayer': true,
              'gameId': socketProvider.roomCode,
            },
          );
        }
      } else {
        // Solo/Practice Mode evaluation
        final result = await drawingService.evaluateSoloDrawing(
          prompt: _currentPrompt,
          drawingBytes: bytes,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/results',
            arguments: {
              'score': result.score,
              'prompt': _currentPrompt,
              'labels': result.labels,
              'grade': result.grade,
              'confidence': result.confidence,
              'explanation': result.explanation,
              'objectRecognitionScore': result.objectRecognitionScore,
              'requiredFeaturesScore': result.requiredFeaturesScore,
              'compositionScore': result.compositionScore,
              'creativityScore': result.creativityScore,
              'strokeQualityScore': result.strokeQualityScore,
              'strengths': result.strengths,
              'weaknesses': result.weaknesses,
              'isMultiplayer': false,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error during AI drawing evaluation: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Evaluation Error'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: Stack(
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
                              // Left Toolbar
                              if (!_isSpectator) ...[
                                _buildLeftToolbar(isDark, cardBg, borderColor, textColor, textMuted, primaryColor),
                                const SizedBox(width: AppTheme.space16),
                              ],

                              // Main Draw Canvas
                              Expanded(
                                flex: 3,
                                child: _buildCanvasArea(borderColor, primaryColor, cardBg),
                              ),
                              const SizedBox(width: AppTheme.space16),

                              // Right Assist / Opponent View
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

            // Evaluating overlay
            if (_isEvaluating)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: AppTheme.space24),
                    decoration: AppTheme.gameCardDecoration(
                      color: cardBg,
                      borderColor: borderColor,
                      shadowColor: primaryColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          'Evaluating drawing...',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'AI is analyzing your creativity',
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
    // If time remaining is 0 or user is a spectator, freeze canvas (block touch events)
    final ignoreTouch = _timeLeft == 0 || _isSpectator;

    return IgnorePointer(
      ignoring: ignoreTouch,
      child: Container(
        decoration: AppTheme.gameCardDecoration(
          color: cardBg,
          borderColor: borderColor,
          shadowColor: primaryColor,
          radius: AppTheme.radiusLarge,
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusLarge)),
          child: DrawingCanvas(),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color borderColor, Color textColor, Color textMuted, Color primaryColor, Color cardBg) {
    final dangerColor = AppTheme.accentCoral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 2.5)),
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
            decoration: AppTheme.gameCardDecoration(
              color: _timeLeft <= 10 ? dangerColor.withOpacity(0.12) : primaryColor.withOpacity(0.06),
              borderColor: borderColor,
              shadowColor: _timeLeft <= 10 ? dangerColor : primaryColor,
              radius: AppTheme.radiusSmall,
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
                Text(
                  'SKETCH THIS PROMPT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.0),
                ),
                Text(
                  _currentPrompt.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                  side: BorderSide(color: borderColor, width: 2.5),
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
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Text(
                'Spectating',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            )
          else
            Container(
              height: 48,
              decoration: AppTheme.gameCardDecoration(
                color: isDark ? AppTheme.accentDark : AppTheme.accentLight,
                borderColor: borderColor,
                shadowColor: borderColor,
                radius: AppTheme.radiusSmall,
              ),
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
        radius: AppTheme.radiusMedium,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8, horizontal: 6),
      child: Flex(
        direction: MediaQuery.of(context).size.width > 900 ? Axis.vertical : Axis.horizontal,
        children: [
          // Color picker trigger
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

          // Tools list
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
          // If multiplayer, show opponent live score card
          if (_isMultiplayer) ...[
            _buildLiveScoreboard(cardBg, borderColor, textColor, textMuted, primaryColor),
            const SizedBox(height: AppTheme.space16),
          ],

          // Drawing Assistant & Shape options
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
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: AppTheme.accentCyan,
        radius: AppTheme.radiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.swords, color: AppTheme.accentCyan, size: 16),
              const SizedBox(width: AppTheme.space8),
              const Text(
                'LIVE DUEL METER',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Side-by-side stats
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accentCyan),
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
      decoration: AppTheme.gameCardDecoration(
        color: cardBg,
        borderColor: borderColor,
        shadowColor: primaryColor,
        radius: AppTheme.radiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
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

          // Toggles (Stabilization, Grid snap, Mirror)
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

          // Dynamic Shape Assist buttons
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

          // Selection tool actions
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

          // Undo, Redo, Clear
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
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentCoral),
          ),
          const SizedBox(height: 16),

          // Live recognition metrics
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

          // Suggestions list
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
