import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // show splash for at least 900ms
    await Future.delayed(const Duration(milliseconds: 900));

    final box = GetStorage();
    final remember = box.read<bool>('auth_remember') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (remember && user != null) {
      // user remembered and session available
      Get.offAllNamed('/home');
      return;
    }

    // otherwise navigate to login
    Get.offAllNamed('/auth/login');
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer.withOpacity(0.9)])),
          child: Center(
            child: FadeTransition(
              opacity: _anim.drive(CurveTween(curve: Curves.easeInOut)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Hero(tag: 'app-logo', child: Material(color: Colors.transparent, child: CircleAvatar(radius: 56, backgroundColor: Colors.white, child: ClipOval(child: Image.asset('assets/images/logo.png', width: 56, height: 56, fit: BoxFit.cover))))),
                const SizedBox(height: 16),
                Text(Constants.appName, style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('إدارة المبيعات والمخزون', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
