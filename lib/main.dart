import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'features/auth/presentation/screens/splash_screens.dart';
import 'package:provider/provider.dart';
import 'features/auth/services/auth_service.dart';

import 'core/theme/sh_theme.dart';
import 'core/theme/sh_colors.dart';

final GlobalKey<MyAppState> appKey = GlobalKey<MyAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService()..checkAuthState(),
      child: MyApp(key: appKey),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}
class MyAppState extends State<MyApp> {
  // --------- ADD THIS: Theme Mode state ---------
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void changeTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SHTheme.light,
          darkTheme: SHTheme.dark,
          themeMode: _themeMode,
          home: child,
        );
      },

      child: const SplashScreens(),
    );
  }
}
