class DieselVehicleOption {
  final int id;
  final String registrationNumber;
  final String type;

  const DieselVehicleOption({
    required this.id,
    required this.registrationNumber,
    required this.type,
  });

  factory DieselVehicleOption.fromMap(Map<String, dynamic> map) {
    return DieselVehicleOption(
      id: (map['id'] as num).toInt(),
      registrationNumber: map['registration_number']?.toString() ?? '',
      type: map['vehicle_type']?.toString() ?? '',
    );
  }
}

class DieselDashboardSummary {
  final double currentStock;
  final double received;
  final double used;
  final double totalCost;
  final double openingStock;

  const DieselDashboardSummary({
    this.currentStock = 0,
    this.received = 0,
    this.used = 0,
    this.totalCost = 0,
    this.openingStock = 0,
  });
}

class DieselFillingRow {
  final int id;
  final String fillingDate;
  final String vehicleType;
  final int vehicleId;
  final String vehicleRegistration;
  final double quantityLitres;
  final double rate;
  final double totalCost;
  final double? meterReading;
  final String? operatorName;
  final String? shift;
  final String? remarks;

  const DieselFillingRow({
    required this.id,
    required this.fillingDate,
    required this.vehicleType,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.quantityLitres,
    required this.rate,
    required this.totalCost,
    this.meterReading,
    this.operatorName,
    this.shift,
    this.remarks,
  });

  factory DieselFillingRow.fromMap(Map<String, dynamic> map) {
    return DieselFillingRow(
      id: (map['id'] as num).toInt(),
      fillingDate: map['filling_date']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString() ?? '',
      vehicleId: (map['vehicle_id'] as num).toInt(),
      vehicleRegistration: map['vehicle_registration']?.toString() ?? '',
      quantityLitres: (map['quantity_litres'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
      meterReading: (map['meter_reading'] as num?)?.toDouble(),
      operatorName: map['operator_name']?.toString(),
      shift: map['shift']?.toString(),
      remarks: map['remarks']?.toString(),
    );
  }
}

class DieselReceiptRow {
  final int id;
  final String receiptDate;
  final String sourceName;
  final double quantityLitres;
  final double rate;
  final double totalCost;
  final String? supplierName;
  final String? billNumber;
  final String? remarks;

  const DieselReceiptRow({
    required this.id,
    required this.receiptDate,
    required this.sourceName,
    required this.quantityLitres,
    required this.rate,
    required this.totalCost,
    this.supplierName,
    this.billNumber,
    this.remarks,
  });

  factory DieselReceiptRow.fromMap(Map<String, dynamic> map) {
    return DieselReceiptRow(
      id: (map['id'] as num).toInt(),
      receiptDate: map['receipt_date']?.toString() ?? '',
      sourceName: map['source_name']?.toString() ?? '',
      quantityLitres: (map['quantity_litres'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
      supplierName: map['supplier_name']?.toString(),
      billNumber: map['bill_number']?.toString(),
      remarks: map['remarks']?.toString(),
    );
  }
}

class DieselStockMovementRow {
  final int id;
  final String transactionType;
  final double quantity;
  final double previousStock;
  final double currentStock;
  final String transactionDate;
  final int? referenceId;
  final String? remarks;

  const DieselStockMovementRow({
    required this.id,
    required this.transactionType,
    required this.quantity,
    required this.previousStock,
    required this.currentStock,
    required this.transactionDate,
    required this.referenceId,
    this.remarks,
  });

  factory DieselStockMovementRow.fromMap(Map<String, dynamic> map) {
    return DieselStockMovementRow(
      id: (map['id'] as num).toInt(),
      transactionType: map['transaction_type']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      previousStock: (map['previous_stock'] as num?)?.toDouble() ?? 0,
      currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0,
      transactionDate: map['transaction_date']?.toString() ?? '',
      referenceId: (map['reference_id'] as num?)?.toInt(),
      remarks: map['remarks']?.toString(),
    );
  }
}

class DieselVehicleConsumptionRow {
  final String vehicleType;
  final String vehicleRegistration;
  final double quantityLitres;
  final double totalCost;
  final int fillingCount;

  const DieselVehicleConsumptionRow({
    required this.vehicleType,
    required this.vehicleRegistration,
    required this.quantityLitres,
    required this.totalCost,
    required this.fillingCount,
  });

  factory DieselVehicleConsumptionRow.fromMap(Map<String, dynamic> map) {
    return DieselVehicleConsumptionRow(
      vehicleType: map['vehicle_type']?.toString() ?? '',
      vehicleRegistration: map['vehicle_registration']?.toString() ?? '',
      quantityLitres: (map['quantity_litres'] as num?)?.toDouble() ?? 0,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
      fillingCount: (map['filling_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DieselReportRow {
  final String date;
  final String vehicleType;
  final String vehicleRegistration;
  final double litres;
  final double rate;
  final double cost;

  const DieselReportRow({
    required this.date,
    required this.vehicleType,
    required this.vehicleRegistration,
    required this.litres,
    required this.rate,
    required this.cost,
  });

  factory DieselReportRow.fromMap(Map<String, dynamic> map) {
    return DieselReportRow(
      date: map['filling_date']?.toString() ?? '',
      vehicleType: map['vehicle_type']?.toString() ?? '',
      vehicleRegistration: map['vehicle_registration']?.toString() ?? '',
      litres: (map['quantity_litres'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      cost: (map['total_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
