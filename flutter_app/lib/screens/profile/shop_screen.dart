import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/progression_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/audio_service.dart';
import '../../config/theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Shop'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            AudioService().playClick();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.coins, color: AppTheme.accentYellow, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${progression.coins}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('UNLOCKABLE BRUSHES & THEMES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: ProgressionProvider.shopCatalog.length,
                  itemBuilder: (context, index) {
                    final item = ProgressionProvider.shopCatalog[index];
                    final isOwned = progression.isUnlocked(item.id);
                    final canAfford = progression.coins >= item.cost;

                    return Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: AppTheme.gameCardDecoration(
                        color: cardBg,
                        borderColor: borderColor,
                        shadowColor: isOwned ? AppTheme.accentLight : primaryColor,
                        radius: AppTheme.radiusLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getIconData(item.iconName), color: primaryColor, size: 24),
                              ),
                              const Spacer(),
                              if (isOwned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentLight.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.accentLight, width: 1.5),
                                  ),
                                  child: const Text('UNLOCKED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppTheme.accentLight)),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(item.name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                          const SizedBox(height: 2),
                          Text(item.description, style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500)),
                          const Spacer(),

                          if (!isOwned)
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: canAfford
                                    ? () {
                                        final success = progression.purchaseItem(item);
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('🎉 Unlocked ${item.name}!')),
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford ? AppTheme.accentYellow : Colors.grey.shade400,
                                  foregroundColor: Colors.black,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.coins, size: 16, color: Colors.black),
                                    const SizedBox(width: 6),
                                    Text('${item.cost}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'spray':
        return LucideIcons.sparkles;
      case 'grid':
        return LucideIcons.grid;
      case 'droplet':
        return LucideIcons.droplet;
      case 'pen-tool':
        return LucideIcons.penTool;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'palette':
        return LucideIcons.palette;
      case 'gamepad-2':
        return LucideIcons.gamepad2;
      default:
        return LucideIcons.brush;
    }
  }
}
