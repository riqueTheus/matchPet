class NGOModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String description;
  final List<String> petsAvailable;
  final String? website;
  final String? instagram;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  NGOModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.description,
    this.petsAvailable = const [],
    this.website,
    this.instagram,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NGOModel.fromJson(Map<String, dynamic> json) {
    return NGOModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      description: json['description'],
      petsAvailable: (json['pets_available'] as List<dynamic>?)
          ?.map((id) => id.toString())
          .toList() ?? [],
      website: json['website'],
      instagram: json['instagram'],
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'description': description,
      'pets_available': petsAvailable,
      'website': website,
      'instagram': instagram,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  NGOModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? description,
    List<String>? petsAvailable,
    String? website,
    String? instagram,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NGOModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      description: description ?? this.description,
      petsAvailable: petsAvailable ?? this.petsAvailable,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
