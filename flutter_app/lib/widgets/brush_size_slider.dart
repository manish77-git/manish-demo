import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/drawing_provider.dart';
import '../config/theme.dart';

/// Brush size slider with visual preview of the brush.
class BrushSizeSlider extends StatelessWidget {
  const BrushSizeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Small brush indicator
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.accentPrimary,
                    inactiveTrackColor: AppTheme.surfaceLight,
                    thumbColor: AppTheme.accentPrimary,
                    overlayColor: AppTheme.accentPrimary.withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: drawing.brushSize,
                    min: 4,
                    max: 40,
                    onChanged: (value) => drawing.setBrushSize(value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Large brush indicator
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Current size preview
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: drawing.brushSize,
                height: drawing.brushSize,
                decoration: BoxDecoration(
                  color: drawing.isEraser
                      ? AppTheme.accentWarm
                      : drawing.currentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (drawing.isEraser
                              ? AppTheme.accentWarm
                              : drawing.currentColor)
                          .withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
