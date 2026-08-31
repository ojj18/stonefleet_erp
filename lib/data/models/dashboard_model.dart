class DashboardModel {
  // ============================================================
  // FLEET KPIs
  // ============================================================

  final int totalExcavators;
  final int workingExcavators;

  final int totalTransportVehicles;
  final int workingTransportVehicles;

  final double totalWorkingHours;
  final double totalTransportKm;

  final double totalDieselUsed;
  final double totalDieselExpense;

  // ============================================================
  // TODAY'S EXCAVATOR OPERATIONS
  // ============================================================

  final List<ExcavatorOperationModel> excavatorOperations;

  // ============================================================
  // TODAY'S TRANSPORT OPERATIONS
  // ============================================================

  final List<TransportOperationModel> transportOperations;

  // ============================================================
  // SERVICE
  // ============================================================

  final List<ServiceOverviewModel> serviceOverview;

  final List<RecentServiceModel> recentServices;

  const DashboardModel({
    this.totalExcavators = 0,
    this.workingExcavators = 0,
    this.totalTransportVehicles = 0,
    this.workingTransportVehicles = 0,
    this.totalWorkingHours = 0,
    this.totalTransportKm = 0,
    this.totalDieselUsed = 0,
    this.totalDieselExpense = 0,
    this.excavatorOperations = const [],
    this.transportOperations = const [],
    this.serviceOverview = const [],
    this.recentServices = const [],
  });
}

// ============================================================
// EXCAVATOR OPERATION
// ============================================================

class ExcavatorOperationModel {
  final String registrationNumber;
  final String operatorName;
  final String shift;

  final double openingHours;
  final double closingHours;
  final double totalHours;

  final int loads;
  final double tonnage;

  final double dieselFilled;

  const ExcavatorOperationModel({
    required this.registrationNumber,
    required this.operatorName,
    required this.shift,
    required this.openingHours,
    required this.closingHours,
    required this.totalHours,
    required this.loads,
    required this.tonnage,
    required this.dieselFilled,
  });
}

// ============================================================
// TRANSPORT OPERATION
// ============================================================

class TransportOperationModel {
  final String registrationNumber;
  final String driverName;

  final double startingKm;
  final double closingKm;
  final double totalKm;

  final int numberOfLoads;

  final String loadingSite;
  final String unloadingSite;

  final double dieselFilled;

  const TransportOperationModel({
    required this.registrationNumber,
    required this.driverName,
    required this.startingKm,
    required this.closingKm,
    required this.totalKm,
    required this.numberOfLoads,
    required this.loadingSite,
    required this.unloadingSite,
    required this.dieselFilled,
  });
}

// ============================================================
// SERVICE OVERVIEW
// ============================================================

enum ServiceStatus { overdue, due, upcoming }

class ServiceOverviewModel {
  final String registrationNumber;
  final String serviceName;
  final String description;
  final ServiceStatus status;

  const ServiceOverviewModel({
    required this.registrationNumber,
    required this.serviceName,
    required this.description,
    required this.status,
  });
}

// ============================================================
// RECENT SERVICE
// ============================================================

class RecentServiceModel {
  final String registrationNumber;
  final String serviceDate;

  final String serviceDescription;

  final double currentKm;
  final double currentHours;

  final double totalCost;

  const RecentServiceModel({
    required this.registrationNumber,
    required this.serviceDate,
    required this.serviceDescription,
    this.currentKm = 0,
    this.currentHours = 0,
    this.totalCost = 0,
  });
}
