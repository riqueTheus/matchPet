import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:match_pet/models/pet_model.dart';
import 'package:match_pet/models/user_model.dart';
import 'package:match_pet/services/firebase_database_service.dart';
import 'package:match_pet/providers/auth_provider.dart';
import 'package:match_pet/widgets/custom_text_field.dart';
import 'package:match_pet/widgets/loading_button.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  PetType _selectedPetType = PetType.dog;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user.type != UserType.ong) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acesso negado. Apenas ONGs podem cadastrar pets.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar se há pelo menos uma imagem
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma foto do pet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mostrar progresso do upload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Fazendo upload das imagens...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Fazer upload das imagens para o Firebase Storage
      final imageUrls = await FirebaseDatabaseService.uploadMultipleImages(_selectedImages);
      
      if (imageUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao fazer upload das imagens. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Criar modelo do pet
      final pet = PetModel(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        breed: _breedController.text.trim(),
        type: _selectedPetType,
        images: imageUrls,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        ngoId: user.id!,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar pet no Firestore
      final petId = await FirebaseDatabaseService.createPet(pet);
      
      if (petId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pet cadastrado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Limpar formulário
          _nameController.clear();
          _ageController.clear();
          _breedController.clear();
          _descriptionController.clear();
          _locationController.clear();
          setState(() {
            _selectedImages = [];
            _selectedPetType = PetType.dog;
          });
          
          // Navegar para o dashboard
          context.go('/ong/dashboard');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao salvar dados do pet. As imagens foram enviadas, mas os dados não foram salvos.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar pet: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('Erro ao cadastrar pet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Pet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/ong/dashboard');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Cadastrar novo pet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha as informações do pet para disponibilizá-lo para adoção',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Seleção de imagens
              Text(
                'Fotos do pet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImages.isEmpty
                    ? InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 32,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Adicionar fotos',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (_selectedImages.isEmpty)
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar fotos'),
                ),
              const SizedBox(height: 24),

              // Nome do pet
              CustomTextField(
                controller: _nameController,
                label: 'Nome do pet',
                hint: 'Digite o nome do pet',
                prefixIcon: Icons.pets,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Idade
              CustomTextField(
                controller: _ageController,
                label: 'Idade (anos)',
                hint: 'Digite a idade do pet',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Idade é obrigatória';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Idade deve ser um número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de pet
              Text(
                'Tipo de pet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PetType>(
                value: _selectedPetType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: PetType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getPetTypeName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPetType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Raça
              CustomTextField(
                controller: _breedController,
                label: 'Raça',
                hint: 'Digite a raça do pet',
                prefixIcon: Icons.pets,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Raça é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Localização
              CustomTextField(
                controller: _locationController,
                label: 'Localização',
                hint: 'Digite a localização (cidade, estado)',
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Localização é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              CustomTextField(
                controller: _descriptionController,
                label: 'Descrição',
                hint: 'Descreva o pet (personalidade, necessidades especiais, etc.)',
                prefixIcon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botão de salvar
              LoadingButton(
                onPressed: _savePet,
                isLoading: _isLoading,
                child: const Text('Cadastrar Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPetTypeName(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'Cachorro';
      case PetType.cat:
        return 'Gato';
      case PetType.bird:
        return 'Pássaro';
      case PetType.rabbit:
        return 'Coelho';
      case PetType.other:
        return 'Outro';
    }
  }
}
