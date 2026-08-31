class TransportServiceItemModel {
  final int? id;
  final int serviceId;
  final int spareId;
  final double quantity;
  final double cost;
  final String? remark;
  final String createdAt;
  final String? updatedAt;

  const TransportServiceItemModel({
    this.id,
    required this.serviceId,
    required this.spareId,
    this.quantity = 1,
    this.cost = 0,
    this.remark,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'spare_id': spareId,
      'quantity': quantity,
      'cost': cost,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory TransportServiceItemModel.fromMap(Map<String, dynamic> map) {
    return TransportServiceItemModel(
      id: map['id'] as int?,
      serviceId: map['service_id'] as int,
      spareId: map['spare_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      cost: (map['cost'] as num).toDouble(),
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  TransportServiceItemModel copyWith({
    int? id,
    int? serviceId,
    int? spareId,
    double? quantity,
    double? cost,
    String? remark,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportServiceItemModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      spareId: spareId ?? this.spareId,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
