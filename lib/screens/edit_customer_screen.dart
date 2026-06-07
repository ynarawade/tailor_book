import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';
import 'package:tailor_book/widgets/tb_button.dart';
import 'package:tailor_book/widgets/tb_card.dart';
import 'package:tailor_book/widgets/tb_img_grid.dart';
import 'package:tailor_book/widgets/tb_input_field.dart';
import 'package:tailor_book/widgets/tb_msc_widget.dart';

import '../core/theme/app_colors.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';

class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({
    super.key,
    required this.customer,
    required this.images,
  });

  final Customer customer;
  final List<CustomerImage> images;

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late List<CustomerImage> _existing;
  final List<XFile> _new = [];
  final _picker = ImagePicker();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _mobileCtrl = TextEditingController(text: widget.customer.mobileNumber);
    _existing = List.from(widget.images);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) setState(() => _new.add(img));
  }

  Future<void> _pickGallery() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _new.addAll(imgs));
  }

  void _removeExisting(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _existing.removeAt(index));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final db = DatabaseHelper();

      // Update customer info
      await db.updateCustomer(widget.customer.id!, {
        'name': _nameCtrl.text.trim(),
        'mobile_number': _mobileCtrl.text.trim(),
      });

      // Delete removed images
      final originalIds = widget.images.map((e) => e.id!).toSet();
      final currentIds = _existing.map((e) => e.id!).toSet();
      for (final id in originalIds.difference(currentIds)) {
        final img = widget.images.firstWhere((e) => e.id == id);
        await db.deleteImage(id);
        final f = File(img.imagePath);
        if (await f.exists()) await f.delete();
      }

      // Save new images
      if (_new.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final customerDir = Directory(
          p.join(dir.path, 'customer_images', 'customer_${widget.customer.id}'),
        );
        if (!await customerDir.exists()) {
          await customerDir.create(recursive: true);
        }
        for (int i = 0; i < _new.length; i++) {
          final name = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final dest = p.join(customerDir.path, name);
          await File(_new[i].path).copy(dest);
          await db.insertImage({
            'customer_id': widget.customer.id,
            'image_path': dest,
            'image_type': 'general',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _existing.length + _new.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Client',
          style: AppTextStyles.headlineSm(color: AppColors.primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: AppTextStyles.bodyMd(
                      color: AppColors.primaryAccent,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Personal details ─────────────────────────────────────────────
            const TbSectionHeader('Personal Details'),
            const SizedBox(height: 10),
            TbCard(
              child: Column(
                children: [
                  TbInputField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TbInputField(
                    label: 'Phone Number',
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                        return 'Enter at least 10 digits';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Photos ───────────────────────────────────────────────────────
            TbSectionHeader(
              'Reference Photos',
              trailing: Text(
                '$totalImages',
                style: AppTextStyles.labelMd(color: AppColors.primaryAccent),
              ),
            ),
            const SizedBox(height: 10),
            TbCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCamera,
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryAccent,
                            side: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickGallery,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                          ),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryAccent,
                            side: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (totalImages > 0) ...[
                    const SizedBox(height: 16),
                    TbImageGrid(
                      existingPaths: _existing.map((e) => e.imagePath).toList(),
                      newPaths: _new.map((x) => x.path).toList(),
                      onRemoveExisting: _removeExisting,
                      onRemoveNew: (i) => setState(() => _new.removeAt(i)),
                      onAddTap: _pickGallery,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            TbButton(
              label: 'Save Changes',
              onPressed: _save,
              isLoading: _loading,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
