import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../core/theme/atelier_theme.dart';
import '../core/utils/phoneFormatter.dart';
import '../models/customer.dart';
import '../widgets/tb_snackbar.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';
import 'settings_screen.dart';

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
    final currentState = context.read<CustomerBloc>().state;
    if (currentState is CustomerLoaded) {
      _searchController.text = currentState.activeSearchQuery;
    } else {
      context.read<CustomerBloc>().add(LoadCustomers());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Refreshes the list respecting the current search context
  void _refreshList() {
    if (!mounted) return;
    final currentState = context.read<CustomerBloc>().state;
    if (currentState is CustomerLoaded &&
        currentState.activeSearchQuery.isNotEmpty) {
      context.read<CustomerBloc>().add(
        SearchCustomers(currentState.activeSearchQuery),
      );
    } else {
      context.read<CustomerBloc>().add(LoadCustomers());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(child: _buildList()),
              ],
            ),
            _buildFab(),
          ],
        ),
      ),
    );
  }

  // ── Editorial Header ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THE ATELIER',
                style: AtelierTheme.textFont(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoaded) {
                    final label = state.activeSearchQuery.isNotEmpty
                        ? 'FOUND'
                        : 'CLIENTS';
                    return Text(
                      '${state.customers.length}/${state.totalCount} $label',
                      style: AtelierTheme.textFont(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clients',
                style: AtelierTheme.displayFont(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, size: 22),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {}); // Updates clear icon visibility immediately
          context.read<CustomerBloc>().add(SearchCustomers(val));
        },
        style: AtelierTheme.textFont(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search client by name or phone...',
          hintStyle: AtelierTheme.textFont(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: Colors.grey.shade500,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: Colors.grey.shade500,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    context.read<CustomerBloc>().add(SearchCustomers(''));
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(
              color: AtelierTheme.brandPrimary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
  // ── Client List & States ─────────────────────────────────────────────────────

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
            child: CircularProgressIndicator(
              color: AtelierTheme.brandPrimary,
              strokeWidth: 2,
            ),
          );
        }

        if (state is CustomerLoaded) {
          if (state.customers.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            itemCount: state.customers.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => Divider(
              color: Theme.of(context).colorScheme.outline,
              height: 1,
              thickness: 0.5,
            ),
            itemBuilder: (context, i) {
              if (i == state.customers.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: state.isLoadingMore
                        ? const CircularProgressIndicator(
                            color: AtelierTheme.brandPrimary,
                            strokeWidth: 2,
                          )
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              context.read<CustomerBloc>().add(
                                LoadMoreCustomers(),
                              );
                            },
                            child: Text(
                              'Load More Clients',
                              style: AtelierTheme.textFont(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                  ),
                );
              }

              return _CustomerCard(
                key: ValueKey(state.customers[i].id),
                customer: state.customers[i],
                onRefresh: _refreshList,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isSearching) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://images.pexels.com/photos/7147459/pexels-photo-7147459.jpeg',
                  height: 220,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    width: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your atelier awaits.',
                textAlign: TextAlign.center,
                style: AtelierTheme.displayFont(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first client to begin your digital client book.',
                textAlign: TextAlign.center,
                style: AtelierTheme.textFont(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Icon(LucideIcons.search, size: 32, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No matches',
                style: AtelierTheme.displayFont(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different name or phone.',
                style: AtelierTheme.textFont(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton.extended(
          backgroundColor: AtelierTheme.brandPrimary,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            );
            _refreshList();
          },
          icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
          label: const Text(
            'New Client',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Customer Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
  });

  final Customer customer;
  final VoidCallback onRefresh;

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '·';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarBg = isDark
        ? AtelierTheme.brandTertiaryDark
        : AtelierTheme.brandTertiaryLight;
    final avatarTextColor = isDark
        ? const Color(0xFFE5C8A8)
        : const Color(0xFF5E2C23);

    return Dismissible(
      key: key ?? ValueKey(customer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        color: AtelierTheme.darkError,
        child: const Icon(LucideIcons.trash_2, color: Colors.white, size: 20),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteDialog(context);
      },
      onDismissed: (direction) {
        if (customer.id != null) {
          context.read<CustomerBloc>().add(DeleteCustomer(customer.id!));
        }
      },
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customerId: customer.id!),
            ),
          );
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(customer.name),
                  style: AtelierTheme.displayFont(
                    color: avatarTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AtelierTheme.displayFont(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.mobileNumber.isNotEmpty
                          ? PhoneFormatter.toIndianStandard(
                              customer.mobileNumber,
                            )
                          : '—',
                      style: AtelierTheme.textFont(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.paperclip,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${customer.imageCount}',
                          style: AtelierTheme.textFont(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete client?',
          style: AtelierTheme.displayFont(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This will permanently remove ${customer.name} and all associated photos.',
          style: AtelierTheme.textFont(
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
                    style: AtelierTheme.textFont(
                      fontSize: 12,
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
                      color: Colors.white,
                      fontSize: 12,
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
  }
}
