import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_book/core/theme/app_colors.dart';
import 'package:tailor_book/core/theme/app_txt_styles.dart';

class TbInputField extends StatelessWidget {
  const TbInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      autofocus: autofocus,
      style: AppTextStyles.bodyLg(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMd(),
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd(color: AppColors.muted),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.muted)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
