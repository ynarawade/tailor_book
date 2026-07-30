import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../core/theme/atelier_theme.dart';
import '../main.dart'; // import global themeController instance

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return LucideIcons.sun;
      case ThemeMode.dark:
        return LucideIcons.moon;
      case ThemeMode.system:
        return LucideIcons.monitor;
    }
  }

  void _showThemeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: themeController,
          builder: (context, _) {
            final currentMode = themeController.themeMode;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'SELECT APPEARANCE',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 11,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      context: ctx,
                      title: 'Light',
                      subtitle: 'Always use light theme',
                      icon: LucideIcons.sun,
                      mode: ThemeMode.light,
                      isSelected: currentMode == ThemeMode.light,
                    ),
                    _buildRadioOption(
                      context: ctx,
                      title: 'Dark',
                      subtitle: 'Always use dark theme',
                      icon: LucideIcons.moon,
                      mode: ThemeMode.dark,
                      isSelected: currentMode == ThemeMode.dark,
                    ),
                    _buildRadioOption(
                      context: ctx,
                      title: 'System Default',
                      subtitle: 'Match system theme settings',
                      icon: LucideIcons.monitor,
                      mode: ThemeMode.system,
                      isSelected: currentMode == ThemeMode.system,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        size: 18,
        color: isSelected
            ? AtelierTheme.brandPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: Radio<ThemeMode>(
        value: mode,
        groupValue: themeController.themeMode,
        activeColor: AtelierTheme.brandPrimary,
        onChanged: (value) {
          if (value != null) {
            themeController.setThemeMode(value);
            Navigator.pop(context);
          }
        },
      ),
      onTap: () {
        themeController.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final currentMode = themeController.themeMode;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APPEARANCE',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showThemeDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getThemeIcon(currentMode),
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getThemeName(currentMode),
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
