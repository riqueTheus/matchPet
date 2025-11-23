import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match_pet/models/user_model.dart';
import 'package:match_pet/services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        state = AsyncValue.data(AuthService.currentUser);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        state = AsyncValue.data(user);
        return true;
      } else {
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserType type,
    String? phone,
    String? address,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthService.createUserWithEmailAndPassword(
        email,
        password,
        name,
        type,
        phone: phone,
        address: address,
      );
      if (user != null) {
        state = AsyncValue.data(user);
        return true;
      } else {
        state = AsyncValue.error('Erro ao criar conta. Tente novamente.', StackTrace.current);
        return false;
      }
    } catch (e) {
      // Extrair mensagem de erro de forma mais robusta
      String errorMessage = 'Erro ao criar conta. Tente novamente.';
      
      if (e is Exception) {
        final errorString = e.toString();
        // Remover "Exception: " se presente
        errorMessage = errorString.replaceFirst(RegExp(r'^Exception:\s*'), '');
        // Se ainda estiver vazio ou muito genérico, usar mensagem padrão
        if (errorMessage.isEmpty || errorMessage == 'null') {
          errorMessage = 'Erro ao criar conta. Tente novamente.';
        }
      } else {
        errorMessage = e.toString();
      }
      
      state = AsyncValue.error(errorMessage, StackTrace.current);
      return false;
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<bool> resetPassword(String email) async {
    return await AuthService.resetPassword(email);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

