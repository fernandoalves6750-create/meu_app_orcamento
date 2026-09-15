import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  // Método para realizar o login com tratamento refinado
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      // Força o popup de seleção de conta limpo
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } on PlatformException catch (e) {
      print('PlatformException no login com Google: ${e.code} - ${e.message}');
      return null;
    } catch (error) {
      print('Erro genérico no login com Google: $error');
      return null;
    }
  }

  // Método para verificar se já existe um usuário conectado
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('Erro no signInSilently: $e');
      return null;
    }
  }

  // Método para sair (logout)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Erro ao deslogar: $e');
    }
  }
}