enum ComplianceStatus { valid, dueSoon, expired, notConfigured }

enum ComplianceEquipmentType { excavator, transport }

class ComplianceModel {
  final int id;
  final ComplianceEquipmentType equipmentType;

  final String? registrationNumber;
  final String? manufacturerName;
  final String? modelName;

  final DateTime? insuranceExpiry;
  final DateTime? fcExpiry;
  final DateTime? permitExpiry;
  final DateTime? taxExpiry;

  ComplianceModel({
    required this.id,
    required this.equipmentType,
    this.registrationNumber,
    this.manufacturerName,
    this.modelName,
    this.insuranceExpiry,
    this.fcExpiry,
    this.permitExpiry,
    this.taxExpiry,
  });

  String get equipmentLabel {
    return equipmentType == ComplianceEquipmentType.excavator
        ? 'Excavator'
        : 'Transport';
  }

  ComplianceStatus getStatus(DateTime? expiryDate) {
    if (expiryDate == null) {
      return ComplianceStatus.notConfigured;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    if (expiryOnly.isBefore(todayOnly)) {
      return ComplianceStatus.expired;
    }

    final dueSoonDate = todayOnly.add(const Duration(days: 30));

    if (!expiryOnly.isAfter(dueSoonDate)) {
      return ComplianceStatus.dueSoon;
    }

    return ComplianceStatus.valid;
  }

  ComplianceStatus get overallStatus {
    final statuses = [
      getStatus(insuranceExpiry),
      getStatus(fcExpiry),
      getStatus(permitExpiry),
      getStatus(taxExpiry),
    ];

    if (statuses.contains(ComplianceStatus.expired)) {
      return ComplianceStatus.expired;
    }

    if (statuses.contains(ComplianceStatus.dueSoon)) {
      return ComplianceStatus.dueSoon;
    }

    if (statuses.every((status) => status == ComplianceStatus.notConfigured)) {
      return ComplianceStatus.notConfigured;
    }

    return ComplianceStatus.valid;
  }

  bool get hasAnyComplianceConfigured {
    return insuranceExpiry != null ||
        fcExpiry != null ||
        permitExpiry != null ||
        taxExpiry != null;
  }
}
