class QuarryBoulderTrip {
  final int? id;
  final String tripDate;
  final int transportVehicleId;
  final String registrationNumber;
  final String driverName;
  final String producerName;
  final double unit;
  final int trips;
  final double totalLoad;
  final double unitPrice;
  final double totalValue;
  final String createdAt;
  final String? updatedAt;

  const QuarryBoulderTrip({
    this.id,
    required this.tripDate,
    required this.transportVehicleId,
    required this.registrationNumber,
    required this.driverName,
    required this.producerName,
    required this.unit,
    required this.trips,
    required this.totalLoad,
    this.unitPrice = 0,
    this.totalValue = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory QuarryBoulderTrip.fromMap(Map<String, dynamic> map) {
    return QuarryBoulderTrip(
      id: map['id'] as int?,
      tripDate: map['trip_date'] as String,
      transportVehicleId: map['transport_vehicle_id'] as int,
      registrationNumber: map['registration_number'] as String,
      driverName: map['driver_name'] as String,
      producerName: (map['producer_name'] as String?) ?? 'Company',
      unit: (map['unit'] as num).toDouble(),
      trips: (map['trips'] as num).toInt(),
      totalLoad: (map['total_load'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      totalValue: (map['total_value'] as num?)?.toDouble() ?? (((map['total_load'] as num?)?.toDouble() ?? 0) * ((map['unit_price'] as num?)?.toDouble() ?? 0)),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'trip_date': tripDate,
        'transport_vehicle_id': transportVehicleId,
        'registration_number': registrationNumber,
        'driver_name': driverName,
        'producer_name': producerName,
        'unit': unit,
        'trips': trips,
        'total_load': totalLoad,
        'unit_price': unitPrice,
        'total_value': totalValue,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
