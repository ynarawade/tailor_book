import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../core/theme/atelier_theme.dart';

enum SnackType { success, error, warning, info, loading }

class TbSnackbar {
  TbSnackbar._();

  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required SnackType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any currently visible top snackbar immediately
    hide(context);

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopSnackWrapper(
        title: title,
        subtitle: subtitle,
        type: type,
        duration: duration,
        onDismiss: () {
          overlayEntry.remove();
          if (_currentOverlay == overlayEntry) {
            _currentOverlay = null;
          }
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  // ── Convenience Shortcuts ──────────────────────────────────────────────────

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

  static void hide(BuildContext context) {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

// ── Top Dropdown Animation & Wrapper ──────────────────────────────────────────

class _TopSnackWrapper extends StatefulWidget {
  const _TopSnackWrapper({
    required this.title,
    required this.type,
    required this.onDismiss,
    required this.duration,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final SnackType type;
  final VoidCallback onDismiss;
  final Duration duration;

  @override
  State<_TopSnackWrapper> createState() => _TopSnackWrapperState();
}

class _TopSnackWrapperState extends State<_TopSnackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0), // Starts completely off-screen above
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Auto dismiss if not loading
    if (widget.type != SnackType.loading) {
      _timer = Timer(widget.duration, _dismiss);
    }
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _SnackStyle.of(context, widget.type, isDark);

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: style.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: style.borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Indicator Container
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: style.iconBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: style.accentColor.withOpacity(0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: widget.type == SnackType.loading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    style.accentColor,
                                  ),
                                ),
                              )
                            : Icon(
                                style.icon,
                                size: 16,
                                color: style.accentColor,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Subtitle Text Block
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: style.textColor,
                              height: 1.25,
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontStyle: FontStyle.normal,
                                fontFamily: 'Satoshi',
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: style.subtitleColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Close Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      splashRadius: 16,
                      icon: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: style.subtitleColor,
                      ),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Style Resolution Per Theme & Type ─────────────────────────────────────────

class _SnackStyle {
  const _SnackStyle({
    required this.bgColor,
    required this.borderColor,
    required this.accentColor,
    required this.iconBg,
    required this.textColor,
    required this.subtitleColor,
    required this.icon,
  });

  final Color bgColor;
  final Color borderColor;
  final Color accentColor;
  final Color iconBg;
  final Color textColor;
  final Color subtitleColor;
  final IconData icon;

  factory _SnackStyle.of(BuildContext context, SnackType type, bool isDark) {
    final surfaceColor = isDark
        ? AtelierTheme.darkSurfaceSecondary
        : AtelierTheme.lightSurfaceSecondary;
    final onSurface = isDark
        ? AtelierTheme.darkOnSurface
        : AtelierTheme.lightOnSurface;
    final mutedText = isDark ? AtelierTheme.darkMuted : AtelierTheme.lightMuted;

    late final Color accent;
    late final IconData iconData;

    switch (type) {
      case SnackType.success:
        accent = const Color(0xFF2E7D32);
        iconData = LucideIcons.check;
        break;
      case SnackType.error:
        accent = isDark ? AtelierTheme.darkError : AtelierTheme.lightError;
        iconData = LucideIcons.triangle_alert;
        break;
      case SnackType.warning:
        accent = const Color(0xFFD97706);
        iconData = LucideIcons.circle_alert;
        break;
      case SnackType.info:
        accent = AtelierTheme.brandPrimary;
        iconData = LucideIcons.info;
        break;
      case SnackType.loading:
        accent = AtelierTheme.brandPrimary;
        iconData = LucideIcons.loader;
        break;
    }

    return _SnackStyle(
      bgColor: surfaceColor.withOpacity(isDark ? 0.92 : 0.96),
      borderColor: isDark
          ? AtelierTheme.darkBorderStrong.withOpacity(0.5)
          : AtelierTheme.lightBorderStrong.withOpacity(0.6),
      accentColor: accent,
      iconBg: accent.withOpacity(0.12),
      textColor: onSurface,
      subtitleColor: mutedText,
      icon: iconData,
    );
  }
}
