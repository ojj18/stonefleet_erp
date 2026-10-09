class RetreadingRecord {
  final int? id;
  final int transportVehicleId;
  final String registrationNumber;
  final String tyreBrand;
  final String tyreSerialNumber;
  final String tyreSize;
  final String retreadingCompany;
  final String sentDate;
  final String status;
  final String? returnDate;
  final double retreadingCost;
  final String? billNumber;
  final double? startingKm;
  final double? endingKm;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;

  const RetreadingRecord({
    this.id,
    required this.transportVehicleId,
    required this.registrationNumber,
    required this.tyreBrand,
    required this.tyreSerialNumber,
    required this.tyreSize,
    required this.retreadingCompany,
    required this.sentDate,
    required this.status,
    this.returnDate,
    this.retreadingCost = 0,
    this.billNumber,
    this.startingKm,
    this.endingKm,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory RetreadingRecord.fromMap(Map<String, dynamic> map) {
    return RetreadingRecord(
      id: map['id'] as int?,
      transportVehicleId: (map['transport_vehicle_id'] as num).toInt(),
      registrationNumber: (map['registration_number'] as String?) ?? '',
      tyreBrand: (map['tyre_brand'] as String?) ?? '',
      tyreSerialNumber: (map['tyre_serial_number'] as String?) ?? '',
      tyreSize: (map['tyre_size'] as String?) ?? '',
      retreadingCompany: (map['retreading_company'] as String?) ?? '',
      sentDate: (map['sent_date'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'AT_RETREADING',
      returnDate: map['return_date'] as String?,
      retreadingCost: (map['retreading_cost'] as num?)?.toDouble() ?? 0,
      billNumber: map['bill_number'] as String?,
      startingKm: (map['starting_km'] as num?)?.toDouble(),
      endingKm: (map['ending_km'] as num?)?.toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'transport_vehicle_id': transportVehicleId,
        'registration_number': registrationNumber,
        'tyre_brand': tyreBrand,
        'tyre_serial_number': tyreSerialNumber,
        'tyre_size': tyreSize,
        'retreading_company': retreadingCompany,
        'sent_date': sentDate,
        'status': status,
        'return_date': returnDate,
        'retreading_cost': retreadingCost,
        'bill_number': billNumber,
        'starting_km': startingKm,
        'ending_km': endingKm,
        'remarks': remarks,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class RetreadingSummary {
  final int totalRecords;
  final int atRetreading;
  final int returned;
  final double totalCost;

  const RetreadingSummary({
    this.totalRecords = 0,
    this.atRetreading = 0,
    this.returned = 0,
    this.totalCost = 0,
  });
}
