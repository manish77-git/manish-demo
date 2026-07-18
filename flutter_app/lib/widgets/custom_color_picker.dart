import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../config/theme.dart';

/// Advanced Color Picker supporting HSV, RGB sliders, HEX text input, opacity, and custom favorite palettes.
class CustomColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const CustomColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<CustomColorPicker> {
  late Color _selectedColor;
  late double _hue;
  late double _saturation;
  late double _value;
  late double _opacity;

  final TextEditingController _hexController = TextEditingController();

  final List<Color> _presets = [
    const Color(0xFF7C3AED), // Brand violet
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEC4899), // Pink
    const Color(0xFFFFFFFF), // White
    const Color(0xFF1E293B), // Dark Slate
  ];

  static final List<Color> _recentColors = [
    const Color(0xFF7C3AED),
    const Color(0xFF3B82F6),
  ];

  static final List<Color> _favoriteColors = [
    const Color(0xFFEF4444),
    const Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    final hsv = HSVColor.fromColor(_selectedColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _opacity = _selectedColor.opacity;
    _updateHexText();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateHexText() {
    final hexCode = _selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    // Drop alpha channel prefix from display if fully opaque
    _hexController.text = hexCode.substring(2);
  }

  void _onColorUpdated() {
    final hsv = HSVColor.fromAHSV(_opacity, _hue, _saturation, _value);
    setState(() {
      _selectedColor = hsv.toColor();
    });
    widget.onColorChanged(_selectedColor);

    if (!_recentColors.contains(_selectedColor)) {
      _recentColors.insert(0, _selectedColor);
      if (_recentColors.length > 8) _recentColors.removeLast();
    }
  }

  void _onHexSubmitted(String text) {
    var cleanText = text.replaceAll('#', '').trim();
    if (cleanText.length == 6) {
      cleanText = 'FF$cleanText';
    }
    final colorVal = int.tryParse(cleanText, radix: 16);
    if (colorVal != null) {
      final color = Color(colorVal);
      final hsv = HSVColor.fromColor(color);
      setState(() {
        _selectedColor = color;
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
        _opacity = color.opacity;
      });
      widget.onColorChanged(_selectedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 2.5),
      ),
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color System',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview block
              Container(
                height: 56,
                decoration: AppTheme.gameCardDecoration(
                  color: _selectedColor,
                  borderColor: borderColor,
                  shadowColor: borderColor,
                  radius: AppTheme.radiusMedium,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HEX: #${_hexController.text}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // RGB and HEX Controls
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('R: ${_selectedColor.red}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _selectedColor.red.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            final c = Color.fromARGB(
                              (_opacity * 255).round(),
                              val.round(),
                              _selectedColor.green,
                              _selectedColor.blue,
                            );
                            final hsv = HSVColor.fromColor(c);
                            _hue = hsv.hue;
                            _saturation = hsv.saturation;
                            _value = hsv.value;
                            _onColorUpdated();
                            _updateHexText();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('G: ${_selectedColor.green}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _selectedColor.green.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            final c = Color.fromARGB(
                              (_opacity * 255).round(),
                              _selectedColor.red,
                              val.round(),
                              _selectedColor.blue,
                            );
                            final hsv = HSVColor.fromColor(c);
                            _hue = hsv.hue;
                            _saturation = hsv.saturation;
                            _value = hsv.value;
                            _onColorUpdated();
                            _updateHexText();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('B: ${_selectedColor.blue}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _selectedColor.blue.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.blue,
                          onChanged: (val) {
                            final c = Color.fromARGB(
                              (_opacity * 255).round(),
                              _selectedColor.red,
                              _selectedColor.green,
                              val.round(),
                            );
                            final hsv = HSVColor.fromColor(c);
                            _hue = hsv.hue;
                            _saturation = hsv.saturation;
                            _value = hsv.value;
                            _onColorUpdated();
                            _updateHexText();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Hue Spectrum
              const Text('HSV Hue Spectrum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Slider(
                value: _hue,
                min: 0,
                max: 360,
                activeColor: Colors.purple,
                onChanged: (val) {
                  _hue = val;
                  _onColorUpdated();
                  _updateHexText();
                },
              ),

              // Saturation and Lightness
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saturation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _saturation,
                          min: 0,
                          max: 1.0,
                          onChanged: (val) {
                            _saturation = val;
                            _onColorUpdated();
                            _updateHexText();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brightness', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _value,
                          min: 0,
                          max: 1.0,
                          onChanged: (val) {
                            _value = val;
                            _onColorUpdated();
                            _updateHexText();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Opacity Slider
              const Text('Alpha (Opacity)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Slider(
                value: _opacity,
                min: 0,
                max: 1.0,
                onChanged: (val) {
                  _opacity = val;
                  _onColorUpdated();
                  _updateHexText();
                },
              ),

              // Hex Manual Input Box
              Row(
                children: [
                  const Text('HEX INPUT:  #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.only(left: 8),
                      child: TextField(
                        controller: _hexController,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onSubmitted: _onHexSubmitted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(LucideIcons.star, color: _favoriteColors.contains(_selectedColor) ? AppTheme.accentYellow : textMuted),
                    onPressed: () {
                      setState(() {
                        if (_favoriteColors.contains(_selectedColor)) {
                          _favoriteColors.remove(_selectedColor);
                        } else {
                          _favoriteColors.add(_selectedColor);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Swatches: Presets, Recents, and Favorites
              _buildPaletteSection('Presets', _presets),
              if (_favoriteColors.isNotEmpty)
                _buildPaletteSection('Favorites ⭐', _favoriteColors),
              if (_recentColors.isNotEmpty)
                _buildPaletteSection('Recents 🕒', _recentColors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteSection(String title, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) => _buildSwatch(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildSwatch(Color color) {
    final isSelected = color.value == _selectedColor.value;
    return GestureDetector(
      onTap: () {
        final hsv = HSVColor.fromColor(color);
        setState(() {
          _selectedColor = color;
          _hue = hsv.hue;
          _saturation = hsv.saturation;
          _value = hsv.value;
          _opacity = color.opacity;
        });
        _updateHexText();
        widget.onColorChanged(color);
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black26,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }
}
