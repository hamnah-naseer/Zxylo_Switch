import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/gradient_button.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'home_registration_screen.dart';
import 'smart_room.dart';
import 'home_registration_screen.dart';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key});

  @override
  State<LoginScreens> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreens> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      if (error == null) {
        if (authService.homeId == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeRegistrationScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => authService.isOwner ? const DashboardScreen() : const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 60),
          // Logo Section
          Center(
            child: Image.asset(
              "assets/images/xylo.png",
              height: 260,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'WELCOME',
            style: GoogleFonts.montserrat(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),

          
          // Gradient Form Section
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
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthInputField(
                        controller: _emailController,
                        hintText: 'Email or Phone',
                        icon: Icons.person,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        hintColor: Colors.white70,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email or phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AuthInputField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white,
                        iconColor: Colors.white,
                        hintColor: Colors.white70,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      GradientButton(
                        text: _isLoading ? 'Logging in...' : 'Login',
                        onPressed: _isLoading ? null : _handleLogin,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0ABAB5),
                            Color(0xFF0095B6),
                          ],
                        ),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        height: 46,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      GradientButton(
                        text: _isGoogleLoading ? 'Signing in...' : 'Sign in with Google',
                        icon: _isGoogleLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
                        onPressed: _isGoogleLoading ? null : () async {
                          setState(() => _isGoogleLoading = true);
                          try {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            final user = await authService.signInWithGoogle();
                            
                            if (!mounted) return;
                            setState(() => _isGoogleLoading = false);
                            
                            if (user != null) {
                              if (authService.homeId == null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomeRegistrationScreen()),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => authService.isOwner ? const DashboardScreen() : const HomeScreen()),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isGoogleLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Google Sign-In failed: $e")),
                              );
                            }
                          }
                        },
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0ABAB5),
                            Color(0xFF0095B6),
                          ],
                        ),
                        borderColor: Colors.white.withValues(alpha: 0.2),
                        height: 46,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          'Create a new Account',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }
}
