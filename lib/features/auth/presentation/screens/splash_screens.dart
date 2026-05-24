import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xyloswitch/features/auth/services/auth_service.dart';
import 'package:xyloswitch/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/dashboard_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/home_registration_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/smart_room.dart';

class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreens>
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

    // 🔹 Auto-login logic
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkAuthState();
      authService.startUserListener();

      if (!mounted) return;

      Widget nextScreen;
      if (authService.isAuthenticated) {
        // Double check if homeId is actually null or just not fetched yet
        if (authService.homeId == null && !authService.isPendingApproval) {
          debugPrint("Splash: HomeId is null, attempting one final fetch...");
          await authService.fetchUserHome();
        }

        if (authService.isPendingApproval) {
          nextScreen = const PendingApprovalScreen();
        } else if (authService.homeId == null) {
          // If still null after second attempt, then it's likely a new account
          nextScreen = const HomeRegistrationScreen();
        } else {
          nextScreen = authService.isOwner ? const DashboardScreen() : const HomeScreen();
        }
      } else {
        nextScreen = const LoginScreens();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 80),
        ),
      );
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0ABAB5), // Tiffany Blue
              Color(0xFF0095B6), // Bondi Blue
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/xylo.png",
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        'Save Watts, Save Wallets',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(242),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
