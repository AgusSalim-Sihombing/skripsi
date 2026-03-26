import 'package:flutter/material.dart';

enum AppPopupType { success, error, info, warning }

class MessagePopup {
  // Menyimpan referensi popup yang sedang aktif agar bisa ditutup jika popup baru muncul
  static OverlayEntry? _activePopupEntry;

  /// Method utama untuk menampilkan popup
  static Future<void> show(
    BuildContext context,
    String message, {
    required AppPopupType type,
    Duration duration = const Duration(seconds: 2),
  }) async {
    // Memastikan context masih valid (widget belum didestroy)
    if (!context.mounted) return;

    // Menghapus popup sebelumnya jika masih ada
    _activePopupEntry?.remove();
    _activePopupEntry = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bgColor;
    late final Color borderColor;
    late final Color iconBgColor;
    late final Color textColor;
    late final IconData icon;
    late final String title;

    switch (type) {
      case AppPopupType.success:
        bgColor = isDark ? const Color(0xFF0F2A1B) : const Color(0xFFEAFBF1);
        borderColor = isDark
            ? const Color(0xFF1F7A45)
            : const Color(0xFF79D9A2);
        iconBgColor = const Color(0xFF22C55E);
        textColor = isDark ? Colors.white : const Color(0xFF14532D);
        icon = Icons.check_circle_rounded;
        title = "Berhasil";
        break;

      case AppPopupType.error:
        bgColor = isDark ? const Color(0xFF2A1010) : const Color(0xFFFDEDED);
        borderColor = isDark
            ? const Color(0xFFB91C1C)
            : const Color(0xFFF5A3A3);
        iconBgColor = const Color(0xFFEF4444);
        textColor = isDark ? Colors.white : const Color(0xFF7F1D1D);
        icon = Icons.error_rounded;
        title = "Error";
        break;

      case AppPopupType.warning:
        bgColor = isDark ? const Color(0xFF2B1E0D) : const Color(0xFFFFF6E8);
        borderColor = isDark
            ? const Color(0xFFD97706)
            : const Color(0xFFF7C97B);
        iconBgColor = const Color(0xFFF59E0B);
        textColor = isDark ? Colors.white : const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
        title = "Peringatan";
        break;

      case AppPopupType.info:
        bgColor = isDark ? const Color(0xFF0E1B35) : const Color(0xFFEFF6FF);
        borderColor = isDark
            ? const Color(0xFF3B82F6)
            : const Color(0xFF93C5FD);
        iconBgColor = const Color(0xFF3B82F6);
        textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
        icon = Icons.info_rounded;
        title = "Informasi";
        break;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    final entry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top + 12;

        return Positioned(
          top: topInset,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -20, end: 0),
              duration: const Duration(milliseconds: 540),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final opacity = ((20 - value.abs()) / 20).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.34 : 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.95),
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _activePopupEntry = entry;

    await Future.delayed(duration);

    // Hapus popup jika entry yang sedang aktif masih sama dengan yang baru saja dibuat
    if (_activePopupEntry == entry) {
      entry.remove();
      _activePopupEntry = null;
    }
  }

  // --- Convenience Methods --- //

  static Future<void> success(BuildContext context, String message) async {
    await show(context, message, type: AppPopupType.success);
  }

  static Future<void> error(BuildContext context, String message) async {
    await show(context, message, type: AppPopupType.error);
  }

  static Future<void> info(BuildContext context, String message) async {
    await show(context, message, type: AppPopupType.info);
  }

  static Future<void> warning(BuildContext context, String message) async {
    await show(context, message, type: AppPopupType.warning);
  }
}
