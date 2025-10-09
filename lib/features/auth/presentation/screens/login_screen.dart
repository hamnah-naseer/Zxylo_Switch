import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/gradient_button.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false; // 👈 Google login loading

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
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
    }
  }

  // 🧠 Google Sign-In Method
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isGoogleLoading = true;
      });

      final googleSignIn = GoogleSignIn(
        scopes: <String>['email'],
      );

      final googleUser = await googleSignIn.signInSilently() ?? await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallHeight = screenSize.height < 700;
    final double basePadding = 16;
    final double topSpacing = 8;
    final double switchFontSize = isSmallHeight ? 16 : 18;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFF20B2AA),
              Color(0xFF483D8B),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// 🔹 Top Section (Logo + Welcome)
              Padding(
                padding:
                EdgeInsets.symmetric(horizontal: basePadding, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        "assets/images/Xylo.jpeg",
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SWITCH',
                      style: GoogleFonts.montserrat(
                        fontSize: switchFontSize,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: topSpacing),
                    Text(
                      'WELCOME',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              /// 🔹 Bottom Section (Form)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(basePadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AuthInputField(
                            controller: _emailController,
                            hintText: 'Email or Phone',
                            icon: Icons.person,
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9B59B6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GradientButton(
                            text: _isLoading ? 'Logging in...' : 'Login',
                            onPressed: _isLoading ? null : _handleLogin,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B59B6), Color(0xFF20B2AA)],
                            ),
                            height: 46,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: Container(
                                      height: 1, color: Colors.grey[300])),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Container(
                                      height: 1, color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GradientButton(
                            text: 'Create an account',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2ECC71), Color(0xFF3498DB)],
                            ),
                            textColor: const Color(0xFF483D8B),
                            borderColor: const Color(0xFF9B59B6),
                            height: 46,
                          ),
                          const SizedBox(height: 15),

                          // 🟡 Google Sign-In Button
                          ElevatedButton.icon(
                            onPressed: _isGoogleLoading
                                ? null
                                : _handleGoogleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                                : Image.asset(
                              'assets/images/google_logo.png', // 👈 add in assets
                              height: 24,
                            ),
                            label: Text(
                              _isGoogleLoading
                                  ? 'Signing in...'
                                  : 'Sign in with Google',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              minimumSize: const Size(double.infinity, 46),
                            ),
                          ),
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
