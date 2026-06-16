import 'package:flutter/material.dart';
import 'package:tailor_book/core/theme/app_colors.dart';

enum SnackType { success, error, warning, info, loading }

class TbSnackbar {
  TbSnackbar._();

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required SnackType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: type == SnackType.loading
            ? const Duration(minutes: 10)
            : duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        content: _TbSnackContent(title: title, subtitle: subtitle, type: type),
      ),
    );
  }

  // ── Convenience shortcuts ──────────────────────────────────────────────────

  static void success(BuildContext context, String title, {String? subtitle}) =>
      show(context, title: title, subtitle: subtitle, type: SnackType.success);

  static void error(BuildContext context, String title, {String? subtitle}) =>
      show(context, title: title, subtitle: subtitle, type: SnackType.error);

  static void warning(BuildContext context, String title, {String? subtitle}) =>
      show(context, title: title, subtitle: subtitle, type: SnackType.warning);

  static void info(BuildContext context, String title, {String? subtitle}) =>
      show(context, title: title, subtitle: subtitle, type: SnackType.info);

  static void loading(BuildContext context, String title, {String? subtitle}) =>
      show(context, title: title, subtitle: subtitle, type: SnackType.loading);

  static void hide(BuildContext context) =>
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

// ── Internal widget ────────────────────────────────────────────────────────────

class _TbSnackContent extends StatelessWidget {
  const _TbSnackContent({
    required this.title,
    required this.type,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final SnackType type;

  @override
  Widget build(BuildContext context) {
    final config = _SnackConfig.from(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: type == SnackType.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: config.accent,
                      backgroundColor: config.accent.withOpacity(0.2),
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: config.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: config.accent.withOpacity(0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        config.symbol,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: config.accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: config.accent,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: config.sub,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Icon(Icons.close_rounded, size: 16, color: config.sub),
          ),
        ],
      ),
    );
  }
}

// ── Config per type ────────────────────────────────────────────────────────────

class _SnackConfig {
  const _SnackConfig({
    required this.bg,
    required this.border,
    required this.accent,
    required this.sub,
    required this.symbol,
  });

  final Color bg;
  final Color border;
  final Color accent;
  final Color sub;
  final String symbol;

  factory _SnackConfig.from(SnackType type) {
    switch (type) {
      case SnackType.success:
        return const _SnackConfig(
          bg: Color(0xFF0A1F1F),
          border: Color(0xFF0F6E56),
          accent: AppColors.success, // #95D1D1 teal
          sub: Color(0xFF5DCAA5),
          symbol: '✓',
        );
      case SnackType.error:
        return const _SnackConfig(
          bg: Color(0xFF1C0A0B),
          border: AppColors.errorContainer, // #93000A
          accent: AppColors.error, // #FFB4AB
          sub: Color(0xFFF09595),
          symbol: '✕',
        );
      case SnackType.warning:
        return const _SnackConfig(
          bg: Color(0xFF1C1400),
          border: Color(0xFF633806),
          accent: AppColors.warning, // #F5A623 gold
          sub: Color(0xFFEF9F27),
          symbol: '!',
        );
      case SnackType.info:
        return const _SnackConfig(
          bg: Color(0xFF0A1520),
          border: Color(0xFF185FA5),
          accent: Color(0xFF85B7EB),
          sub: Color(0xFF378ADD),
          symbol: 'i',
        );
      case SnackType.loading:
        return const _SnackConfig(
          bg: AppColors.surfaceContLow, // #1C1B1B
          border: AppColors.surfaceContHighest, // #353534
          accent: AppColors.primary, // #FFB955 gold
          sub: AppColors.muted, // #9F8E7A
          symbol: '',
        );
    }
  }
}
