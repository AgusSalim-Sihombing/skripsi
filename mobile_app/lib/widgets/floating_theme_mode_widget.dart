import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_controller.dart';

class FloatingThemeModeWidget extends StatefulWidget {
  const FloatingThemeModeWidget({super.key});

  @override
  State<FloatingThemeModeWidget> createState() =>
      _FloatingThemeModeWidgetState();
}

class _FloatingThemeModeWidgetState extends State<FloatingThemeModeWidget> {
  Offset _themeFabOffset = Offset.zero;
  bool _themeFabReady = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    const double btnSize = 56;

    final double safeTop = media.padding.top + 30;
    final double minX = 30;
    final double minY = safeTop;
    final double maxX = media.size.width - btnSize - 8;
    final double maxY = media.size.height - btnSize - 8;

    if (!_themeFabReady) {
      _themeFabOffset = Offset(maxX, safeTop);
      _themeFabReady = true;
    }

    // clamp kalau ukuran layar berubah
    _themeFabOffset = Offset(
      _themeFabOffset.dx.clamp(minX, maxX),
      _themeFabOffset.dy.clamp(minY, maxY),
    );

    return Positioned(
      left: _themeFabOffset.dx,
      top: _themeFabOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _themeFabOffset = Offset(
              (_themeFabOffset.dx + details.delta.dx).clamp(minX, maxX),
              (_themeFabOffset.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onTap: () async {
          await ThemeController.toggleTheme();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.surfaceGlass.withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              border: Border.all(
                color: isDark
                    ? AppColors.borderLight2
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark.withOpacity(0.35)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.accentLight : AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}
