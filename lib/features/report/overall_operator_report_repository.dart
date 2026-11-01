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
      ) WHERE TRIM(COALESCE(name,'')) <> ''
      ORDER BY name COLLATE NOCASE
    ''');
    final names = rows.map((r) => r['name'].toString()).toSet().toList();
    for (final name in ['Company', 'Madhavan', 'Murugan']) {
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
        AND COALESCE(total_amount,0) <> 0
    ''',
      'Quarry Driller',
      'amount',
    );

    // Older External Lorry entries may store the operator in
    // vehicle_registration (e.g. "External Lorry - Murugan") while
    // operator_name is empty. Resolve both formats for filtering/reporting.
    const dieselOperatorExpr =
        "CASE WHEN TRIM(COALESCE(operator_name,'')) <> '' THEN TRIM(operator_name) WHEN LOWER(TRIM(COALESCE(vehicle_registration,''))) LIKE 'external lorry - %' THEN TRIM(SUBSTR(vehicle_registration, LENGTH('External Lorry - ') + 1)) ELSE TRIM(COALESCE(vehicle_registration,'')) END";
    final dieselOpClause = filterOp
        ? 'AND LOWER(TRIM(($dieselOperatorExpr))) = ?'
        : '';
    await addRows(
      '''
      SELECT filling_date AS entry_date,
             TRIM(($dieselOperatorExpr)) AS operator,
             vehicle_registration || ' | ' || COALESCE(quantity_litres,0) || ' L' AS description,
             total_cost AS amount
      FROM diesel_fillings
      WHERE date(filling_date) BETWEEN date(?) AND date(?)
        AND LOWER(TRIM(vehicle_type)) = 'external lorry'
        AND TRIM(COALESCE(vehicle_registration,'')) <> ''
        $dieselOpClause
        AND COALESCE(total_cost,0) <> 0
    ''',
      'Diesel Filling',
      'amount',
    );

    result.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return result;
  }

  Future<Map<String, double>> getOperationalBreakdown({
    required DateTime fromDate,
    required DateTime toDate,
    String? operatorName,
  }) async {
    final db = await _helper.database;
    final op = operatorName?.trim();
    final filterOp = op != null && op.isNotEmpty;
    final purchaseWhere =
        '''
      date(purchase_date) BETWEEN date(?) AND date(?)
      ${filterOp ? 'AND LOWER(TRIM(operator_name)) = ?' : ''}
    ''';
    final purchaseArgs = [
      _date(fromDate),
      _date(toDate),
      if (filterOp) op.toLowerCase(),
    ];
    final purchases = await db.rawQuery('''
      SELECT
        COALESCE(SUM(bullet_quantity),0) AS bullet_qty,
        COALESCE(SUM(bullet_total),0) AS bullet_cost,
        COALESCE(SUM(wire_3m_quantity),0) AS wire3m_qty,
        COALESCE(SUM(wire_3m_total),0) AS wire3m_cost,
        COALESCE(SUM(wire_4m_quantity),0) AS wire4m_qty,
        COALESCE(SUM(wire_4m_total),0) AS wire4m_cost,
        COALESCE(SUM(ed_quantity),0) AS ed_qty,
        COALESCE(SUM(ed_total),0) AS ed_cost
      FROM quarry_blasting_purchases
      WHERE $purchaseWhere
    ''', purchaseArgs);
    final boulder = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_load),0) AS boulder_units,
             COALESCE(SUM(total_value),0) AS boulder_cost
      FROM quarry_boulder_trips
      WHERE date(trip_date) BETWEEN date(?) AND date(?)
        ${filterOp ? 'AND LOWER(TRIM(producer_name)) = ?' : ''}
    ''',
      [_date(fromDate), _date(toDate), if (filterOp) op.toLowerCase()],
    );
    const dieselOperatorExpr =
        "CASE WHEN TRIM(COALESCE(operator_name,'')) <> '' THEN TRIM(operator_name) WHEN LOWER(TRIM(COALESCE(vehicle_registration,''))) LIKE 'external lorry - %' THEN TRIM(SUBSTR(vehicle_registration, LENGTH('External Lorry - ') + 1)) ELSE TRIM(COALESCE(vehicle_registration,'')) END";
    final diesel = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity_litres),0) AS diesel_litres,
             COALESCE(SUM(total_cost),0) AS diesel_cost
      FROM diesel_fillings
      WHERE date(filling_date) BETWEEN date(?) AND date(?)
        AND LOWER(TRIM(vehicle_type)) = 'external lorry'
        AND TRIM(COALESCE(vehicle_registration,'')) <> ''
        ${filterOp ? 'AND LOWER(TRIM(($dieselOperatorExpr))) = ?' : ''}
    ''',
      [_date(fromDate), _date(toDate), if (filterOp) op.toLowerCase()],
    );
    double value(Map<String, Object?> row, String key) =>
        (row[key] as num?)?.toDouble() ?? 0;
    final p = purchases.first;
    final d = diesel.first;
    final boulderRow = boulder.first;
    return {
      'boulderUnits': value(boulderRow, 'boulder_units'),
      'boulderCost': value(boulderRow, 'boulder_cost'),
      'bulletQuantity': value(p, 'bullet_qty'),
      'bulletCost': value(p, 'bullet_cost'),
      'wire3mQuantity': value(p, 'wire3m_qty'),
      'wire3mCost': value(p, 'wire3m_cost'),
      'wire4mQuantity': value(p, 'wire4m_qty'),
      'wire4mCost': value(p, 'wire4m_cost'),
      'edQuantity': value(p, 'ed_qty'),
      'edCost': value(p, 'ed_cost'),
      'dieselLitres': value(d, 'diesel_litres'),
      'dieselCost': value(d, 'diesel_cost'),
    };
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
