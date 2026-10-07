import '../../core/database/database_helper.dart';
import '../models/quarry_blasting_purchase_model.dart';

class QuarryBlastingRepository {
  final DatabaseHelper _databaseHelper;

  QuarryBlastingRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<QuarryPurchaseSummary> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? operatorName,
  }) async {
    final db = await _databaseHelper.database;
    final where = <String>[];
    final args = <dynamic>[];
    _addDateFilters(where, args, fromDate, toDate);
    if (operatorName != null && operatorName.trim().isNotEmpty) {
      where.add('LOWER(operator_name) = ?');
      args.add(operatorName.trim().toLowerCase());
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS purchase_count,
        COALESCE(SUM(bullet_quantity), 0) AS bullet_quantity,
        COALESCE(SUM(wire_3m_quantity), 0) AS wire_3m_quantity,
        COALESCE(SUM(wire_4m_quantity), 0) AS wire_4m_quantity,
        COALESCE(SUM(ed_quantity), 0) AS ed_quantity,
        COALESCE(SUM(bullet_total), 0) AS bullet_cost,
        COALESCE(SUM(wire_3m_total), 0) AS wire_3m_cost,
        COALESCE(SUM(wire_4m_total), 0) AS wire4m_cost,
        COALESCE(SUM(ed_total), 0) AS ed_cost,
        COALESCE(SUM(total_cost), 0) AS total_cost
      FROM quarry_blasting_purchases
      $clause
    ''', args);

    return QuarryPurchaseSummary.fromMap(rows.first);
  }

  Future<List<QuarryBlastingPurchase>> getPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    String? operatorName,
  }) async {
    final db = await _databaseHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    _addDateFilters(where, args, fromDate, toDate);
    if (operatorName != null && operatorName.trim().isNotEmpty) {
      where.add('LOWER(operator_name) = ?');
      args.add(operatorName.trim().toLowerCase());
    }

    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim()}%';
      where.add("purchase_date LIKE ?");
      args.add(value);
    }

    final rows = await db.query(
      'quarry_blasting_purchases',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'purchase_date DESC, id DESC',
    );

    return rows.map(QuarryBlastingPurchase.fromMap).toList();
  }

  Future<int> createPurchase({
    required String purchaseDate,
    required String operatorName,
    required double salary,
    required double bulletQuantity,
    required double bulletPrice,
    required double wire3mQuantity,
    required double wire3mPrice,
    required double wire4mQuantity,
    required double wire4mPrice,
    required double edQuantity,
    required double edPrice,
  }) async {
    final db = await _databaseHelper.database;

    final bulletTotal = bulletQuantity * bulletPrice;
    final wire3mTotal = wire3mQuantity * wire3mPrice;
    final wire4mTotal = wire4mQuantity * wire4mPrice;
    final edTotal = edQuantity * edPrice;
    final totalCost = bulletTotal + wire3mTotal + wire4mTotal + edTotal;
    final now = DateTime.now().toIso8601String();

    return db.insert('quarry_blasting_purchases', {
      'purchase_date': purchaseDate,
      'operator_name': operatorName,
      'salary': salary,
      'bullet_quantity': bulletQuantity,
      'bullet_price': bulletPrice,
      'bullet_total': bulletTotal,
      'wire_3m_quantity': wire3mQuantity,
      'wire_3m_price': wire3mPrice,
      'wire_3m_total': wire3mTotal,
      'wire_4m_quantity': wire4mQuantity,
      'wire_4m_price': wire4mPrice,
      'wire_4m_total': wire4mTotal,
      'ed_quantity': edQuantity,
      'ed_price': edPrice,
      'ed_total': edTotal,
      'total_cost': totalCost,
      'created_at': now,
      'updated_at': now,
    });
  }


  Future<int> updatePurchase({
    required int id,
    required String purchaseDate,
    required String operatorName,
    required double salary,
    required double bulletQuantity,
    required double bulletPrice,
    required double wire3mQuantity,
    required double wire3mPrice,
    required double wire4mQuantity,
    required double wire4mPrice,
    required double edQuantity,
    required double edPrice,
  }) async {
    final db = await _databaseHelper.database;

    final bulletTotal = bulletQuantity * bulletPrice;
    final wire3mTotal = wire3mQuantity * wire3mPrice;
    final wire4mTotal = wire4mQuantity * wire4mPrice;
    final edTotal = edQuantity * edPrice;
    final totalCost = bulletTotal + wire3mTotal + wire4mTotal + edTotal;
    final now = DateTime.now().toIso8601String();

    return db.update(
      'quarry_blasting_purchases',
      {
        'purchase_date': purchaseDate,
        'operator_name': operatorName,
        'salary': salary,
        'bullet_quantity': bulletQuantity,
        'bullet_price': bulletPrice,
        'bullet_total': bulletTotal,
        'wire_3m_quantity': wire3mQuantity,
        'wire_3m_price': wire3mPrice,
        'wire_3m_total': wire3mTotal,
        'wire_4m_quantity': wire4mQuantity,
        'wire_4m_price': wire4mPrice,
        'wire_4m_total': wire4mTotal,
        'ed_quantity': edQuantity,
        'ed_price': edPrice,
        'ed_total': edTotal,
        'total_cost': totalCost,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePurchase(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(
      'quarry_blasting_purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  void _addDateFilters(
    List<String> where,
    List<dynamic> args,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate != null) {
      where.add('date(purchase_date) >= date(?)');
      args.add(_dateOnly(fromDate));
    }
    if (toDate != null) {
      where.add('date(purchase_date) <= date(?)');
      args.add(_dateOnly(toDate));
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
