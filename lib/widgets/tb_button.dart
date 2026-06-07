import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailor_book/core/theme/app_colors.dart';

enum TbButtonVariant { primary, secondary, destructive }

class TbButton extends StatelessWidget {
  const TbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TbButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.minimumWidth = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final TbButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final textStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    final size = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(minimumWidth, 52)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStateProperty.all(textStyle),
    );

    return switch (variant) {
      TbButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          disabledBackgroundColor: AppColors.primaryAccent.withOpacity(0.4),
        ).merge(size),
        child: child,
      ),
      TbButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          side: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ).merge(size),
        child: child,
      ),
      TbButtonVariant.destructive => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorContainer,
          foregroundColor: AppColors.error,
          elevation: 0,
        ).merge(size),
        child: child,
      ),
    };
  }
}
