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

      // FCM must never block login.
      try {
        await FCMService().initialize().timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {}

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

    try {
      final userCredential =
          await AuthService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential == null) {
        _showMessage(
          "Google Sign-In was cancelled or failed.",
        );
        return;
      }

      // FCM must never block Google login.
      try {
        await FCMService().initialize().timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {}

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
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: darkNavy,

        centerTitle: true,

        title: const Text(
          "APEX",
          style: TextStyle(
            color: primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },

          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              30,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  // ==================================================
                  // BRAND HEADER
                  // ==================================================

                  _buildBrandHeader(),

                  const SizedBox(height: 20),

                  // ==================================================
                  // LOGIN CARD
                  // ==================================================

                  _buildLoginCard(),

                  const SizedBox(height: 20),

                  // ==================================================
                  // GOOGLE LOGIN
                  // ==================================================

                  _buildGoogleButton(),

                  const SizedBox(height: 18),

                  // ==================================================
                  // CREATE ACCOUNT
                  // ==================================================

                  _buildCreateAccount(),

                  const SizedBox(height: 18),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  const Text(
                    "Academic Platform for Excellence",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  // ============================================================
  // BRAND HEADER
  // ============================================================

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            darkNavy,
            primaryNavy,
            primaryBlue,
            cyan,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        children: [
          // Logo
          Container(
            width: 78,
            height: 78,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),

              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),

            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 43,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            "Welcome to APEX",
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "Sign in to continue to your dashboard",
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE1E8F0),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10073B6F),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          const Row(
            children: [
              Icon(
                Icons.login_rounded,
                color: primaryBlue,
                size: 21,
              ),

              SizedBox(width: 8),

              Text(
                "Login",
                style: TextStyle(
                  color: darkNavy,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // EMAIL
          _buildTextField(
            controller: emailController,
            label: "Email",
            hint: "Enter your email",
            icon: Icons.email_outlined,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            validator: _validateEmail,
          ),

          const SizedBox(height: 14),

          // PASSWORD
          _buildTextField(
            controller: passwordController,
            label: "Password",
            hint: "Enter your password",
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction:
                TextInputAction.done,
            validator: _validatePassword,

            suffix: IconButton(
              tooltip: obscurePassword
                  ? "Show password"
                  : "Hide password",

              onPressed: () {
                setState(() {
                  obscurePassword =
                      !obscurePassword;
                });
              },

              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,

                color: primaryBlue,
              ),
            ),

            onSubmitted: (_) {
              if (!isLoading) {
                login();
              }
            },
          ),

          const SizedBox(height: 20),

          // LOGIN BUTTON
          SizedBox(
            height: 52,

            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    darkNavy,
                    primaryNavy,
                    primaryBlue,
                  ],

                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),

                borderRadius:
                    BorderRadius.circular(14),

                boxShadow: [
                  BoxShadow(
                    color:
                        primaryNavy.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: ElevatedButton(
                onPressed:
                    isLoading ? null : login,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.transparent,

                  disabledBackgroundColor:
                      Colors.transparent,

                  shadowColor:
                      Colors.transparent,

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,

    TextInputType? keyboardType,
    TextInputAction? textInputAction,

    bool obscureText = false,

    Widget? suffix,

    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,

      textInputAction: textInputAction,

      obscureText: obscureText,

      validator: validator,

      onFieldSubmitted: onSubmitted,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle: const TextStyle(
          color: darkNavy,
          fontSize: 13,
        ),

        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 13,
        ),

        prefixIcon: Icon(
          icon,
          color: primaryBlue,
          size: 21,
        ),

        suffixIcon: suffix,

        filled: true,

        fillColor: const Color(0xFFF9FBFD),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),

          borderSide: const BorderSide(
            color: Color(0xFFE0E7EF),
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),

          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.6,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),

          borderSide: const BorderSide(
            color: primaryBlue,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),

          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GOOGLE BUTTON
  // ============================================================

  Widget _buildGoogleButton() {
    return Container(
      height: 52,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            lightBlue,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: primaryBlue.withOpacity(0.25),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x08073B6F),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: OutlinedButton(
        onPressed:
            isLoading ? null : signInWithGoogle,

        style: OutlinedButton.styleFrom(
          backgroundColor:
              Colors.transparent,

          side: BorderSide.none,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            googleLoading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  )
                : Container(
                    width: 26,
                    height: 26,

                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          primaryNavy,
                          cyan,
                        ],
                      ),

                      borderRadius:
                          BorderRadius.circular(7),
                    ),

                    child: const Center(
                      child: Text(
                        "G",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(width: 10),

            Text(
              googleLoading
                  ? "Signing in..."
                  : "Continue with Google",

              style: const TextStyle(
                color: darkNavy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Widget _buildCreateAccount() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: lightBlue,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: cyan.withOpacity(0.20),
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Text(
            "Don't have an account?",
            style: TextStyle(
              color: darkNavy,
              fontSize: 13,
            ),
          ),

          TextButton(
            onPressed:
                isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RegisterScreen(),
                          ),
                        );
                      },

            style: TextButton.styleFrom(
              foregroundColor: primaryBlue,
            ),

            child: const Text(
              "Create Account",
              style: TextStyle(
                color: primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}