class ManufacturerModel {
  final int? id;
  final String name;
  final String? code;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  const ManufacturerModel({
    this.id,
    required this.name,
    this.code,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ManufacturerModel.fromMap(Map<String, dynamic> map) {
    return ManufacturerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String?,
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
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ManufacturerModel copyWith({
    int? id,
    String? name,
    String? code,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return ManufacturerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
