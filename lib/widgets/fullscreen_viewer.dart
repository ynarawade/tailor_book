import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../core/theme/atelier_theme.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import 'tb_snackbar.dart';

class FullScreenGallery extends StatefulWidget {
  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onImagesUpdated,
  });

  final List<CustomerImage> images;
  final int initialIndex;

  /// Callback to notify parent screens (like CustomerDetailsScreen) to refresh images
  final VoidCallback? onImagesUpdated;

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _controller;
  late int _current;
  late List<CustomerImage> _imageList;
  bool _isDeleting = false;

  // Controllers for double tap zoom
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _imageList = List.from(widget.images);
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // ── Zoom Controls ──────────────────────────────────────────────────────────

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Zoom out if already zoomed in
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in at double-tapped position
      final position = _doubleTapDetails?.localPosition;
      if (position != null) {
        _transformationController.value = Matrix4.identity()
          ..translate(-position.dx * 1.5, -position.dy * 1.5)
          ..scale(2.5);
      }
    }
  }

  // ── Image Deletion Handler ──────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    if (_imageList.isEmpty || _isDeleting) return;

    final imageToDelete = _imageList[_current];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete attachment?',
          style: AtelierTheme.displayFont(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This action will permanently delete this image.',
          style: AtelierTheme.textFont(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: AtelierTheme.textFont(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtelierTheme.darkError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Delete',
                    style: AtelierTheme.textFont(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final db = DatabaseHelper();

      // 1. Delete record from database
      if (imageToDelete.id != null) {
        await db.deleteImage(imageToDelete.id!);
      }

      // 2. Delete actual file from device filesystem
      final file = File(imageToDelete.imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Notify parent widget of update
      widget.onImagesUpdated?.call();

      if (!mounted) return;

      // 4. Update internal list
      setState(() {
        _imageList.removeAt(_current);
        _isDeleting = false;
      });

      TbSnackbar.success(context, 'Attachment deleted');

      // 5. If no images remain, close viewer
      if (_imageList.isEmpty) {
        Navigator.pop(context, true);
        return;
      }

      // 6. Adjust current page index
      if (_current >= _imageList.length) {
        _current = _imageList.length - 1;
      }

      // Reset zoom scale
      _transformationController.value = Matrix4.identity();
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        TbSnackbar.error(context, 'Failed to delete attachment');
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _imageList.isNotEmpty ? '${_current + 1} / ${_imageList.length}' : '',
          style: AtelierTheme.textFont(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    LucideIcons.trash_2,
                    size: 20,
                    color: Colors.redAccent,
                  ),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _imageList.isEmpty
          ? const SizedBox.shrink()
          : PageView.builder(
              controller: _controller,
              itemCount: _imageList.length,
              onPageChanged: (i) {
                setState(() {
                  _current = i;
                  // Reset zoom level whenever swiping to another image
                  _transformationController.value = Matrix4.identity();
                });
              },
              itemBuilder: (context, i) {
                return GestureDetector(
                  onDoubleTapDown: _handleDoubleTapDown,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    clipBehavior: Clip.none,
                    child: Center(
                      child: Image.file(
                        File(_imageList[i].imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            LucideIcons.image_off,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
