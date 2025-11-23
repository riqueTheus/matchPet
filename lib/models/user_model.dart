class UserModel {
  final String? id;
  final String name;
  final String email;
  final String password;
  final UserType type;
  final List<Match> matches;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.type,
    this.matches = const [],
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      type: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['type']}',
        orElse: () => UserType.user,
      ),
      matches: (json['matches'] as List<dynamic>?)
          ?.map((match) => Match.fromJson(match))
          .toList() ?? [],
      phone: json['phone'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'type': type.toString().split('.').last,
      'matches': matches.map((match) => match.toJson()).toList(),
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    UserType? type,
    List<Match>? matches,
    String? phone,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      type: type ?? this.type,
      matches: matches ?? this.matches,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Match {
  final String petId;
  final MatchStatus status;
  final DateTime matchedAt;

  Match({
    required this.petId,
    required this.status,
    required this.matchedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      petId: json['pet_id'],
      status: MatchStatus.values.firstWhere(
        (e) => e.toString() == 'MatchStatus.${json['status']}',
        orElse: () => MatchStatus.match,
      ),
      matchedAt: DateTime.parse(json['matchedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'status': status.toString().split('.').last,
      'matchedAt': matchedAt.toIso8601String(),
    };
  }
}

enum UserType {
  user,
  ong,
}

enum MatchStatus {
  match,
  adopted,
}
