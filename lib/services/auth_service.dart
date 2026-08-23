import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-In must be initialized only once.
      // With google_sign_in 7.x, the singleton may already
      // be initialized during the current app session.
      try {
        await _googleSignIn.initialize();
      } on StateError catch (e) {
        if (!e.toString().contains('init() has already been called')) {
          rethrow;
        }
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      print('GOOGLE ERROR CODE: ${e.code}');
      print('GOOGLE ERROR DESCRIPTION: ${e.description}');
      rethrow;
    } on FirebaseAuthException catch (e) {
      print('FIREBASE ERROR CODE: ${e.code}');
      print('FIREBASE ERROR MESSAGE: ${e.message}');
      rethrow;
    } catch (e) {
      print('OTHER GOOGLE ERROR: $e');
      rethrow;
    }
  }
}
