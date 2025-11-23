import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:match_pet/models/pet_model.dart';
import 'package:match_pet/models/user_model.dart';
import 'package:match_pet/services/firebase_database_service.dart';
import 'package:match_pet/providers/auth_provider.dart';
import 'package:match_pet/widgets/pet_card.dart';

class ONGDashboardScreen extends ConsumerStatefulWidget {
  const ONGDashboardScreen({super.key});

  @override
  ConsumerState<ONGDashboardScreen> createState() => _ONGDashboardScreenState();
}

class _ONGDashboardScreenState extends ConsumerState<ONGDashboardScreen> {
  List<PetModel> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.type != UserType.ong) return;

      final pets = await FirebaseDatabaseService.getPetsByNGO(user.id!);
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
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

  Future<void> _deletePet(PetModel pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implementar exclusão de pet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade em desenvolvimento'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null || user.type != UserType.ong) {
      return const Scaffold(
        body: Center(child: Text('Acesso negado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard ONG'),
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
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/ong/add-pet'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com estatísticas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      Text(
                        'Bem-vindo, ${user.name}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            context,
                            icon: Icons.pets,
                            title: 'Total de Pets',
                            value: _pets.length.toString(),
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            context,
                            icon: Icons.check_circle,
                            title: 'Disponíveis',
                            value: _pets.where((pet) => pet.isAvailable).length.toString(),
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            context,
                            icon: Icons.favorite,
                            title: 'Adotados',
                            value: _pets.where((pet) => !pet.isAvailable).length.toString(),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de pets
                Expanded(
                  child: _pets.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pets.length,
                          itemBuilder: (context, index) {
                            final pet = _pets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                child: Column(
                                  children: [
                                    PetCard(
                                      pet: pet,
                                      onTap: () => context.go('/pet/${pet.id}'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                // TODO: Implementar edição de pet
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Funcionalidade em desenvolvimento'),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.edit),
                                              label: const Text('Editar'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _deletePet(pet),
                                              icon: const Icon(Icons.delete),
                                              label: const Text('Excluir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ong/add-pet'),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Pet'),
      ),
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
            'Nenhum pet cadastrado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece adicionando seu primeiro pet!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/ong/add-pet'),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
