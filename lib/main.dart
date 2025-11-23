import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:match_pet/config/app_router.dart';
import 'package:match_pet/config/theme.dart';
import 'package:match_pet/services/firebase_database_service.dart';
import 'package:match_pet/services/auth_service.dart';
import 'package:match_pet/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar serviços
  await AuthService.initialize();
  
  runApp(const ProviderScope(child: MatchPetApp()));
}

class MatchPetApp extends ConsumerWidget {
  const MatchPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MatchPet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}