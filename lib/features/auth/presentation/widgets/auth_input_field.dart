import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? hintColor;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.hintColor,
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
        color: widget.backgroundColor ?? const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(30),
        border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: 1.5) : null,
        boxShadow: widget.backgroundColor != null ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: widget.textColor ?? const Color(0xFF1A1C1E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: widget.hintColor ?? const Color(0xFFAFBBC9),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: widget.iconColor ?? const Color(0xFF0095B6),
                  size: 22,
                )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: widget.hintColor ?? const Color(0xFFAFBBC9),
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
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false, // Ensure the input field itself does not paint a background
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
