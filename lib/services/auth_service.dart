import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool _googleInitialized = false;

  static Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      print("GOOGLE ERROR CODE: ${e.code}");
      print("GOOGLE ERROR DESCRIPTION: ${e.description}");
      print("GOOGLE ERROR: $e");
      rethrow;
    } on FirebaseAuthException catch (e) {
      print("FIREBASE ERROR CODE: ${e.code}");
      print("FIREBASE ERROR MESSAGE: ${e.message}");
      rethrow;
    } catch (e) {
      print("OTHER GOOGLE ERROR: $e");
      rethrow;
    }
  }
}
