import 'dart:async';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../auth/role_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController contentController;

  late Animation<double> logoScale;
  late Animation<double> logoFade;
  late Animation<Offset> contentSlide;
  late Animation<double> contentFade;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    logoScale = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOutBack,
    );

    logoFade = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeIn,
    );

    contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    contentFade = CurvedAnimation(
      parent: contentController,
      curve: Curves.easeIn,
    );

    startIntro();
  }

  Future<void> startIntro() async {
    await logoController.forward();

    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    await contentController.forward();

    await Future.delayed(
      const Duration(milliseconds: 2200),
    );

    if (!mounted) return;

    final nextScreen = FirebaseAuth.instance.currentUser == null
        ? const LoginScreen()
        : const RoleRouter();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    logoController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkNavy = Color(0xFF052B52);
    const primaryBlue = Color(0xFF0B6EAA);
    const cyan = Color(0xFF18A8C8);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkNavy,
              primaryBlue,
              cyan,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: logoScale,
                    child: FadeTransition(
                      opacity: logoFade,
                      child: Container(
                        width: 145,
                        height: 145,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/apex_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.school_rounded,
                                size: 75,
                                color: primaryBlue,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SlideTransition(
                    position: contentSlide,
                    child: FadeTransition(
                      opacity: contentFade,
                      child: Column(
                        children: [
                          const Text(
                            'APEX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                            ),
                          ),

                          const SizedBox(height: 30),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Vedanti Borade',
                                  style: memberStyle,
                                ),
                                Text(
                                  'Vaishnavi Desale',
                                  style: memberStyle,
                                ),
                                Text(
                                  'Mrunal Dalvi',
                                  style: memberStyle,
                                ),
                                Text(
                                  'Yashshree Nemade',
                                  style: memberStyle,
                                ),

                                SizedBox(height: 20),

                                Divider(
                                  color: Colors.white24,
                                ),

                                SizedBox(height: 14),

                                Text(
                                  'GUIDED BY',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),

                                SizedBox(height: 7),

                                Text(
                                  'Dr. Aggrawal Mam',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(height: 20),

                                Text(
                                  'Government Polytechnic, Nashik',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(height: 7),

                                Text(
                                  'Academic Year 2026–27',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const memberStyle = TextStyle(
  color: Colors.white,
  fontSize: 15,
  height: 1.55,
  fontWeight: FontWeight.w600,
);