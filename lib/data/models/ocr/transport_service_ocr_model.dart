class TransportServiceOcrModel {
  final String? registrationNumber;
  final String? serviceDate;
  final double? currentKm;
  final List<TransportServiceOcrItem> serviceItems;
  final String? serviceRemarks;

  const TransportServiceOcrModel({
    this.registrationNumber,
    this.serviceDate,
    this.currentKm,
    this.serviceItems = const [],
    this.serviceRemarks,
  });

  factory TransportServiceOcrModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TransportServiceOcrModel(
      registrationNumber:
          json['registration_number'] as String?,
      serviceDate:
          json['service_date'] as String?,
      currentKm:
          _toDouble(json['current_km']),
      serviceItems:
          (json['service_items'] as List<dynamic>? ?? [])
              .map(
                (item) => TransportServiceOcrItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      serviceRemarks:
          json['service_remarks'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '').trim(),
    );
  }
}

class TransportServiceOcrItem {
  final String? sparePart;
  final double? quantity;
  final double? cost;
  final String? itemRemark;

  const TransportServiceOcrItem({
    this.sparePart,
    this.quantity,
    this.cost,
    this.itemRemark,
  });

  factory TransportServiceOcrItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return TransportServiceOcrItem(
      sparePart:
          json['spare_part'] as String?,
      quantity:
          _toDouble(json['quantity']),
      cost:
          _toDouble(json['cost']),
      itemRemark:
          json['item_remark'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().replaceAll(',', '').trim(),
    );
  }
}