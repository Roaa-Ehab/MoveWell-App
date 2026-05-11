import 'package:flutter/material.dart';
import '../theme/colors.dart';

class InputField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? prefixText;
  final bool readOnly;
  final VoidCallback? onTap;

  const InputField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.prefixText,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixText: widget.prefixText,
        prefixStyle: const TextStyle(
          color: AppColors.textPrimary, fontSize: 14),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                  color: AppColors.textMuted, size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
