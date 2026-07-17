import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_provider.dart';
import '../config/theme.dart';

/// Animated horizontal color picker with curated drawing colors.
class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key});

  static const List<Color> drawingColors = [
    Color(0xFF1F2937),    // Charcoal/Black
    Color(0xFFFF6B6B),    // Coral
    Color(0xFFFF8E53),    // Orange
    Color(0xFFFFD93D),    // Gold
    Color(0xFF6BCB77),    // Green
    Color(0xFF4ECDC4),    // Teal
    Color(0xFF45B7D1),    // Sky blue
    Color(0xFF6C63FF),    // Purple
    Color(0xFFE056A0),    // Pink
    Color(0xFF9B59B6),    // Violet
    Color(0xFF8B4513),    // Brown
    Color(0xFF2C3E50),    // Dark blue
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: drawingColors.length + 1, // +1 for eraser
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              if (index == drawingColors.length) {
                // Eraser button
                return _buildEraserButton(drawing);
              }

              final color = drawingColors[index];
              final isSelected = !drawing.isEraser && drawing.currentColor == color;

              return GestureDetector(
                onTap: () => drawing.setColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  width: isSelected ? 42 : 36,
                  height: isSelected ? 42 : 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEraserButton(DrawingProvider drawing) {
    final isSelected = drawing.isEraser;
    return GestureDetector(
      onTap: () => drawing.toggleEraser(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        width: isSelected ? 42 : 36,
        height: isSelected ? 42 : 36,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentWarm.withOpacity(0.2)
              : AppTheme.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppTheme.accentWarm
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: Icon(
          Icons.auto_fix_high,
          size: isSelected ? 20 : 16,
          color: isSelected ? AppTheme.accentWarm : AppTheme.textMuted,
        ),
      ),
    );
  }
}
