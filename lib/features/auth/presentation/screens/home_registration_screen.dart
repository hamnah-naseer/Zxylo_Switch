import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'pending_approval_screen.dart';
import 'sign_in_screen.dart';

class HomeRegistrationScreen extends StatefulWidget {
  const HomeRegistrationScreen({super.key});

  @override
  State<HomeRegistrationScreen> createState() => _HomeRegistrationScreenState();
}

class _HomeRegistrationScreenState extends State<HomeRegistrationScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isCreating = true; // Toggle between Create and Join

  Future<void> _handleAction() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    String? error;
    if (_isCreating) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        error = "Please enter a home name";
      } else if (name.length > 50) {
        error = "Home name cannot exceed 50 characters";
      } else {
        error = await authService.createHome(name);
      }
    } else {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        error = "Please enter a home code";
      } else if (code.length != 6) {
        error = "Home code must be exactly 6 characters";
      } else {
        error = await authService.joinHome(code);
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => authService.isPendingApproval
              ? const PendingApprovalScreen()
              : const DashboardScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0ABAB5), // Tiffany Blue
                  Color(0xFF0095B6), // Bondi Blue
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () async {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreens()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isCreating ? 'Create Your Home' : 'Join a Home',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreating 
                      ? 'Establish a new smart home environment' 
                      : 'Enter the 6-digit code shared by your family',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_isCreating)
                          _buildInputField(
                            controller: _nameController,
                            label: 'Home Name',
                            hint: 'e.g. My Smart Villa',
                            icon: Icons.home_outlined,
                          )
                        else
                          _buildInputField(
                            controller: _codeController,
                            label: 'Home Code',
                            hint: '6-digit code',
                            icon: Icons.vpn_key_outlined,
                            maxLength: 6,
                          ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0095B6).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isLoading ? null : _handleAction,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      _isCreating ? 'CREATE' : 'JOIN',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => setState(() => _isCreating = !_isCreating),
                    child: Text(
                      _isCreating ? 'Already have a code? Join Home' : 'Want to create a new home?',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0095B6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF1A1C1E),
            letterSpacing: maxLength != null ? 4 : 0,
            fontWeight: maxLength != null ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
              color: const Color(0xFFAFBBC9), 
              fontSize: 14,
              letterSpacing: 0,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF0095B6), size: 22),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0095B6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

RoundedRectangleBorder roundedRectangleCircular(double radius) {
  return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}
