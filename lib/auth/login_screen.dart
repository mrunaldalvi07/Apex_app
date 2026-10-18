import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/fcm_service.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // APEX BLUE THEME
  // ============================================================

  static const Color primaryNavy = Color(0xFF073B6F);
  static const Color darkNavy = Color(0xFF052B52);
  static const Color primaryBlue = Color(0xFF0B6EAA);
  static const Color cyan = Color(0xFF18A8C8);
  static const Color lightBlue = Color(0xFFEAF6FB);
  static const Color background = Color(0xFFF5F8FC);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool loading = false;
  bool googleLoading = false;
  bool obscurePassword = true;

  bool get isLoading => loading || googleLoading;

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<void> login() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final email = emailController.text.trim();

      // Do not trim passwords.
      final password = passwordController.text;

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (!mounted) return;

      // AuthWrapper listens to authStateChanges and shows the correct dashboard.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        "Unable to login. Please check your connection and try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> signInWithGoogle() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      googleLoading = true;
    });

      final userCredential = await AuthService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential == null) {
        _showMessage(
          "Google Sign-In was cancelled or failed.",
        );
        return;
      }

      // AuthWrapper listens to authStateChanges and shows the correct dashboard.
    } catch (e) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleRouter(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(e),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        "Google Sign-In failed. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() {
          googleLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FIREBASE ERROR HANDLING
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return "Please enter a valid email address.";

      case 'user-not-found':
        return "No account found with this email.";

      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";

      case 'user-disabled':
        return "This account has been disabled.";

      case 'too-many-requests':
        return "Too many attempts. Please try again later.";

      case 'network-request-failed':
        return "Network error. Please check your connection.";

      case 'operation-not-allowed':
        return "This login method is not enabled.";

      case 'google-id-token-missing':
        return "Google authentication could not be completed.";

      default:
        return e.message ?? "Login failed. Please try again.";
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: primaryNavy,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? "";

    if (email.isEmpty) {
      return "Email is required";
    }

    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email address";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? "";

    if (password.isEmpty) {
      return "Password is required";
    }

    if (password.length < 6) {
      return "Password must contain at least 6 characters";
    }

    return null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("APEX Login")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading || googleLoading || resetLoading
                    ? null
                    : resetPassword,
                child: Text(
                  resetLoading ? 'Sending reset link...' : 'Forgot password?',
                ),
              ),
            ),

          const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading || googleLoading || resetLoading
                    ? null
                    : login,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("LOGIN"),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR"),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: loading || googleLoading || resetLoading
                    ? null
                    : signInWithGoogle,
                icon: googleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata),
                label: Text(
                  googleLoading ? "Signing in..." : "Continue with Google",
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: loading || googleLoading || resetLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text("Create Account"),
            ),
          ),
        ],
      ),
    );
  }
}