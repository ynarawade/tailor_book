import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../core/theme/atelier_theme.dart';
import '../core/utils/phoneFormatter.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../services/image_compress_util.dart';
import '../widgets/fullscreen_viewer.dart';
import '../widgets/tb_snackbar.dart';
import 'edit_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});
  final int customerId;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  Customer? _customer;
  List<CustomerImage> _images = [];
  bool _loading = true;
  bool _addingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  // ── Database & State Loading ────────────────────────────────────────────────

  Future<void> _loadCustomerData() async {
    final db = DatabaseHelper();

    // 1. Fetch customer details by ID
    final rawCustomer = await db.getCustomer(widget.customerId);

    if (rawCustomer == null) {
      if (mounted) {
        TbSnackbar.error(context, 'Customer not found');
        Navigator.pop(context);
      }
      return;
    }

    final loadedCustomer = Customer.fromMap(rawCustomer);

    // 2. Fetch customer attachments
    final rawImages = await db.getCustomerImages(widget.customerId);
    final appDir = await getApplicationDocumentsDirectory();

    final loadedImages = rawImages.map((e) {
      final map = Map<String, dynamic>.from(e);
      final storedPath = e['image_path'] as String;

      if (storedPath.startsWith('/')) {
        map['image_path'] = storedPath;
      } else {
        map['image_path'] = path.join(appDir.path, storedPath);
      }

      return CustomerImage.fromMap(map);
    }).toList();

    if (mounted) {
      setState(() {
        _customer = loadedCustomer;
        _images = loadedImages;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadCustomerData();
    if (mounted) context.read<CustomerBloc>().add(LoadCustomers());
  }

  // ── Contact Actions ──────────────────────────────────────────────────────────

  Future<void> _handleCall() async {
    if (_customer == null || _customer!.mobileNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:${_customer!.mobileNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) TbSnackbar.error(context, 'Cannot open phone dialer');
    }
  }

  Future<void> _handleWhatsApp() async {
    if (_customer == null || _customer!.mobileNumber.isEmpty) return;
    final cleanNum = _customer!.mobileNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri appUrl = Uri.parse('whatsapp://send?phone=$cleanNum');
    final Uri webUrl = Uri.parse(
      'https://wa.me/${cleanNum.replaceAll('+', '')}',
    );

    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) TbSnackbar.error(context, 'WhatsApp is not installed');
    }
  }

  // ── Add Attachments Direct Flow ─────────────────────────────────────────────

  void _showAttachmentPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add attachment',
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _SheetRow(
              icon: LucideIcons.image,
              label: 'Choose from library',
              onTap: () {
                Navigator.pop(ctx);
                _attachImages(ImageSource.gallery);
              },
            ),
            _SheetRow(
              icon: LucideIcons.camera,
              label: 'Take a photo',
              onTap: () {
                Navigator.pop(ctx);
                _attachImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachImages(ImageSource source) async {
    if (_customer == null) return;

    try {
      final List<XFile> selected = [];
      if (source == ImageSource.gallery) {
        final imgs = await _picker.pickMultiImage();
        selected.addAll(imgs);
      } else {
        final img = await _picker.pickImage(source: ImageSource.camera);
        if (img != null) selected.add(img);
      }

      if (selected.isEmpty) return;

      setState(() => _addingImage = true);

      final db = DatabaseHelper();
      final appDir = await getApplicationDocumentsDirectory();
      final customerDirSubPath = 'customer_images/customer_${_customer!.id}';
      final customerDir = Directory(path.join(appDir.path, customerDirSubPath));

      if (!await customerDir.exists()) {
        await customerDir.create(recursive: true);
      }

      for (int i = 0; i < selected.length; i++) {
        final compressed = await ImageCompressUtil.compressAndSave(selected[i]);
        final sourceFile = File(compressed?.path ?? selected[i].path);

        final fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final absoluteNewPath = path.join(customerDir.path, fileName);
        final relativeDatabasePath = path.join(customerDirSubPath, fileName);

        if (await sourceFile.exists()) {
          await sourceFile.rename(absoluteNewPath);
        }

        await db.insertImage({
          'customer_id': _customer!.id,
          'image_path': relativeDatabasePath,
          'image_type': 'general',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _refresh();
      if (mounted) TbSnackbar.success(context, 'Attachment added successfully');
    } catch (e) {
      if (mounted) TbSnackbar.error(context, 'Failed to save attachment');
    } finally {
      if (mounted) setState(() => _addingImage = false);
    }
  }

  // ── Customer Deletion Flow ──────────────────────────────────────────────────

  Future<void> _confirmDeleteCustomer() async {
    if (_customer == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete client?',
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This will permanently remove ${_customer!.name} and all attachments.',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.grey.shade400,
            fontSize: 14,
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
                    style: TextStyle(
                      fontFamily: 'Satoshi',
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
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
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

    if (confirmed == true && mounted) {
      context.read<CustomerBloc>().add(DeleteCustomer(_customer!.id!));
      Navigator.pop(context);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _loading || _customer == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AtelierTheme.brandPrimary,
                  strokeWidth: 2,
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildClientDetails(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 32),
                          _buildAttachmentsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Sub-Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevron_left, size: 24),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 18),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditCustomerScreen(customer: _customer!, images: _images),
                ),
              );
              if (result == true) _refresh();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash_2, size: 18),
            color: AtelierTheme.darkError,
            onPressed: _confirmDeleteCustomer,
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails() {
    final created = DateTime.tryParse(_customer!.createdAt);
    final dateStr = created != null
        ? '${created.day} ${_monthName(created.month)} ${created.year}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLIENT',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 11,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _customer!.name,
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 34,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          PhoneFormatter.toIndianStandard(_customer!.mobileNumber),
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 15,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Added $dateStr',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleCall,
            icon: Icon(
              LucideIcons.phone,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              'Call',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleWhatsApp,
            icon: Icon(
              LucideIcons.message_circle,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              'WhatsApp',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ATTACHMENTS · ${_images.length}',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            InkWell(
              onTap: _showAttachmentPickerSheet,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: const [
                    Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: AtelierTheme.brandPrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AtelierTheme.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_addingImage) ...[
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AtelierTheme.brandPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Compressing image…',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (_images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.image, size: 28, color: Colors.grey.shade600),
                const SizedBox(height: 10),
                Text(
                  'No attachments yet.\nAdd measurement sheets, bills, or design photos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () async {
                  // Opens the viewer and waits for user to return
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGallery(
                        images: _images,
                        initialIndex: i,
                        onImagesUpdated:
                            _refresh, // Instantly updates list on delete
                      ),
                    ),
                  );

                  // Ensures screen updates when user comes back
                  if (mounted) {
                    _refresh();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_images[i].imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: const Icon(
                            LucideIcons.image_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _monthName(int m) {
    const n = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (m >= 1 && m <= 12) ? n[m] : '';
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
