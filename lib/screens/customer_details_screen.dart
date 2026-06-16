// lib/screens/customer_details_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';
import 'package:tailor_book/core/utils/phoneFormatter.dart';
import 'package:tailor_book/widgets/fullscreen_viewer.dart';
import 'package:tailor_book/widgets/tb_avatar.dart';
import 'package:tailor_book/widgets/tb_card.dart';
import 'package:tailor_book/widgets/tb_msc_widget.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../core/theme/app_colors.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import 'edit_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  List<CustomerImage> _images = [];
  bool _loading = true;
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadImages();
  }

  Future<void> _loadImages() async {
    final db = DatabaseHelper();
    final raw = await db.getCustomerImages(_customer.id!);
    final appDir = await getApplicationDocumentsDirectory();

    if (mounted) {
      setState(() {
        _images = raw.map((e) {
          final map = Map<String, dynamic>.from(e);
          final storedPath = e['image_path'] as String;

          // Old records have absolute paths (start with /)
          // New records have relative paths (start with customer_images/...)
          // Handle both:
          if (storedPath.startsWith('/')) {
            map['image_path'] = storedPath; // already absolute, use as-is
          } else {
            map['image_path'] = path.join(
              appDir.path,
              storedPath,
            ); // reconstruct
          }

          return CustomerImage.fromMap(map);
        }).toList();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final db = DatabaseHelper();
    final raw = await db.getCustomer(_customer.id!);
    if (raw != null && mounted) {
      setState(() => _customer = Customer.fromMap(raw));
    }
    await _loadImages();
    if (mounted) context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildImagesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // Floating edit button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EditCustomerScreen(customer: _customer, images: _images),
            ),
          );
          if (result == true) _refresh();
        },
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  // ── Sliver App Bar with hero avatar ────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C1B1B), AppColors.background],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              TbAvatar(name: _customer.name, radius: 44),
              const SizedBox(height: 14),
              Text(
                _customer.name,
                style: AppTextStyles.headlineMd(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    PhoneFormatter.toIndianStandard(_customer.mobileNumber),
                    style: AppTextStyles.labelMd().copyWith(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info card ───────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final created = DateTime.tryParse(_customer.createdAt);
    final dateStr = created != null
        ? '${created.day.toString().padLeft(2, '0')} '
              '${_monthName(created.month)} ${created.year}'
        : '—';

    return TbCard(
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'IMAGES',
              value: '${_images.length}',
              icon: Icons.photo_library_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.hairline),
          Expanded(
            child: _Stat(
              label: 'ADDED',
              value: dateStr,
              icon: Icons.calendar_today_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ── Images section ──────────────────────────────────────────────────────────

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TbSectionHeader(
          'Reference Photos',
          trailing: Text(
            '${_images.length}',
            style: AppTextStyles.labelMd(color: AppColors.primaryAccent),
          ),
        ),
        const SizedBox(height: 14),
        if (_images.isEmpty)
          TbEmptyState(
            icon: Icons.photo_outlined,
            title: 'No photos yet',
            subtitle: 'Tap the edit button to add reference images',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, i) {
              print(_images.first.imagePath);
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenGallery(images: _images, initialIndex: i),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_images[i].imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceContHigh,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      // Subtle border overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairline),
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
    return n[m];
  }
}

// ── Stat cell inside info card ─────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.bodyLg(
            color: AppColors.onSurface,
          ).copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelMd()),
      ],
    );
  }
}
