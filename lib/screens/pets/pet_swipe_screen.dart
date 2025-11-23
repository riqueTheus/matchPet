import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:match_pet/models/pet_model.dart';
import 'package:match_pet/services/firebase_database_service.dart';
import 'package:match_pet/providers/auth_provider.dart';
import 'package:match_pet/widgets/pet_card.dart';

class PetSwipeScreen extends ConsumerStatefulWidget {
  const PetSwipeScreen({super.key});

  @override
  ConsumerState<PetSwipeScreen> createState() => _PetSwipeScreenState();
}

class _PetSwipeScreenState extends ConsumerState<PetSwipeScreen>
    with TickerProviderStateMixin {
  List<PetModel> _pets = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await FirebaseDatabaseService.getAvailablePets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
      if (_pets.isNotEmpty) {
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSwipeLeft() {
    _nextPet();
  }

  void _onSwipeRight() async {
    if (_currentIndex < _pets.length) {
      final currentPet = _pets[_currentIndex];
      final user = ref.read(currentUserProvider);
      
      if (user != null) {
        // Adicionar match
        final success = await FirebaseDatabaseService.addMatch(user.id!, currentPet.id!);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Match com ${currentPet.name}! ❤️'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }
    _nextPet();
  }

  void _nextPet() {
    if (_currentIndex < _pets.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      // Não há mais pets
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você viu todos os pets disponíveis! Volte mais tarde.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontrar Pets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/matches'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildEmptyState()
              : _buildSwipeArea(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum pet disponível',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Volte mais tarde para ver novos pets!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPets,
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeArea() {
    if (_currentIndex >= _pets.length) {
      return _buildEmptyState();
    }

    final currentPet = _pets[_currentIndex];

    return Column(
      children: [
        // Contador de pets
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${_currentIndex + 1} de ${_pets.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),

        // Card do pet
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: PetCard(
                  pet: currentPet,
                  onTap: () => context.go('/pet/${currentPet.id}'),
                ),
              );
            },
          ),
        ),

        // Botões de ação
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão de rejeitar
              FloatingActionButton(
                onPressed: _onSwipeLeft,
                backgroundColor: Colors.red,
                child: const Icon(Icons.close, color: Colors.white),
              ),
              
              // Botão de ver detalhes
              FloatingActionButton(
                onPressed: () => context.go('/pet/${currentPet.id}'),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.info, color: Colors.white),
              ),
              
              // Botão de curtir
              FloatingActionButton(
                onPressed: _onSwipeRight,
                backgroundColor: Colors.green,
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
