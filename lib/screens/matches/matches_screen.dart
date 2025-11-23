import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:match_pet/models/pet_model.dart';
import 'package:match_pet/services/firebase_database_service.dart';
import 'package:match_pet/providers/auth_provider.dart';
import 'package:match_pet/widgets/pet_card.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  List<PetModel> _matchedPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final matches = await FirebaseDatabaseService.getUserMatches(user.id!);
      final petIds = matches.map((match) => match.petId).toList();
      
      final pets = <PetModel>[];
      for (final petId in petIds) {
        final pet = await FirebaseDatabaseService.getPetById(petId);
        if (pet != null) {
          pets.add(pet);
        }
      }

      setState(() {
        _matchedPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Matches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchedPets.isEmpty
              ? _buildEmptyState()
              : _buildMatchesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum match ainda',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece a dar swipe nos pets para encontrar seus matches!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/swipe'),
            icon: const Icon(Icons.swipe),
            label: const Text('Encontrar Pets'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return Column(
      children: [
        // Header com contador
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Text(
            '${_matchedPets.length} match${_matchedPets.length != 1 ? 'es' : ''} encontrado${_matchedPets.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Lista de matches
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _matchedPets.length,
            itemBuilder: (context, index) {
              final pet = _matchedPets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PetCard(
                  pet: pet,
                  onTap: () => context.go('/pet/${pet.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
