import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file', // Necessário se for fazer backup no Google Drive
    ],
  );

  // Método para realizar o login
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Erro detalhado no login com Google: $error');
      return null;
    }
  }

  // Método para verificar se já existe um usuário conectado anteriormente
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }

  // Método para sair (logout)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}