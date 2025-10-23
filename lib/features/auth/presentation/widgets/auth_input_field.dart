import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFAEAAC5).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFFafa).withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: const Color(0xFFCBC9E6),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFFEAEDF3).withValues(alpha:0.6),
          ),
          prefixIcon: widget.icon != null
              ? Icon(
            widget.icon,
            color: const Color(0xFFFFFafa).withValues(alpha:0.7),
            size: 20,
          )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFFFFFafa).withOpacity(0.7),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
