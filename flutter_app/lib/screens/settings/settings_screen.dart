import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/drawing_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final drawingProvider = context.watch<DrawingProvider>();
    final isDark = themeProvider.isDarkMode;

    final tileColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
    final dividerColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance', LucideIcons.palette, context),
              const SizedBox(height: 12),
              Card(
                color: tileColor,
                child: Column(
                  children: [
                    _buildThemeRadioTile(
                      title: 'Follow System',
                      mode: AppThemeMode.system,
                      activeMode: themeProvider.themeMode,
                      onChanged: (mode) => themeProvider.setThemeMode(mode!),
                    ),
                    Divider(height: 1, color: dividerColor),
                    _buildThemeRadioTile(
                      title: 'Light Mode',
                      mode: AppThemeMode.light,
                      activeMode: themeProvider.themeMode,
                      onChanged: (mode) => themeProvider.setThemeMode(mode!),
                    ),
                    Divider(height: 1, color: dividerColor),
                    _buildThemeRadioTile(
                      title: 'Dark Mode',
                      mode: AppThemeMode.dark,
                      activeMode: themeProvider.themeMode,
                      onChanged: (mode) => themeProvider.setThemeMode(mode!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Drawing Settings Section
              _buildSectionHeader('Drawing Assistant & Canvas', LucideIcons.brush, context),
              const SizedBox(height: 12),
              Card(
                color: tileColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Smoothing Slider
                      Row(
                        children: [
                          Icon(LucideIcons.activity, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Line Smoothing', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('Reduces hand jitter while drawing', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: 5.0, // Mock configuration placeholder (or load from drawing settings)
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        label: '5.0',
                        onChanged: (val) {
                          // Update smoothing settings
                        },
                      ),
                      Divider(height: 24, color: dividerColor),
                      // Grid Snapping
                      SwitchListTile(
                        value: false,
                        title: const Text('Snap to Grid', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Align strokes and lines to grid overlay'),
                        secondary: Icon(LucideIcons.grid),
                        onChanged: (val) {
                          // Toggle grid snap
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actions Section
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                icon: Icon(LucideIcons.trash2, size: 20),
                label: const Text('Reset Preferences'),
                onPressed: () {
                  themeProvider.setThemeMode(AppThemeMode.system);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences reset to defaults')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildThemeRadioTile({
    required String title,
    required AppThemeMode mode,
    required AppThemeMode activeMode,
    required ValueChanged<AppThemeMode?> onChanged,
  }) {
    return RadioListTile<AppThemeMode>(
      value: mode,
      groupValue: activeMode,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onChanged: onChanged,
      activeColor: AppTheme.primaryLight,
    );
  }
}
