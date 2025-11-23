import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_pet/models/user_model.dart';
import 'package:match_pet/services/firebase_database_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static UserModel? _currentUser;
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static UserModel? get currentUser => _currentUser;

  static Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    
    // Verificar se há usuário salvo localmente
    final userId = _prefs?.getString('user_id');
    if (userId != null) {
      // Recriar usuário baseado no ID salvo
      if (userId == 'user_test_001') {
        _currentUser = UserModel(
          id: 'user_test_001',
          name: 'João Silva',
          email: 'usuario@teste.com',
          password: '',
          type: UserType.user,
          phone: '(11) 99999-0001',
          address: 'Rua das Flores, 123 - São Paulo, SP',
          matches: [],
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          updatedAt: DateTime.now(),
        );
        return true;
      } else if (userId == 'ong_test_001') {
        _currentUser = UserModel(
          id: 'ong_test_001',
          name: 'ONG Proteção Animal',
          email: 'ong@teste.com',
          password: '',
          type: UserType.ong,
          phone: '(11) 99999-0002',
          address: 'Av. dos Animais, 456 - São Paulo, SP',
          matches: [],
          createdAt: DateTime.now().subtract(Duration(days: 60)),
          updatedAt: DateTime.now(),
        );
        return true;
      }
    }
    
    // TODO: Implementar Firebase quando configurado
    // final user = _auth.currentUser;
    // if (user != null) {
    //   return _currentUser != null;
    // }
    
    return false;
  }

  static Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // ===== CREDENCIAIS DE TESTE (HARDCODED) =====
      // Para teste - usuário comum
      if (email.trim() == 'usuario@teste.com' && password == '123456') {
        _currentUser = UserModel(
          id: 'user_test_001',
          name: 'João Silva',
          email: 'usuario@teste.com',
          password: '', // Não armazenamos senha
          type: UserType.user,
          phone: '(11) 99999-0001',
          address: 'Rua das Flores, 123 - São Paulo, SP',
          matches: [],
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          updatedAt: DateTime.now(),
        );
        await _prefs?.setString('user_id', _currentUser!.id ?? '');
        return _currentUser;
      }
      
      // Para teste - ONG
      if (email.trim() == 'ong@teste.com' && password == '123456') {
        _currentUser = UserModel(
          id: 'ong_test_001',
          name: 'ONG Proteção Animal',
          email: 'ong@teste.com',
          password: '', // Não armazenamos senha
          type: UserType.ong,
          phone: '(11) 99999-0002',
          address: 'Av. dos Animais, 456 - São Paulo, SP',
          matches: [],
          createdAt: DateTime.now().subtract(Duration(days: 60)),
          updatedAt: DateTime.now(),
        );
        await _prefs?.setString('user_id', _currentUser!.id ?? '');
        return _currentUser;
      }
      // ===== FIM CREDENCIAIS DE TESTE =====

      // Tentar login real com Firebase
      try {
        User? firebaseUser;
        String? firebaseUserId;
        
        try {
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          // Aguardar um pouco para garantir que o login foi processado
          await Future.delayed(const Duration(milliseconds: 300));
          // Usar currentUser em vez de credential.user para evitar erro de casting
          firebaseUser = _auth.currentUser;
          firebaseUserId = firebaseUser?.uid;
        } catch (e) {
          // Se houver erro de casting mas o login foi bem-sucedido, tentar recuperar do currentUser
          if (e.toString().contains('PigeonUserDetails') || 
              e.toString().contains('type cast') ||
              e.toString().contains('List<Object?>')) {
            print('Erro de casting no login, tentando recuperar usuário atual: $e');
            await Future.delayed(const Duration(milliseconds: 500));
            firebaseUser = _auth.currentUser;
            firebaseUserId = firebaseUser?.uid;
            
            // Se conseguiu recuperar o usuário, continuar normalmente
            if (firebaseUser != null && firebaseUserId != null) {
              print('Usuário recuperado com sucesso após erro de casting no login: $firebaseUserId');
            } else {
              // Se não conseguiu recuperar, verificar se é um erro de autenticação conhecido
              if (e is FirebaseAuthException) {
                rethrow;
              } else {
                throw Exception('Erro ao fazer login. Tente novamente.');
              }
            }
          } else {
            // Se não for erro de casting, relançar o erro original
            rethrow;
          }
        }

        if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
          // Buscar dados do usuário no Firestore
          _currentUser = await FirebaseDatabaseService.getUserByEmail(email);
          if (_currentUser != null) {
            await _prefs?.setString('user_id', _currentUser!.id ?? firebaseUserId);
            return _currentUser;
          } else {
            // Se o usuário não existe no Firestore, pode ser que foi criado apenas no Auth
            // Criar um perfil básico no Firestore
            print('Usuário não encontrado no Firestore, criando perfil básico...');
            final basicUser = UserModel(
              id: firebaseUserId,
              name: firebaseUser?.displayName ?? 'Usuário',
              email: email,
              password: '',
              type: UserType.user,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            final success = await FirebaseDatabaseService.createUserWithId(firebaseUserId, basicUser);
            if (success) {
              _currentUser = basicUser;
              await _prefs?.setString('user_id', firebaseUserId);
              return basicUser;
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        // Tratar erros específicos do Firebase Auth
        print('FirebaseAuthException no login: ${e.code} - ${e.message}');
        // Não relançar, deixar o hardcode como fallback se necessário
      } catch (e) {
        // Verificar se o erro é de casting mas o login foi bem-sucedido
        final errorString = e.toString();
        if (errorString.contains('PigeonUserDetails') || 
            errorString.contains('type cast') ||
            errorString.contains('List<Object?>')) {
          print('Erro de casting no login, verificando se login foi bem-sucedido: $e');
          await Future.delayed(const Duration(milliseconds: 500));
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid.isNotEmpty) {
            print('Login foi bem-sucedido apesar do erro de casting. UID: ${currentUser.uid}');
            // Buscar dados do usuário no Firestore
            _currentUser = await FirebaseDatabaseService.getUserByEmail(email);
            if (_currentUser != null) {
              await _prefs?.setString('user_id', _currentUser!.id ?? currentUser.uid);
              return _currentUser;
            }
          }
        }
        print('Erro no Firebase: $e');
        // Se Firebase falhar, usar hardcode como fallback
      }
      
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  static Future<UserModel?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserType type, {
    String? phone,
    String? address,
  }) async {
    try {
      // Criar usuário no Firebase Auth
      User? firebaseUser;
      String? firebaseUserId;
      
      try {
        // Criar usuário no Firebase Auth
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        // Aguardar um pouco para garantir que o usuário foi criado
        await Future.delayed(const Duration(milliseconds: 300));
        // Usar currentUser em vez de credential.user para evitar erro de casting
        firebaseUser = _auth.currentUser;
        firebaseUserId = firebaseUser?.uid;
      } catch (e) {
        // Se houver erro de casting mas o usuário foi criado, tentar recuperar do currentUser
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('type cast')) {
          print('Erro de casting detectado, tentando recuperar usuário atual: $e');
          await Future.delayed(const Duration(milliseconds: 500));
          firebaseUser = _auth.currentUser;
          firebaseUserId = firebaseUser?.uid;
          
          // Se conseguiu recuperar o usuário, continuar normalmente
          if (firebaseUser != null && firebaseUserId != null) {
            print('Usuário recuperado com sucesso após erro de casting: $firebaseUserId');
          } else {
            // Se não conseguiu recuperar, verificar se é um erro de autenticação conhecido
            if (e is FirebaseAuthException) {
              rethrow;
            } else {
              throw Exception('Erro ao criar usuário. Tente novamente.');
            }
          }
        } else {
          // Se não for erro de casting, relançar o erro original
          rethrow;
        }
      }

      if (firebaseUserId != null) {
        // Criar modelo de usuário com o ID do Firebase Auth
        final user = UserModel(
          id: firebaseUserId, // Usar o UID do Firebase Auth como ID
          name: name,
          email: email.trim(),
          password: password, // Em produção, isso deve ser hasheado
          type: type,
          phone: phone,
          address: address,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Criar usuário no Firestore usando o UID do Firebase Auth como ID do documento
        final success = await FirebaseDatabaseService.createUserWithId(firebaseUserId, user);
        
        if (success) {
          _currentUser = user;
          await _prefs?.setString('user_id', firebaseUserId);
          return user;
        } else {
          // Se falhar ao criar no Firestore, deletar do Firebase Auth
          try {
            await firebaseUser?.delete();
          } catch (deleteError) {
            print('Erro ao deletar usuário do Firebase Auth: $deleteError');
          }
          throw Exception('Erro ao criar perfil do usuário. Tente novamente.');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Tratar erros específicos do Firebase Auth
      String errorMessage = 'Erro ao criar conta';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'A senha é muito fraca. Use uma senha mais forte (mínimo 6 caracteres).';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este email já está em uso. Tente fazer login ou use outro email.';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido. Verifique o formato do email.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operação não permitida. Entre em contato com o suporte.';
          break;
        case 'network-request-failed':
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
          break;
        default:
          errorMessage = 'Erro ao criar conta: ${e.message ?? e.code}';
      }
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(errorMessage);
    } catch (e) {
      // Verificar se o erro é de casting mas o usuário foi criado
      final errorString = e.toString();
      if (errorString.contains('PigeonUserDetails') || 
          errorString.contains('type cast') ||
          errorString.contains('List<Object?>')) {
        print('Erro de casting detectado, verificando se usuário foi criado: $e');
        // Aguardar um pouco e verificar se o usuário foi criado
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid.isNotEmpty) {
          print('Usuário foi criado apesar do erro de casting. UID: ${currentUser.uid}');
          // Continuar com a criação do perfil no Firestore
          final firebaseUserId = currentUser.uid;
          final user = UserModel(
            id: firebaseUserId,
            name: name,
            email: email.trim(),
            password: password,
            type: type,
            phone: phone,
            address: address,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final success = await FirebaseDatabaseService.createUserWithId(firebaseUserId, user);
          
          if (success) {
            _currentUser = user;
            await _prefs?.setString('user_id', firebaseUserId);
            return user;
          } else {
            // Se falhar ao criar no Firestore, tentar deletar do Firebase Auth
            try {
              await currentUser.delete();
            } catch (deleteError) {
              print('Erro ao deletar usuário do Firebase Auth: $deleteError');
            }
            throw Exception('Erro ao criar perfil do usuário. Tente novamente.');
          }
        }
      }
      // Capturar outros tipos de erro
      print('Erro ao criar conta: $errorString');
      
      // Tratar erros específicos conhecidos
      if (errorString.contains('email-already-in-use') || 
          errorString.contains('already in use')) {
        throw Exception('Este email já está em uso. Tente fazer login ou use outro email.');
      } else if (errorString.contains('weak-password') || 
                 errorString.contains('password')) {
        throw Exception('A senha é muito fraca. Use uma senha mais forte (mínimo 6 caracteres).');
      } else if (errorString.contains('invalid-email')) {
        throw Exception('Email inválido. Verifique o formato do email.');
      } else if (errorString.contains('network') || 
                 errorString.contains('connection')) {
        throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
      } else {
        throw Exception('Erro ao criar conta. Tente novamente mais tarde.');
      }
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    await _prefs?.remove('user_id');
  }

  static Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Erro ao enviar email de reset: $e');
      return false;
    }
  }

  static Future<UserModel?> getCurrentUserFromStorage() async {
    final userIdString = _prefs?.getString('user_id');
    if (userIdString != null) {
      final userId = userIdString;
      _currentUser = await FirebaseDatabaseService.getUserById(userId);
      return _currentUser;
    }
    return null;
  }
}
