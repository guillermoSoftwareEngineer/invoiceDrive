import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Usuario canceló

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCred.user;

      if (user != null) {
        final docRef = _db.collection('usuarios').doc(user.uid);

        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          await docRef.set({
            'uid': user.uid,
            'nombre': user.displayName ?? '',
            'correo': user.email ?? '',
            'fotoUrl': user.photoURL ?? '',
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print('❌ Error en login con Google: $e');
      print(e);
      return null;
      return null;
    }
  }
}
