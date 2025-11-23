import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:match_pet/screens/auth/login_screen.dart';
import 'package:match_pet/screens/auth/register_screen.dart';
import 'package:match_pet/screens/home/home_screen.dart';
import 'package:match_pet/screens/pets/pet_detail_screen.dart';
import 'package:match_pet/screens/pets/pet_swipe_screen.dart';
import 'package:match_pet/screens/profile/user_profile_screen.dart';
import 'package:match_pet/screens/ong/ong_dashboard_screen.dart';
import 'package:match_pet/screens/ong/add_pet_screen.dart';
import 'package:match_pet/screens/matches/matches_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Rotas de autenticação
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Rotas principais
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/swipe',
        name: 'swipe',
        builder: (context, state) => const PetSwipeScreen(),
      ),
      GoRoute(
        path: '/pet/:id',
        name: 'pet-detail',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetDetailScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/matches',
        name: 'matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      
      // Rotas para ONGs
      GoRoute(
        path: '/ong/dashboard',
        name: 'ong-dashboard',
        builder: (context, state) => const ONGDashboardScreen(),
      ),
      GoRoute(
        path: '/ong/add-pet',
        name: 'add-pet',
        builder: (context, state) => const AddPetScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'A página que você está procurando não existe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Voltar ao Início'),
            ),
          ],
        ),
      ),
    ),
  );
}

