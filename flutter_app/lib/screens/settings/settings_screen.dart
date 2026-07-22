import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/drawing_provider.dart';
import '../../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioService _audio = AudioService();

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
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            _audio.playClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              // Audio Section
              _buildSectionHeader('Audio & Sound Effects', LucideIcons.volume2, context),
              const SizedBox(height: 12),
              Card(
                color: tileColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: !_audio.isMuted,
                        title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('UI clicks, drawing sounds & victory fanfares'),
                        secondary: Icon(_audio.isMuted ? LucideIcons.volumeX : LucideIcons.volume2),
                        onChanged: (val) {
                          setState(() => _audio.isMuted = !val);
                          _audio.playClick();
                        },
                      ),
                      Divider(height: 16, color: dividerColor),
                      Row(
                        children: [
                          const Icon(LucideIcons.sliders, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SFX Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                                Slider(
                                  value: _audio.sfxVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  label: '${(_audio.sfxVolume * 100).round()}%',
                                  onChanged: (val) {
                                    setState(() => _audio.sfxVolume = val);
                                    _audio.playClick();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                      onChanged: (mode) {
                        _audio.playClick();
                        themeProvider.setThemeMode(mode!);
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    _buildThemeRadioTile(
                      title: 'Light Mode',
                      mode: AppThemeMode.light,
                      activeMode: themeProvider.themeMode,
                      onChanged: (mode) {
                        _audio.playClick();
                        themeProvider.setThemeMode(mode!);
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    _buildThemeRadioTile(
                      title: 'Dark Mode',
                      mode: AppThemeMode.dark,
                      activeMode: themeProvider.themeMode,
                      onChanged: (mode) {
                        _audio.playClick();
                        themeProvider.setThemeMode(mode!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Drawing Settings Section
              _buildSectionHeader('Drawing Canvas Assists', LucideIcons.brush, context),
              const SizedBox(height: 12),
              Card(
                color: tileColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: drawingProvider.showGrid,
                        title: const Text('Show Grid Overlay', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Display guide lines on drawing canvas'),
                        secondary: const Icon(LucideIcons.grid),
                        onChanged: (val) {
                          _audio.playClick();
                          drawingProvider.toggleGrid();
                        },
                      ),
                      Divider(height: 16, color: dividerColor),
                      SwitchListTile(
                        value: drawingProvider.snapGrid,
                        title: const Text('Grid Snapping', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Snap points to grid alignments'),
                        secondary: const Icon(LucideIcons.alignCenter),
                        onChanged: (val) {
                          _audio.playClick();
                          drawingProvider.toggleSnapGrid();
                        },
                      ),
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
