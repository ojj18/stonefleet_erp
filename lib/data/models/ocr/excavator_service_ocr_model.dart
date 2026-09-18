class ExcavatorServiceOcrModel {
  final String? registrationNumber;
  final String? serviceDate;
  final double? currentHourMeter;
  final List<ExcavatorServiceOcrItem> serviceItems;
  final String? serviceRemarks;

  const ExcavatorServiceOcrModel({
    this.registrationNumber,
    this.serviceDate,
    this.currentHourMeter,
    this.serviceItems = const [],
    this.serviceRemarks,
  });

  factory ExcavatorServiceOcrModel.fromJson(Map<String, dynamic> json) {
    return ExcavatorServiceOcrModel(
      registrationNumber: json['registration_number'] as String?,
      serviceDate: json['service_date'] as String?,
      currentHourMeter: _toDouble(json['current_hour_meter']),
      serviceItems: (json['service_items'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ExcavatorServiceOcrItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      serviceRemarks: json['service_remarks'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }
}

class ExcavatorServiceOcrItem {
  final String? sparePart;
  final double? quantity;
  final double? cost;
  final String? itemRemark;

  const ExcavatorServiceOcrItem({
    this.sparePart,
    this.quantity,
    this.cost,
    this.itemRemark,
  });

  factory ExcavatorServiceOcrItem.fromJson(Map<String, dynamic> json) {
    return ExcavatorServiceOcrItem(
      sparePart: json['spare_part'] as String?,
      quantity: _toDouble(json['quantity']),
      cost: _toDouble(json['cost']),
      itemRemark: json['item_remark'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }
}
