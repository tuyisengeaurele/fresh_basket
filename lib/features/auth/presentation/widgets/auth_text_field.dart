import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final int maxLines;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
