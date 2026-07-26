import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/prompt_service.dart';
import '../../widgets/doodle_painter.dart';
import '../../widgets/mascot_painter.dart';

class SinglePlayerScreen extends StatefulWidget {
  const SinglePlayerScreen({super.key});

  @override
  State<SinglePlayerScreen> createState() => _SinglePlayerScreenState();
}

class _SinglePlayerScreenState extends State<SinglePlayerScreen> {
  int _selectedRounds = 5; // 3, 5, 10, 15, -1 for Endless
  PromptDifficulty _selectedDifficulty = PromptDifficulty.easy;
  PromptCategory _selectedCategory = PromptCategory.randomFun;

  final List<int> _roundOptions = [3, 5, 10, 15, -1];

  String _roundsLabel(int rounds) {
    if (rounds == -1) return 'Endless ♾️';
    return '$rounds Rounds';
  }

  void _startChallenge() {
    final promptObj = PromptService().getRandomPrompt(
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );

    Navigator.pushNamed(
      context,
      '/drawing',
      arguments: {
        'prompt': promptObj.text,
        'duration': 60,
        'isSinglePlayerChallenge': true,
        'currentRound': 1,
        'totalRounds': _selectedRounds,
        'cumulativeScore': 0,
        'difficulty': _selectedDifficulty.label.toLowerCase(),
        'category': _selectedCategory.label,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Player Challenge'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedDoodleBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: AppTheme.gameCard(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mascot Header
                      Row(
                        children: [
                          const AnimatedInky(size: 70, expression: InkyExpression.excited),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SOLO CHALLENGE',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Test your artistic skills and beat your personal high score!',
                                  style: TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Personal Best Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: AppTheme.accentCard(context, AppColors.sunny),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.sunny,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.trophy, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PERSONAL HIGH SCORE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                                Text(
                                  '${auth.highestScore} pts',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${auth.gamesPlayed} Played',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                                ),
                                Text(
                                  '${auth.averageScore} Avg Score',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Category Selector
                      const Text(
                        'Select Category',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PromptCategory.values.take(8).map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text('${cat.emoji} ${cat.label}'),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Round Selector
                      const Text(
                        'Select Number of Rounds',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _roundOptions.map((rounds) {
                          final isSelected = _selectedRounds == rounds;
                          return ChoiceChip(
                            label: Text(_roundsLabel(rounds), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
                            onSelected: (_) {
                              setState(() => _selectedRounds = rounds);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.space20),

                      // Difficulty Selector
                      const Text(
                        'Select Prompt Difficulty',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Row(
                        children: PromptDifficulty.values.map((diff) {
                          final isSelected = _selectedDifficulty == diff;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text('${diff.emoji} ${diff.label}', style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                selectedColor: primaryColor,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
                                onSelected: (_) {
                                  setState(() => _selectedDifficulty = diff);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppTheme.space32),

                      // Start CTA Button
                      Container(
                        height: 52,
                        decoration: AppTheme.gradientButton(
                          startColor: AppColors.coral,
                          endColor: AppColors.sunny,
                          radius: AppTheme.radiusMedium,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _startChallenge,
                          icon: const Icon(LucideIcons.play, color: Colors.white, size: 20),
                          label: const Text(
                            'START CHALLENGE',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
