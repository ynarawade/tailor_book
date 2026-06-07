// Contains: TbSectionHeader, TbBadge, TbEmptyState, TbInfoRow

import 'package:flutter/material.dart';
import 'package:tailor_book/core/theme/app_colors.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TbSectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class TbSectionHeader extends StatelessWidget {
  const TbSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMd(color: AppColors.muted),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TbBadge — small pill with icon + count, used on customer cards
// ─────────────────────────────────────────────────────────────────────────────

class TbBadge extends StatelessWidget {
  const TbBadge({super.key, required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.labelMd(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TbEmptyState — centered icon + title + subtitle
// ─────────────────────────────────────────────────────────────────────────────

class TbEmptyState extends StatelessWidget {
  const TbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContLow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Icon(icon, size: 40, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.headlineSm(color: AppColors.onSurface),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMd(),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TbInfoRow — icon + label used in detail / backup screens
// ─────────────────────────────────────────────────────────────────────────────

class TbInfoRow extends StatelessWidget {
  const TbInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = AppColors.muted,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd())),
        ],
      ),
    );
  }
}
