class PetModel {
  final String? id;
  final String name;
  final int age;
  final String breed;
  final PetType type;
  final List<String> images;
  final String description;
  final String location;
  final String ngoId;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetModel({
    this.id,
    required this.name,
    required this.age,
    required this.breed,
    required this.type,
    this.images = const [],
    required this.description,
    required this.location,
    required this.ngoId,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['_id'],
      name: json['name'],
      age: json['age'],
      breed: json['breed'],
      type: PetType.values.firstWhere(
        (e) => e.toString() == 'PetType.${json['type']}',
        orElse: () => PetType.dog,
      ),
      images: List<String>.from(json['images'] ?? []),
      description: json['description'],
      location: json['location'],
      ngoId: json['ngo_id'],
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'age': age,
      'breed': breed,
      'type': type.toString().split('.').last,
      'images': images,
      'description': description,
      'location': location,
      'ngo_id': ngoId,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PetModel copyWith({
    String? id,
    String? name,
    int? age,
    String? breed,
    PetType? type,
    List<String>? images,
    String? description,
    String? location,
    String? ngoId,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      type: type ?? this.type,
      images: images ?? this.images,
      description: description ?? this.description,
      location: location ?? this.location,
      ngoId: ngoId ?? this.ngoId,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PetType {
  dog,
  cat,
  bird,
  rabbit,
  other,
}
