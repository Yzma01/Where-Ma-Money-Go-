import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:where_ma_money_go/models/user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ─── Login ───────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _fetchOrCreateUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _authException(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión. Intenta de nuevo.');
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user!;

      // Actualizar displayName en Firebase Auth
      await firebaseUser.updateDisplayName(name.trim());

      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: name.trim(),
        isEmailVerified: false,
        createdAt: DateTime.now(),
      );

      // Guardar datos adicionales en Firestore
      await _users.doc(firebaseUser.uid).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'isEmailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw _authException(e);
    } catch (e) {
      throw Exception('Error al crear la cuenta. Intenta de nuevo.');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión.');
    }
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _authException(e);
    } catch (e) {
      throw Exception('Error al enviar el correo de verificación.');
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      // Forzar recarga para obtener el estado actualizado del servidor
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;

      if (verified) {
        // Sincronizar el estado en Firestore
        final uid = _auth.currentUser!.uid;
        await _users.doc(uid).update({'isEmailVerified': true});
      }

      return verified;
    } catch (e) {
      return false;
    }
  }

  // ─── Get Current User ─────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      await firebaseUser.reload();
      return await _fetchOrCreateUser(firebaseUser);
    } catch (e) {
      return null;
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _authException(e);
    } catch (e) {
      throw Exception('Error al enviar el correo de recuperación.');
    }
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Obtiene el documento del usuario en Firestore.
  /// Si no existe (p. ej. usuario antiguo), lo crea con los datos disponibles.
  Future<UserModel> _fetchOrCreateUser(User firebaseUser) async {
    final doc = await _users.doc(firebaseUser.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: data['name'] as String?,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    } else {
      // Crear documento si no existe
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: DateTime.now(),
      );
      await _users.doc(firebaseUser.uid).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'isEmailVerified': user.isEmailVerified,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return user;
    }
  }

  /// Traduce los códigos de error de Firebase a mensajes legibles.
  Exception _authException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Este correo ya está registrado.',
      'weak-password' =>
        'La contraseña es muy débil. Usa al menos 6 caracteres.',
      'invalid-email' => 'El formato del correo no es válido.',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
      'too-many-requests' =>
        'Demasiados intentos. Espera un momento e intenta de nuevo.',
      'network-request-failed' => 'Error de conexión. Revisa tu internet.',
      'requires-recent-login' =>
        'Necesitas volver a iniciar sesión para esta acción.',
      _ => 'Ocurrió un error. Intenta de nuevo.',
    };
    return Exception(message);
  }
}
