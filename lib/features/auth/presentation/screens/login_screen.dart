
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import '../widgets/auth_input_field.dart';
import '../widgets/gradient_button.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';


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
  bool _isGoogleLoading = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    GoogleSignIn.instance.initialize(
      serverClientId: '109754991498-fq5baimbtp0uicau7q4l0hfb7frqosv1.apps.googleusercontent.com',
    );
  }
  Future<bool> login() async {
    final user = await GoogleSignIn.instance.authenticate();
    if (user == null) {
      // user cancelled the sign-in
      return false;
    }
    final userAuth = await user.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: userAuth.idToken,

    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    return FirebaseAuth.instance.currentUser != null;
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
            colors: [Color(0xFF1D2D44),
              Color(0xFF3E5C76)],
            stops: [ 0.5,1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                EdgeInsets.only(top: 60, left: basePadding, right: basePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        "assets/images/xylo.png",
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'WELCOME',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,  // or any color matching your background
                        letterSpacing: 2,     // gives elegant spacing
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.6), // transparent glass
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.65), // frosted border
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha:0.09),
                              blurRadius: 15,
                              offset: const Offset(0, -2),
                            ),
                          ],
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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
                                  borderColor: const Color(0xFF9B59B6),
                                  height: 46,
                                ),
                                const SizedBox(height: 10),

                                GradientButton(
                                  text: _isGoogleLoading
                                      ? 'Signing in...'
                                      : 'Sign in with Google',
                                  icon: _isGoogleLoading
                                      ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const FaIcon(
                                    FontAwesomeIcons.google,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  onPressed: _isGoogleLoading
                                      ? null
                                      : () async {
                                    setState(() => _isGoogleLoading = true);
                                    bool isLogged = await login();
                                    setState(() => _isGoogleLoading = false);

                                    if (isLogged) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                            const DashboardScreen()),
                                      );
                                    }
                                  },
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9B59B6), Color(0xFF20B2AA)],
                                  ),
                                  borderColor: const Color(0xFF9B59B6),
                                  height: 46,
                                ),

                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SignupScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Create a new Account',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF9B59B6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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


