// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';
import 'package:tailor_book/widgets/tb_avatar.dart';
import 'package:tailor_book/widgets/tb_card.dart';
import 'package:tailor_book/widgets/tb_msc_widget.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: state is CustomerAdded
                  ? AppColors.secondary
                  : AppColors.warning,
            ),
          );
        } else if (state is CustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorContainer,
            ),
          );
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
            itemBuilder: (context, i) =>
                _CustomerCard(customer: state.customers[i]),
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
  const _CustomerCard({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return TbCard(
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
                    Text(customer.mobileNumber, style: AppTextStyles.bodyMd()),
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
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.muted,
              size: 20,
            ),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Remove ${customer.name} and all their images? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerBloc>().add(DeleteCustomer(customer.id!));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
