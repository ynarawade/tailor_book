import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../core/theme/atelier_theme.dart';
import '../models/customer.dart';
import '../widgets/tb_snackbar.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _mobileCtrl = TextEditingController(text: widget.customer.mobileNumber);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CustomerBloc>().add(
      UpdateCustomer(
        customerId: widget.customer.id!,
        name: _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerUpdated) {
          TbSnackbar.success(context, 'Client profile updated');
          Navigator.pop(context, true);
        } else if (state is CustomerError) {
          setState(() => _isSaving = false);
          TbSnackbar.error(context, state.message);
        }
      },
      child: Scaffold(
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

                        // Phone Field
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
                            if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
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
              _buildStickyFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

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
              'Edit Client',
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 26,
                fontWeight: FontWeight.w600,
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

  Widget _buildStickyFooter() {
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
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AtelierTheme.brandPrimary,
            disabledBackgroundColor: AtelierTheme.brandPrimary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
          ),
          icon: _isSaving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AtelierTheme.darkSurface
                        : AtelierTheme.lightSurface,
                  ),
                )
              : Icon(
                  LucideIcons.check,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AtelierTheme.darkSurface
                      : AtelierTheme.lightSurface,
                ),
          label: Text(
            _isSaving ? 'Updating…' : 'Save Changes',
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
