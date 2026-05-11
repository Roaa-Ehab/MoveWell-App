import 'package:flutter/material.dart';
import 'package:movewell/core/features/auth/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';
import 'package:movewell/core/theme/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MoveWellApp(),
    ),
  );
}

class MoveWellApp extends StatelessWidget {
  const MoveWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoveWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
