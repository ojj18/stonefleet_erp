class SpareModel {
  final int? id;
  final String name;
  final String? code;
  final String? category;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  const SpareModel({
    this.id,
    required this.name,
    this.code,
    this.category,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory SpareModel.fromMap(Map<String, dynamic> map) {
    return SpareModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String?,
      category: map['category'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  SpareModel copyWith({
    int? id,
    String? name,
    String? code,
    String? category,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return SpareModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
