import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:match_pet/models/user_model.dart';
import 'package:match_pet/models/pet_model.dart';
import 'package:match_pet/models/ngo_model.dart';

class FirebaseDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> createUser(UserModel user) async {
    try {
      final docRef = await _firestore.collection('users').add({
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'type': user.type.toString().split('.').last,
        'phone': user.phone,
        'address': user.address,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': Timestamp.fromDate(user.updatedAt),
      });
      return docRef.id;
    } catch (e) {
      print('Erro ao criar usuário: $e');
      return null;
    }
  }

  /// Cria um usuário no Firestore usando um ID específico (geralmente o UID do Firebase Auth)
  static Future<bool> createUserWithId(String userId, UserModel user) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'type': user.type.toString().split('.').last,
        'phone': user.phone,
        'address': user.address,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': Timestamp.fromDate(user.updatedAt),
      });
      return true;
    } catch (e) {
      print('Erro ao criar usuário com ID: $e');
      return false;
    }
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return _userFromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  static Future<UserModel?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return _userFromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar usuário por ID: $e');
      return null;
    }
  }

  static Future<bool> updateUser(String id, UserModel user) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'type': user.type.toString().split('.').last,
        'phone': user.phone,
        'address': user.address,
        'updatedAt': Timestamp.fromDate(user.updatedAt),
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  // Métodos para Pets
  static Future<String?> createPet(PetModel pet) async {
    try {
      final docRef = await _firestore.collection('pets').add({
        'name': pet.name,
        'age': pet.age,
        'breed': pet.breed,
        'type': pet.type.toString().split('.').last,
        'images': pet.images,
        'description': pet.description,
        'location': pet.location,
        'ngoId': pet.ngoId,
        'isAvailable': pet.isAvailable,
        'createdAt': Timestamp.fromDate(pet.createdAt),
        'updatedAt': Timestamp.fromDate(pet.updatedAt),
      });
      return docRef.id;
    } catch (e) {
      print('Erro ao criar pet: $e');
      return null;
    }
  }

  static Future<List<PetModel>> getAvailablePets() async {
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => _petFromDocument(doc)).toList();
    } catch (e) {
      print('Erro ao buscar pets disponíveis: $e');
      return [];
    }
  }

  static Future<List<PetModel>> getPetsByNGO(String ngoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .where('ngoId', isEqualTo: ngoId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => _petFromDocument(doc)).toList();
    } catch (e) {
      print('Erro ao buscar pets da ONG: $e');
      return [];
    }
  }

  static Future<PetModel?> getPetById(String id) async {
    try {
      final doc = await _firestore.collection('pets').doc(id).get();
      if (doc.exists) {
        return _petFromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar pet por ID: $e');
      return null;
    }
  }

  static Future<bool> updatePet(String id, PetModel pet) async {
    try {
      await _firestore.collection('pets').doc(id).update({
        'name': pet.name,
        'age': pet.age,
        'breed': pet.breed,
        'type': pet.type.toString().split('.').last,
        'images': pet.images,
        'description': pet.description,
        'location': pet.location,
        'ngoId': pet.ngoId,
        'isAvailable': pet.isAvailable,
        'updatedAt': Timestamp.fromDate(pet.updatedAt),
      });
      return true;
    } catch (e) {
      print('Erro ao atualizar pet: $e');
      return false;
    }
  }

  // Métodos para ONGs
  static Future<String?> createNGO(NGOModel ngo) async {
    try {
      final docRef = await _firestore.collection('ngos').add({
        'name': ngo.name,
        'email': ngo.email,
        'phone': ngo.phone,
        'address': ngo.address,
        'description': ngo.description,
        'website': ngo.website,
        'instagram': ngo.instagram,
        'isVerified': ngo.isVerified,
        'createdAt': Timestamp.fromDate(ngo.createdAt),
        'updatedAt': Timestamp.fromDate(ngo.updatedAt),
      });
      return docRef.id;
    } catch (e) {
      print('Erro ao criar ONG: $e');
      return null;
    }
  }

  static Future<NGOModel?> getNGOById(String id) async {
    try {
      final doc = await _firestore.collection('ngos').doc(id).get();
      if (doc.exists) {
        return _ngoFromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar ONG por ID: $e');
      return null;
    }
  }

  static Future<List<NGOModel>> getAllNGOs() async {
    try {
      final querySnapshot = await _firestore
          .collection('ngos')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => _ngoFromDocument(doc)).toList();
    } catch (e) {
      print('Erro ao buscar ONGs: $e');
      return [];
    }
  }

  // Métodos para Matches
  static Future<bool> addMatch(String userId, String petId) async {
    try {
      await _firestore.collection('matches').add({
        'userId': userId,
        'petId': petId,
        'status': MatchStatus.match.toString().split('.').last,
        'matchedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar match: $e');
      return false;
    }
  }

  static Future<List<Match>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .orderBy('matchedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Match(
          petId: data['petId'] as String,
          status: MatchStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => MatchStatus.match,
          ),
          matchedAt: (data['matchedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar matches do usuário: $e');
      return [];
    }
  }

  // Upload de imagens
  static Future<String?> uploadImage(String path, String fileName) async {
    try {
      final ref = _storage.ref().child('pet_images/$fileName');
      final uploadTask = await ref.putFile(File(path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Faz upload de múltiplas imagens e retorna as URLs
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> imageUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final url = await uploadImage(file.path, fileName);
      
      if (url != null) {
        imageUrls.add(url);
      } else {
        print('Erro ao fazer upload da imagem $i');
      }
    }
    
    return imageUrls;
  }

  // Métodos auxiliares para conversão
  static UserModel _userFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id, // Firebase usa String IDs
      name: data['name'] as String,
      email: data['email'] as String,
      password: data['password'] as String,
      type: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => UserType.user,
      ),
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static PetModel _petFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      id: doc.id,
      name: data['name'] as String,
      age: data['age'] as int,
      breed: data['breed'] as String,
      type: PetType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => PetType.dog,
      ),
      images: List<String>.from(data['images'] ?? []),
      description: data['description'] as String,
      location: data['location'] as String,
      ngoId: data['ngoId'] as String,
      isAvailable: data['isAvailable'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static NGOModel _ngoFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NGOModel(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      address: data['address'] as String,
      description: data['description'] as String,
      website: data['website'] as String?,
      instagram: data['instagram'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}