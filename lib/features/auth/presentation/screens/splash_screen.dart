import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();


    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
             const DashboardScreen(), //const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1D2D44),
              Color(0xFF3E5C76),
            ],stops: [0.1,0.2]
          ),
          //

          boxShadow: [
            // Dark shadow
            BoxShadow(
              color: Colors.black.withValues(alpha:0.8),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            // Glow effect
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha:0.5),
              blurRadius: 40,
              spreadRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Stack(
                        children: [

                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(-0.6, -0.6),
                                  radius: 0.8,
                                  colors: [
                                    Color(0xFF3E5C76).withValues(alpha:0.2),  //--->change
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/images/xylo.png",
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Save Watts, Safe Wallets',
                                style: GoogleFonts.montserrat(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha:0.95),
                                  //shadows: [
                                  //Shadow(
                                  //color: Color(0xFF3E5C76).withValues(alpha:0.3),
                                  //blurRadius: 8,
                                  //offset: const Offset(0, 0),
                                  //),
                                  //],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                ),
              );
            },
          ),
        ),
      ),
    );
  }}