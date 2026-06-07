import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tailor_book/core/theme/app_colors.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';

/// Generic image grid used in both AddCustomerScreen and EditCustomerScreen.
///
/// [existingPaths]  — already-saved image file paths (shown first)
/// [newPaths]       — just-picked image paths (shown with NEW badge)
/// [onRemoveExisting] / [onRemoveNew] — called when user taps ✕
/// [onAddTap]       — called when user taps the + tile (open picker)
/// [onImageTap]     — called with (allPaths, tappedIndex) for full-screen view
class TbImageGrid extends StatelessWidget {
  const TbImageGrid({
    super.key,
    this.existingPaths = const [],
    this.newPaths = const [],
    this.onRemoveExisting,
    this.onRemoveNew,
    this.onAddTap,
    this.onImageTap,
  });

  final List<String> existingPaths;
  final List<String> newPaths;
  final void Function(int index)? onRemoveExisting;
  final void Function(int index)? onRemoveNew;
  final VoidCallback? onAddTap;
  final void Function(List<String> all, int index)? onImageTap;

  List<String> get _allPaths => [...existingPaths, ...newPaths];

  @override
  Widget build(BuildContext context) {
    final totalItems =
        existingPaths.length + newPaths.length + 1; // +1 for add tile

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Last tile is always the "add" tile
        if (index == totalItems - 1) {
          return _AddTile(onTap: onAddTap);
        }

        if (index < existingPaths.length) {
          return _ImageTile(
            path: existingPaths[index],
            onRemove: onRemoveExisting != null
                ? () => onRemoveExisting!(index)
                : null,
            onTap: onImageTap != null
                ? () => onImageTap!(_allPaths, index)
                : null,
          );
        }

        final newIndex = index - existingPaths.length;
        return _ImageTile(
          path: newPaths[newIndex],
          isNew: true,
          onRemove: onRemoveNew != null ? () => onRemoveNew!(newIndex) : null,
          onTap: onImageTap != null
              ? () => onImageTap!(_allPaths, index)
              : null,
        );
      },
    );
  }
}

// ── Private tiles ─────────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.path,
    this.isNew = false,
    this.onRemove,
    this.onTap,
  });

  final String path;
  final bool isNew;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceContHigh,
                child: const Icon(Icons.broken_image, color: AppColors.muted),
              ),
            ),
          ),

          // Gradient scrim so badges are readable
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // NEW badge
          if (isNew)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NEW',
                  style: AppTextStyles.labelMd(color: Colors.black),
                ),
              ),
            ),

          // Remove button
          if (onRemove != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCont,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primaryAccent, size: 24),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: AppTextStyles.labelMd(color: AppColors.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }
}
