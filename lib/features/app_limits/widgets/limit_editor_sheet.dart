import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_limit.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_icon.dart';

class LimitEditorSheet extends StatefulWidget {
  final AppLimit app;
  final Function(int) onSave;

  const LimitEditorSheet({
    super.key,
    required this.app,
    required this.onSave,
  });

  @override
  State<LimitEditorSheet> createState() => _LimitEditorSheetState();
}

class _LimitEditorSheetState extends State<LimitEditorSheet> {
  late double _sliderValue;

  final List<int> _presets = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.app.dailyLimitMinutes.toDouble().clamp(5, 180);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Color get _accentColor {
    if (_sliderValue >= 120) return AppColors.dangerRed;
    if (_sliderValue >= 75) return AppColors.warningAmber;
    return AppColors.mintGreen;
  }

  @override
  Widget build(BuildContext context) {
    // Use viewInsets to handle keyboard and screen size
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // Cap height so it never overflows
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1040),
            const Color(0xFF0A0E27),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 40 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // App info row
            Row(
              children: [
                AppIcon(
                  packageName: widget.app.packageName,
                  size: 28,
                  containerSize: 56,
                  borderRadius: 18,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.app.displayName,
                          style: AppTextStyles.headlineMedium),
                      Text('Set your daily limit',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Big time display — fixed height container prevents overflow
            SizedBox(
              height: 72,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatMinutes(_sliderValue.toInt()),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: _accentColor,
                      fontSize: 56,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 4),

            Text('per day',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),

            const SizedBox(height: 28),

            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 14),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 24),
                activeTrackColor: _accentColor,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: Colors.white,
                overlayColor: _accentColor.withOpacity(0.2),
              ),
              child: Slider(
                value: _sliderValue,
                min: 5,
                max: 180,
                divisions: 35,
                onChanged: (val) => setState(() => _sliderValue = val),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5m', style: AppTextStyles.labelSmall),
                  Text('3h', style: AppTextStyles.labelSmall),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Presets label
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick presets', style: AppTextStyles.labelSmall),
            ),
            const SizedBox(height: 12),

            // Presets row — wrapped so they never overflow
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _sliderValue.toInt() == preset;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _sliderValue = preset.toDouble()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? _accentColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: isSelected
                            ? _accentColor.withOpacity(0.6)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      _formatMinutes(preset),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? _accentColor
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Save button
            GestureDetector(
              onTap: () {
                widget.onSave(_sliderValue.toInt());
                Navigator.pop(context);
              },
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                borderRadius: BorderRadius.circular(20),
                gradientColors: [
                  _accentColor.withOpacity(0.4),
                  _accentColor.withOpacity(0.2),
                ],
                child: Center(
                  child: Text('Save Limit',
                      style: AppTextStyles.headlineMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}