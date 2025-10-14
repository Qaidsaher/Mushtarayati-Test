import 'package:firebase_auth/firebase_auth.dart';
import '../providers/remote/firebase_auth_provider.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  AuthResult({required this.success, this.message, this.user});
}

class AuthRepository {
  final FirebaseAuthProvider _provider = FirebaseAuthProvider();

  Future<AuthResult> login(String email, String password) async {
    try {
      final user = await _provider.signIn(email, password);
      if (user == null) return AuthResult(success: false, message: 'فشل تسجيل الدخول');
      return AuthResult(
        success: true,
        user: UserModel(id: user.uid, email: user.email ?? '', name: user.displayName ?? ''),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  Future<AuthResult> register(String email, String password) async {
    try {
      final user = await _provider.register(email, password);
      if (user == null) return AuthResult(success: false, message: 'فشل إنشاء الحساب');
      // optionally update displayName if payload contains name (handled by controller)
      return AuthResult(
        success: true,
        user: UserModel(id: user.uid, email: user.email ?? '', name: user.displayName ?? ''),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _provider.sendPasswordReset(email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: e.toString());
    }
  }

  Future<void> signOut() async {
    await _provider.signOut();
  }

  Future<void> updateDisplayName(String name) async {
    await _provider.updateDisplayName(name);
  }
}
