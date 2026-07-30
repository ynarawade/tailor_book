import 'package:atelier/screens/customer_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../core/theme/atelier_theme.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../widgets/tb_snackbar.dart';

class CustomerFormScreen extends StatefulWidget {
  /// Pass an existing [customer] for Edit mode, or leave null for Create mode.
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  Customer? _duplicateCustomer;
  bool get _isEditing => widget.customer != null;

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.mobileNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Contact Import ──────────────────────────────────────────────────────────

  Future<void> _pickContact() async {
    try {
      var status = await Permission.contacts.status;

      if (status.isDenied) {
        status = await Permission.contacts.request();
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return;
      }

      if (!status.isGranted) return;

      final contact = await _contactPicker.selectContact();

      if (contact == null) return;

      final rawPhone = contact.phoneNumbers?.isNotEmpty == true
          ? contact.phoneNumbers!.first
          : '';

      // Clean phone number: keep numbers and leading plus sign
      final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

      setState(() {
        _nameController.text = contact.fullName ?? '';
        _phoneController.text = cleanPhone;
      });

      // Instantly validate fields after contact picking
      _formKey.currentState?.validate();
    } catch (e) {
      if (mounted) {
        TbSnackbar.error(context, 'Failed to import contact');
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          'Permission Required',
          style: AtelierTheme.displayFont(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Contacts access is permanently denied. Please enable it in system settings.',
          style: AtelierTheme.textFont(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AtelierTheme.textFont(fontSize: 14, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtelierTheme.brandPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: AtelierTheme.textFont(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save Handler ────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_isEditing) {
      context.read<CustomerBloc>().add(
        UpdateCustomer(
          customerId: widget.customer!.id!,
          name: name,
          mobileNumber: phone,
        ),
      );
    } else {
      // Check for duplicate phone before adding
      final db = DatabaseHelper();
      final existingData = await db.getCustomerByMobile(phone);

      if (existingData != null) {
        setState(() {
          _duplicateCustomer = Customer.fromMap(existingData);
        });
        return;
      }

      context.read<CustomerBloc>().add(
        AddCustomer(name: name, mobileNumber: phone),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerAdded) {
          TbSnackbar.success(context, 'Client created');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CustomerDetailsScreen(customerId: state.customerId),
            ),
          );
        } else if (state is CustomerUpdated) {
          TbSnackbar.success(context, 'Client updated');
          Navigator.pop(context);
        } else if (state is CustomerError) {
          TbSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isSaving = state is CustomerLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormField(
                                label: 'NAME',
                                child: TextFormField(
                                  controller: _nameController,
                                  style: AtelierTheme.textFont(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    hintText: 'Client name',
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'Name is required'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _FormField(
                                label: 'PHONE',
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: AtelierTheme.textFont(
                                    fontSize: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '+1 555 000 0000',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    final digitsOnly = val.replaceAll(
                                      RegExp(r'\D'),
                                      '',
                                    );
                                    if (digitsOnly.length < 10) {
                                      return 'Enter at least 10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 120,
                              ), // Spacer for bottom bar
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Fixed Bottom Action Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtelierTheme.brandPrimary,
                        disabledBackgroundColor: AtelierTheme.brandPrimary
                            .withOpacity(0.5),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: isSaving ? null : _handleSave,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 18,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AtelierTheme.darkSurface
                                      : AtelierTheme.lightSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing ? 'Update Client' : 'Save Client',
                                  style: AtelierTheme.textFont(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AtelierTheme.lightSurface,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // Duplicate Customer Modal
                if (_duplicateCustomer != null) _buildDuplicateModal(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevron_left, size: 24),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Client' : 'New Client',
              style: AtelierTheme.displayFont(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (!_isEditing)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: _pickContact,
              icon: Icon(
                LucideIcons.user_plus,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              label: Text(
                'Contacts',
                style: AtelierTheme.textFont(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Duplicate Dialog ───────────────────────────────────────────────────────

  Widget _buildDuplicateModal() {
    final dup = _duplicateCustomer!;
    return Container(
      color: Colors.black.withOpacity(0.65),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Client exists',
                style: AtelierTheme.displayFont(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A client with this mobile number already exists: ${dup.name}.',
                style: AtelierTheme.textFont(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
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
                      onPressed: () =>
                          setState(() => _duplicateCustomer = null),
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
                        backgroundColor: AtelierTheme.brandPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final id = dup.id!;
                        setState(() => _duplicateCustomer = null);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailsScreen(customerId: id),
                          ),
                        );
                      },
                      child: Text(
                        'Open Existing',
                        style: AtelierTheme.textFont(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field Helper Widget ──────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AtelierTheme.textFont(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
