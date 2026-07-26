import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
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
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textMuted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
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
          padding: const EdgeInsets.all(AppTheme.space24),
          child: ListView(
            children: [
              // ── Appearance ────────────────────────────────
              _sectionHeader('Appearance', LucideIcons.palette, primary),
              const SizedBox(height: 12),
              Container(
                decoration: AppTheme.gameCard(context),
                child: Column(
                  children: [
                    _buildThemeTile(
                      'System Default',
                      LucideIcons.monitor,
                      AppThemeMode.system,
                      themeProvider,
                      isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _buildThemeTile(
                      'Light Mode',
                      LucideIcons.sun,
                      AppThemeMode.light,
                      themeProvider,
                      isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _buildThemeTile(
                      'Dark Mode',
                      LucideIcons.moon,
                      AppThemeMode.dark,
                      themeProvider,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── Sound ─────────────────────────────────────
              _sectionHeader('Sound', LucideIcons.volume2, primary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: AppTheme.gameCard(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _audio.isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                          size: 20,
                          color: primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                'Clicks, victory sounds & drawing feedback',
                                style: TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: !_audio.isMuted,
                          activeColor: primary,
                          onChanged: (val) {
                            setState(() => _audio.isMuted = !val);
                            _audio.playClick();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.sliders, size: 20),
                        const SizedBox(width: 14),
                        const Text('Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _audio.sfxVolume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            activeColor: primary,
                            label: '${(_audio.sfxVolume * 100).round()}%',
                            onChanged: (val) {
                              setState(() => _audio.sfxVolume = val);
                            },
                          ),
                        ),
                        Text(
                          '${(_audio.sfxVolume * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w700, color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── Drawing ───────────────────────────────────
              _sectionHeader('Drawing Canvas', LucideIcons.paintbrush, primary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: AppTheme.gameCard(context),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      'Show Grid',
                      'Guide lines on the drawing canvas',
                      LucideIcons.grid3x3,
                      drawingProvider.showGrid,
                      primary,
                      textMuted,
                      () {
                        _audio.playClick();
                        drawingProvider.toggleGrid();
                      },
                    ),
                    Divider(height: 20, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _buildSwitchTile(
                      'Grid Snapping',
                      'Snap points to grid positions',
                      LucideIcons.alignCenter,
                      drawingProvider.snapGrid,
                      primary,
                      textMuted,
                      () {
                        _audio.playClick();
                        drawingProvider.toggleSnapGrid();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── Account & About ───────────────────────────
              _sectionHeader('Account', LucideIcons.user, primary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: AppTheme.gameCard(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.userCheck, size: 20, color: primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auth.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('@${auth.username}', style: TextStyle(fontSize: 12, color: textMuted)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            _audio.playClick();
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            }
                          },
                          icon: const Icon(LucideIcons.logOut, size: 16, color: AppColors.coral),
                          label: const Text('Sign Out', style: TextStyle(color: AppColors.coral, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // ── About ─────────────────────────────────────
              _sectionHeader('About', LucideIcons.info, primary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: AppTheme.gameCard(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.sparkles, size: 20, color: AppColors.sunny),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DrawBattle', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text('Version 2.0.0 · Production Ready', style: TextStyle(fontSize: 12, color: textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    String title,
    IconData icon,
    AppThemeMode mode,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return ListTile(
      leading: Icon(icon, color: isSelected ? primary : null, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(LucideIcons.check, color: primary, size: 20)
          : null,
      onTap: () {
        _audio.playClick();
        themeProvider.setThemeMode(mode);
      },
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Color primary,
    Color textMuted,
    VoidCallback onToggle,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: primary,
          onChanged: (_) => onToggle(),
        ),
      ],
    );
  }
}
