import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';
import 'package:tailor_book/widgets/tb_button.dart';
import 'package:tailor_book/widgets/tb_card.dart';
import 'package:tailor_book/widgets/tb_img_grid.dart';
import 'package:tailor_book/widgets/tb_input_field.dart';
import 'package:tailor_book/widgets/tb_msc_widget.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../core/theme/app_colors.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────────

  Future<void> _pickCamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) setState(() => _images.add(img));
  }

  Future<void> _pickGallery() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _images.addAll(imgs));
  }

  Future<void> _pickContact() async {
    try {
      var status = await Permission.contacts.status;
      if (status.isDenied) status = await Permission.contacts.request();
      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return;
      }
      if (!status.isGranted) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primaryAccent),
              SizedBox(width: 16),
              Text('Loading contacts...'),
            ],
          ),
        ),
      );

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (mounted) Navigator.pop(context);

      final withPhone = contacts.where((c) => c.phones.isNotEmpty).toList();
      if (withPhone.isEmpty) return;

      if (!mounted) return;
      final selected = await showDialog<Contact>(
        context: context,
        builder: (_) => _ContactPickerDialog(contacts: withPhone),
      );

      if (selected != null) {
        setState(() {
          _nameCtrl.text = selected.displayName;
          if (selected.phones.isNotEmpty) {
            _mobileCtrl.text = selected.phones.first.number.replaceAll(
              RegExp(r'[^\d+]'),
              '',
            );
          }
        });
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Contacts access is permanently denied. Enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }
    context.read<CustomerBloc>().add(
      AddCustomer(
        name: _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        imagePaths: _images.map((x) => x.path).toList(),
      ),
    );
    Navigator.pop(context, true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Client',
          style: AppTextStyles.headlineSm(color: AppColors.primary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
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
            TbSectionHeader('Personal Details'),
            const SizedBox(height: 10),
            TbCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TbInputField(
                          label: 'Full Name',
                          hint: 'e.g. Ananya Sharma',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ContactButton(onTap: _pickContact),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TbInputField(
                    label: 'Phone Number',
                    hint: '+91 98765 43210',
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

            // ── Reference photos ─────────────────────────────────────────────
            TbSectionHeader(
              'Reference Photos',
              trailing: Text(
                '${_images.length}',
                style: AppTextStyles.labelMd(color: AppColors.primaryAccent),
              ),
            ),
            const SizedBox(height: 10),
            TbCard(
              child: Column(
                children: [
                  // Picker chips
                  Row(
                    children: [
                      _PickerChip(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take Photo',
                        onTap: _pickCamera,
                      ),
                      const SizedBox(width: 10),
                      _PickerChip(
                        icon: Icons.photo_library_outlined,
                        label: 'Upload Gallery',
                        onTap: _pickGallery,
                      ),
                    ],
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TbImageGrid(
                      newPaths: _images.map((x) => x.path).toList(),
                      onRemoveNew: (i) => setState(() => _images.removeAt(i)),
                      onAddTap: _pickGallery,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            TbButton(
              label: 'Save Client Profile',
              onPressed: _save,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets local to this screen ────────────────────────────────

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceContHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: const Icon(
          Icons.contacts_outlined,
          color: AppColors.primaryAccent,
          size: 20,
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          side: const BorderSide(color: AppColors.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: AppTextStyles.labelMd(color: AppColors.primaryAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Contact picker dialog — same logic, new styling
// ─────────────────────────────────────────────────────────────────────────────

class _ContactPickerDialog extends StatefulWidget {
  const _ContactPickerDialog({required this.contacts});
  final List<Contact> contacts;

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  late List<Contact> _filtered;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.contacts;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contact'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.muted,
                  size: 18,
                ),
              ),
              onChanged: (v) => setState(() {
                _filtered = widget.contacts
                    .where(
                      (c) =>
                          c.displayName.toLowerCase().contains(v.toLowerCase()),
                    )
                    .toList();
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No contacts found'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryAccent,
                            child: Text(
                              c.displayName.isNotEmpty
                                  ? c.displayName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.bodyMd(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            c.displayName,
                            style: AppTextStyles.bodyLg(),
                          ),
                          subtitle: c.phones.isNotEmpty
                              ? Text(
                                  c.phones.first.number,
                                  style: AppTextStyles.metadataSm(),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
