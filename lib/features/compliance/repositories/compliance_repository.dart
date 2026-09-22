import '../../../core/database/database_helper.dart';
import '../models/compliance_model.dart';

class ComplianceRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<ComplianceModel>> getAllCompliance() async {
    final db = await _databaseHelper.database;

    final excavators = await db.query('excavators', orderBy: 'id DESC');

    final transports = await db.query('transport_vehicles', orderBy: 'id DESC');

    final List<ComplianceModel> result = [];

    for (final row in excavators) {
      result.add(
        ComplianceModel(
          id: row['id'] as int,
          equipmentType: ComplianceEquipmentType.excavator,
          registrationNumber: row['registration_number'] as String?,
          manufacturerName: row['manufacturer_name'] as String?,
          modelName: row['model_name'] as String?,
          insuranceExpiry: _parseDate(row['insurance_expiry']),
          fcExpiry: _parseDate(row['fc_expiry']),
          permitExpiry: _parseDate(row['permit_expiry']),
          taxExpiry: _parseDate(row['tax_expiry']),
        ),
      );
    }

    for (final row in transports) {
      result.add(
        ComplianceModel(
          id: row['id'] as int,
          equipmentType: ComplianceEquipmentType.transport,
          registrationNumber: row['registration_number'] as String?,
          manufacturerName: row['manufacturer_name'] as String?,
          modelName: row['model_name'] as String?,
          insuranceExpiry: _parseDate(row['insurance_expiry']),
          fcExpiry: _parseDate(row['fc_expiry']),
          permitExpiry: _parseDate(row['permit_expiry']),
          taxExpiry: _parseDate(row['tax_expiry']),
        ),
      );
    }

    return result;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }
}
