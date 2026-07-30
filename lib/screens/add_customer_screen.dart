import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../core/theme/atelier_theme.dart';
import '../widgets/tb_snackbar.dart';
import 'customer_details_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  // ── Contact Picker ───────────────────────────────────────────────────────────

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
        _nameCtrl.text = contact.fullName ?? '';
        _mobileCtrl.text = cleanPhone;
      });

      // Trigger field validation so errors clear immediately upon selecting
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
          style: TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Contacts access is permanently denied. Please enable it in system settings.',
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtelierTheme.brandPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save Action ─────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CustomerBloc>().add(
      AddCustomer(
        name: _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerAdded) {
          TbSnackbar.success(context, 'Client created successfully');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CustomerDetailsScreen(customerId: state.customerId),
            ),
          );
        } else if (state is CustomerError) {
          TbSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isSaving = state is CustomerLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('PERSONAL DETAILS'),
                          const SizedBox(height: 16),

                          // Name Field
                          _buildFieldLabel('NAME'),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: _borderInputDecoration(
                              hint: 'e.g. Ananya Sharma',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Mobile Field
                          _buildFieldLabel('PHONE'),
                          TextFormField(
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontFamily: 'Satoshi',
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: _borderInputDecoration(
                              hint: '+91 98765 43210',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone is required';
                              }
                              final digitsOnly = v.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digitsOnly.length < 10) {
                                return 'Enter at least 10 digits';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStickyFooter(isSaving),
              ],
            ),
          ),
        );
      },
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'New Client',
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickContact,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              LucideIcons.user_plus,
              size: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              'Contacts',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  InputDecoration _borderInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Satoshi',
        color: Colors.grey.shade600,
        fontSize: 15,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AtelierTheme.brandPrimary, width: 1.5),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AtelierTheme.darkError),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AtelierTheme.darkError, width: 1.5),
      ),
    );
  }

  Widget _buildStickyFooter(bool isSaving) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AtelierTheme.brandPrimary,
            disabledBackgroundColor: AtelierTheme.brandPrimary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
          ),
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Icon(
                  LucideIcons.check,
                  size: 18,
                  color: AtelierTheme.lightSurface,
                ),
          label: Text(
            isSaving ? 'Saving…' : 'Save Client',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AtelierTheme.lightSurface,
            ),
          ),
        ),
      ),
    );
  }
}
