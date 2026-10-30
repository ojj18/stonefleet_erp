import '../../../core/database/database_helper.dart';

class OverallOperatorReportRepository {
  final DatabaseHelper _helper;
  OverallOperatorReportRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;

  Future<List<String>> getOperators() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT name FROM (
        SELECT operator_name AS name FROM quarry_blasting_purchases
        UNION SELECT producer_name AS name FROM quarry_boulder_trips
        UNION SELECT driller_name AS name FROM quarry_driller_records
        UNION SELECT operator_name AS name FROM diesel_fillings WHERE vehicle_type = 'External Lorry'
      ) WHERE TRIM(COALESCE(name,'')) <> '' AND LOWER(TRIM(name)) <> 'company'
      ORDER BY name COLLATE NOCASE
    ''');
    final names = rows.map((r) => r['name'].toString()).toSet().toList();
    for (final name in ['Madhavan', 'Murugan']) {
      if (!names.any((n) => n.toLowerCase() == name.toLowerCase())) {
        names.add(name);
      }
    }
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<List<Map<String, dynamic>>> getSettlement({
    required DateTime fromDate,
    required DateTime toDate,
    String? operatorName,
  }) async {
    final db = await _helper.database;
    final result = <Map<String, dynamic>>[];
    final op = operatorName?.trim();
    final filterOp = op != null && op.isNotEmpty;

    Future<void> addRows(String sql, String source, String amountKey) async {
      final rows = await db.rawQuery(sql, [
        _date(fromDate),
        _date(toDate),
        if (filterOp) op.toLowerCase(),
      ]);
      for (final row in rows) {
        final amount = (row[amountKey] as num?)?.toDouble() ?? 0;
        result.add({
          'date': row['entry_date']?.toString() ?? '',
          'operator': row['operator']?.toString() ?? '',
          'source': source,
          'description': row['description']?.toString() ?? '',
          'amount': amount,
        });
      }
    }

    final opClause = filterOp ? 'AND LOWER(TRIM(operator_name)) = ?' : '';
    await addRows(
      '''
      SELECT purchase_date AS entry_date, TRIM(operator_name) AS operator,
             'Blasting materials (Bullet, 3m Wire, 4m Wire, ED)' AS description,
             (COALESCE(bullet_total,0) + COALESCE(wire_3m_total,0) +
              COALESCE(wire_4m_total,0) + COALESCE(ed_total,0)) AS amount
      FROM quarry_blasting_purchases
      WHERE date(purchase_date) BETWEEN date(?) AND date(?) $opClause
        AND LOWER(TRIM(COALESCE(operator_name,''))) <> 'company'
        AND (COALESCE(bullet_total,0) + COALESCE(wire_3m_total,0) +
             COALESCE(wire_4m_total,0) + COALESCE(ed_total,0)) <> 0
    ''',
      'Blasting Materials',
      'amount',
    );

    await addRows(
      '''
      SELECT purchase_date AS entry_date, TRIM(operator_name) AS operator,
             'Padi' AS description, salary AS amount
      FROM quarry_blasting_purchases
      WHERE date(purchase_date) BETWEEN date(?) AND date(?) $opClause
        AND LOWER(TRIM(COALESCE(operator_name,''))) <> 'company'
        AND COALESCE(salary,0) <> 0
    ''',
      'Quarry Blasting',
      'amount',
    );

    final advanceOpClause = filterOp
        ? 'AND LOWER(TRIM(operator_name)) = ?'
        : '';
    await addRows(
      '''
      SELECT purchase_date AS entry_date, TRIM(operator_name) AS operator,
             'Advance paid' AS description, -advance_amount AS amount
      FROM quarry_blasting_purchases
      WHERE date(purchase_date) BETWEEN date(?) AND date(?) $advanceOpClause
        AND LOWER(TRIM(COALESCE(operator_name,''))) <> 'company'
        AND COALESCE(advance_amount,0) <> 0
    ''',
      'Advance',
      'amount',
    );

    final boulderOpClause = filterOp
        ? 'AND LOWER(TRIM(producer_name)) = ?'
        : '';
    await addRows(
      '''
      SELECT trip_date AS entry_date, TRIM(producer_name) AS operator,
             'Boulder trips: ' || COALESCE(trips,0) || ' | Total units: ' || COALESCE(total_load,0) AS description,
             total_value AS amount
      FROM quarry_boulder_trips
      WHERE date(trip_date) BETWEEN date(?) AND date(?) $boulderOpClause
        AND LOWER(TRIM(COALESCE(producer_name,''))) <> 'company'
        AND COALESCE(total_value,0) <> 0
    ''',
      'Quarry Boulders',
      'amount',
    );

    final drillerOpClause = filterOp ? 'AND LOWER(TRIM(driller_name)) = ?' : '';
    await addRows(
      '''
      SELECT record_date AS entry_date, TRIM(driller_name) AS operator,
             'Feet: ' || COALESCE(feet,0) || ' | Rate: ' || COALESCE(rate_per_foot,0) AS description,
             total_amount AS amount
      FROM quarry_driller_records
      WHERE date(record_date) BETWEEN date(?) AND date(?) $drillerOpClause
        AND LOWER(TRIM(COALESCE(driller_name,''))) <> 'company'
        AND COALESCE(total_amount,0) <> 0
    ''',
      'Quarry Driller',
      'amount',
    );

    final dieselOpClause = filterOp ? 'AND LOWER(TRIM(operator_name)) = ?' : '';
    await addRows(
      '''
      SELECT filling_date AS entry_date, TRIM(operator_name) AS operator,
             vehicle_registration || ' | ' || COALESCE(quantity_litres,0) || ' L' AS description,
             total_cost AS amount
      FROM diesel_fillings
      WHERE date(filling_date) BETWEEN date(?) AND date(?)
        AND vehicle_type = 'External Lorry'
        AND LOWER(TRIM(COALESCE(operator_name,''))) <> ''
        AND LOWER(TRIM(COALESCE(operator_name,''))) <> 'company' $dieselOpClause
        AND COALESCE(total_cost,0) <> 0
    ''',
      'Diesel Filling',
      'amount',
    );

    result.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return result;
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
