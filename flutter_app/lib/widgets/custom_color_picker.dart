import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  final List<Color> _presetColors = [
    const Color(0xFF1E293B), // Slate Dark
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
  ];

  static final List<Color> _recentColors = [
    const Color(0xFF1E293B),
    const Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    final hsv = HSVColor.fromColor(_selectedColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _updateColor() {
    final hsv = HSVColor.fromAHSV(1.0, _hue, _saturation, _value);
    setState(() {
      _selectedColor = hsv.toColor();
    });
    widget.onColorChanged(_selectedColor);

    if (!_recentColors.contains(_selectedColor)) {
      _recentColors.insert(0, _selectedColor);
      if (_recentColors.length > 8) _recentColors.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Color Palette',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stroke Preview
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '#${_selectedColor.value.toRadixString(16).substring(2, 8).toUpperCase()}',
                  style: TextStyle(
                    color: ThemeData.estimateBrightnessForColor(_selectedColor) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hue Slider (Color Spectrum)
            const Text('Hue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red
                  ],
                ),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 14,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _hue,
                  min: 0,
                  max: 360,
                  onChanged: (val) {
                    _hue = val;
                    _updateColor();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Saturation Slider
            const Text('Saturation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Slider(
              value: _saturation,
              activeColor: _selectedColor,
              onChanged: (val) {
                _saturation = val;
                _updateColor();
              },
            ),
            const SizedBox(height: 16),

            // Lightness (Value) Slider
            const Text('Brightness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Slider(
              value: _value,
              activeColor: _selectedColor,
              onChanged: (val) {
                _value = val;
                _updateColor();
              },
            ),
            const SizedBox(height: 24),

            // Preset swatches
            const Text('Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((color) => _buildSwatch(color)).toList(),
            ),
            const SizedBox(height: 20),

            // Recents swatches
            if (_recentColors.isNotEmpty) ...[
              const Text('Recent Colors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentColors.map((color) => _buildSwatch(color)).toList(),
              ),
            ],
          ],
        ),
      ),
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
        });
        widget.onColorChanged(color);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black12,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }
}
