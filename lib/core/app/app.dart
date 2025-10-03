import 'package:flutter/material.dart';

import 'package:ui_common/ui_common.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../theme/sh_theme.dart';

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'XYLO SWITCH - Smart Home App',
          theme: SHTheme.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}
