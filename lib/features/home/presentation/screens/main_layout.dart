import 'package:flutter/material.dart';
import 'package:xyloswitch/features/auth/presentation/screens/dashboard_screen.dart';
import '../widgets/sm_home_bottom_navigation.dart';

class MainLayout extends StatefulWidget {
  final Widget body;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.body,
    required this.currentIndex,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    _currentIndex = widget.currentIndex;
    super.initState();
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);

    // Navigate to DashboardScreen with the selected index
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.body,
      bottomNavigationBar: SmHomeBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
