class UserModel {
  final String id;
  final String email;
  final String? name;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.isEmailVerified = false,
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'isEmailVerified': isEmailVerified,
    'createdAt': createdAt?.toIso8601String(),
  };
}
