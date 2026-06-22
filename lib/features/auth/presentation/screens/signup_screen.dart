import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../widgets/auth_input_field.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.signup(
          fullName: _fullNameController.text,
          email: _emailController.text,
          contact: _contactController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (success && mounted) {
          // After signup, log out to ensure the user can log in manually
          await authService.logout();
          
          if (!mounted) return;
          
          // Notify the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );

          // Go back to login page
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signup failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Privacy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Text(
                  "Let's Register\nYour Account",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Form Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0ABAB5), // Tiffany Blue
                        Color(0xFF0095B6), // Bondi Blue
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AuthInputField(
                            controller: _fullNameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline,
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            hintColor: Colors.white,
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                          ),
                          const SizedBox(height: 10),
                          AuthInputField(
                            controller: _emailController,
                            hintText: 'Email Address',
                            icon: Icons.email_outlined,
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            hintColor: Colors.white,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (value.length < 5) return 'Email must be at least 5 characters';
                              if (value.length > 254) return 'Email cannot exceed 254 characters';
                              if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthInputField(
                            controller: _contactController,
                            hintText: 'Contact',
                            icon: Icons.phone_outlined,
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            hintColor: Colors.white,
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your contact number' : null,
                          ),
                          const SizedBox(height: 10),
                          AuthInputField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            hintColor: Colors.white,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              if (value.length > 128) return 'Password cannot exceed 128 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AuthInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            hintColor: Colors.white,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Theme(
                                  data: ThemeData(
                                    unselectedWidgetColor: const Color(0xFF005B6B),
                                  ),
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                                    activeColor: Colors.transparent,
                                    checkColor: const Color(0xFF0ABAB5),
                                    side: const BorderSide(color: Color(0xFF005B6B), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'I agree to the ',
                                      style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF005B6B)),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Privacy',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurpleAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 260,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0ABAB5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Sign Up',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white70),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}