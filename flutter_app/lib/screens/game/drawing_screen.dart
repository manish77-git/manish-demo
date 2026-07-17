import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/drawing_canvas.dart';
import '../../widgets/custom_color_picker.dart';
import '../../services/drawing_service.dart';

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

  // AI Drawing Assistant State
  int _lastStrokeCount = 0;
  Timer? _analysisDebounce;
  bool _isAnalyzing = false;
  int _aiConfidence = 0;
  String _aiDetectedObject = 'nothing';
  List<String> _aiMissingItems = [];
  String _aiSuggestion = 'Start drawing to get live suggestions!';

  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _currentPrompt = _practicePrompts[_random.nextInt(_practicePrompts.length)];
    
    // Start count-down timer
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
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _analysisDebounce?.cancel();
    // Safely remove listener in dispose
    try {
      context.read<DrawingProvider>().removeListener(_onStrokesChanged);
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
        _aiSuggestion = 'Draw something to begin!';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Export small low-resolution preview for extremely fast upload
      final bytes = await drawing.exportToPng(const Size(200, 200));
      if (bytes == null || !mounted) return;

      final service = DrawingService(
        baseUrl: 'http://localhost:3000',
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
      }
    } catch (e) {
      debugPrint('Live analysis debounce error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _pickNewWord() {
    setState(() {
      _currentPrompt = _practicePrompts[_random.nextInt(_practicePrompts.length)];
      _aiConfidence = 0;
      _aiDetectedObject = 'nothing';
      _aiMissingItems = [];
      _aiSuggestion = 'Try drawing the new prompt!';
    });
    context.read<DrawingProvider>().clear();
  }

  void _handleTimeUp() {
    _handleSubmit();
  }

  Future<void> _handleSubmit() async {
    final drawingProvider = context.read<DrawingProvider>();
    final auth = context.read<AuthProvider>();

    setState(() {
      _isEvaluating = true;
    });

    try {
      final bytes = await drawingProvider.exportToPng(const Size(500, 500));
      if (bytes == null) throw Exception('Failed to export canvas');

      final drawingService = DrawingService(
        baseUrl: 'http://localhost:3000',
        getToken: () => auth.idToken,
      );

      // Verify AI status
      final status = await drawingService.checkAiStatus();
      if (status['initialized'] != true) {
        throw Exception(status['error'] ?? 'AI Server is not ready or key is invalid.');
      }

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
          },
        );
      }
    } catch (e) {
      debugPrint('Error during AI drawing evaluation: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('AI Evaluation Error'),
              ],
            ),
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
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
      }
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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header Panel
                _buildTopBar(isDark, borderColor, textColor, textMuted),
                
                // Workspace Layout
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Toolbar
                        _buildLeftToolbar(isDark, cardBg, borderColor, textColor, textMuted),
                        const SizedBox(width: 16),
                        
                        // Center Drawing Canvas
                        const Expanded(
                          child: DrawingCanvas(),
                        ),
                        const SizedBox(width: 16),

                        // Right AI Assistant drawer
                        if (isDesktop)
                          _buildRightAssistantPanel(cardBg, borderColor, textColor, textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_isEvaluating)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Card(
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: borderColor, width: 1.5),
                    ),
                    elevation: 12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 4),
                          const SizedBox(height: 24),
                          Text(
                            'Analyzing sketch... 🧠',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gemini is scoring multi-criteria details',
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color borderColor, Color textColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(
        children: [
          // Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.timer, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_timeLeft',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Word details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAW THIS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentPrompt.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Action triggers
          IconButton(
            onPressed: _pickNewWord,
            icon: Icon(LucideIcons.shuffle),
            tooltip: 'New Prompt',
            color: AppTheme.primaryLight,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryLight.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: Icon(LucideIcons.check, color: Colors.white, size: 18),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
  ) {
    final drawing = context.watch<DrawingProvider>();

    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Brush Color Picker trigger
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: drawing.currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 2),
              ),
              child: Icon(LucideIcons.pipette, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(indent: 12, endIndent: 12, height: 16),

          // Tools list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildToolbarIcon(LucideIcons.brush, DrawingToolType.brush, drawing),
                _buildToolbarIcon(LucideIcons.penTool, DrawingToolType.pen, drawing),
                _buildToolbarIcon(LucideIcons.pencil, DrawingToolType.pencil, drawing),
                _buildToolbarIcon(LucideIcons.edit2, DrawingToolType.marker, drawing),
                _buildToolbarIcon(LucideIcons.paintBucket, DrawingToolType.watercolor, drawing),
                _buildToolbarIcon(LucideIcons.sparkles, DrawingToolType.neon, drawing),
                _buildToolbarIcon(LucideIcons.eraser, DrawingToolType.eraser, drawing),
                const SizedBox(height: 8),
                const Divider(height: 16),
                const SizedBox(height: 8),
                // Shape tools
                _buildToolbarIcon(LucideIcons.minus, DrawingToolType.line, drawing),
                _buildToolbarIcon(LucideIcons.square, DrawingToolType.rectangle, drawing),
                _buildToolbarIcon(LucideIcons.circle, DrawingToolType.circle, drawing),
                _buildToolbarIcon(LucideIcons.triangle, DrawingToolType.triangle, drawing),
                _buildToolbarIcon(LucideIcons.arrowUpRight, DrawingToolType.arrow, drawing),
                _buildToolbarIcon(LucideIcons.star, DrawingToolType.star, drawing),
              ],
            ),
          ),

          const Divider(indent: 12, endIndent: 12, height: 16),
          // Canvas utility actions
          _buildUtilityIconButton(LucideIcons.grid, drawing.toggleGrid, drawing.showGrid),
          _buildUtilityIconButton(LucideIcons.magnet, drawing.toggleSnapGrid, drawing.snapGrid),
          _buildUtilityIconButton(LucideIcons.undo2, drawing.undo, drawing.canUndo),
          _buildUtilityIconButton(LucideIcons.redo2, drawing.redo, drawing.canRedo),
          _buildUtilityIconButton(LucideIcons.trash2, drawing.clear, drawing.strokes.isNotEmpty, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, DrawingToolType type, DrawingProvider drawing) {
    final isSelected = drawing.currentTool == type;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        onPressed: () => drawing.setTool(type),
        icon: Icon(icon, size: 20),
        color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? primaryColor : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildUtilityIconButton(IconData icon, VoidCallback onTap, bool enabled, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        color: color ?? (enabled ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[600]),
        style: IconButton.styleFrom(
          backgroundColor: enabled && color != null ? color.withOpacity(0.08) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildRightAssistantPanel(Color cardBg, Color borderColor, Color textColor, Color textMuted) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppTheme.accentLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Assistant',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (_isAnalyzing) ...[
                const Spacer(),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Matching confidence
          const Text('Recognition Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _aiConfidence / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$_aiConfidence%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),

          // Detected shape tag
          const Text('Detected Object', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _aiDetectedObject.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 24),

          // Missing elements checklist
          const Text('Suggested Next Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          Expanded(
            child: _aiMissingItems.isEmpty
                ? Center(
                    child: Text(
                      'AI is processing strokes...',
                      style: TextStyle(color: textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    itemCount: _aiMissingItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(LucideIcons.plus, size: 14, color: AppTheme.accentLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _aiMissingItems[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Suggestion box
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _aiSuggestion,
              style: const TextStyle(fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
