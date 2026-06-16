// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';
import 'package:tailor_book/core/utils/phoneFormatter.dart';
import 'package:tailor_book/widgets/tb_avatar.dart';
import 'package:tailor_book/widgets/tb_card.dart';
import 'package:tailor_book/widgets/tb_msc_widget.dart';
import 'package:tailor_book/widgets/tb_snackbar.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../core/theme/app_colors.dart';
import '../models/customer.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            'TailorBook',
            style: AppTextStyles.headlineMd(color: AppColors.primary),
          ),
          const Spacer(),
          BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              final count = state is CustomerLoaded
                  ? state.customers.length
                  : 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Text(
                  '$count clients',
                  style: AppTextStyles.labelMd(color: AppColors.muted),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyLg(),
        decoration: InputDecoration(
          hintText: 'Search customers...',
          hintStyle: AppTextStyles.bodyMd(color: AppColors.muted),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.muted,
            size: 20,
          ),
          suffixIcon: const Icon(
            Icons.mic_none,
            color: AppColors.muted,
            size: 20,
          ),
        ),
        onChanged: (v) => context.read<CustomerBloc>().add(SearchCustomers(v)),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerAdded || state is CustomerDeleted) {
          final msg = state is CustomerAdded
              ? state.message
              : (state as CustomerDeleted).message;
          TbSnackbar.success(context, msg);
        } else if (state is CustomerError) {
          TbSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }

        if (state is CustomerLoaded) {
          if (state.customers.isEmpty) {
            return TbEmptyState(
              icon: Icons.people_outline,
              title: 'No customers yet',
              subtitle: _searchController.text.isNotEmpty
                  ? 'No results for "${_searchController.text}"'
                  : 'Tap the scissors button to add your first client',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: state.customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CustomerCard(
              key: ValueKey(state.customers[i].id),
              customer: state.customers[i],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        );
        // Bloc already reloads internally after AddCustomer
      },
      backgroundColor: AppColors.primaryAccent,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      child: const Icon(Icons.content_cut_rounded, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Customer card — extracted as its own widget for clean rebuilds
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key ?? ValueKey(customer.id),
      direction: DismissDirection.endToStart, // Swipe from right to left only
      // ── Swipe Background Layout ───────────────────────────────────────────
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: AppColors.error, // Soft red background
          borderRadius: BorderRadius.circular(
            12,
          ), // Match your card corner radius
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),

      // ── Confirm Swipe Action ──────────────────────────────────────────────
      confirmDismiss: (direction) async {
        // Triggers your existing confirmation dialog
        return await _showDeleteDialog(context);
      },

      // ── Dispatch Action on Confirmed Swipe ────────────────────────────────
      onDismissed: (direction) {
        context.read<CustomerBloc>().add(DeleteCustomer(customer.id!));
      },

      // ── Your Original Card UI (Minus the explicit trash icon) ──────────────
      child: TbCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(customer: customer),
          ),
        ),
        child: Row(
          children: [
            TbAvatar(name: customer.name, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: AppTextStyles.headlineSm(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        PhoneFormatter.toIndianStandard(customer.mobileNumber),
                        style: AppTextStyles.labelMd().copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TbBadge(
                        icon: Icons.photo_library_outlined,
                        count: customer.imageCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Explicit delete button removed for a much cleaner look!
          ],
        ),
      ),
    );
  }

  // ── Updated Dialog to return a boolean ─────────────────────────────────────
  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Remove ${customer.name} and all their images? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, false), // Cancel swipe return false
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.onSurface),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, true), // Confirm swipe return true
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
