import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_controller.dart';

class ThemeMenuTile extends StatelessWidget {
  const ThemeMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        final isDarkSelected = mode == ThemeMode.dark;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.white05 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.borderLight2
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: SwitchListTile.adaptive(
            value: isDarkSelected,
            onChanged: (value) async {
              await ThemeController.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
            title: Text(
              isDarkSelected ? "Mode Gelap" : "Mode Terang",
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            secondary: Icon(
              isDarkSelected
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: isDarkSelected
                  ? AppColors.accentLight
                  : AppColors.primaryBlue,
            ),
          ),
        );
      },
    );
  }
}
