import '../../core/database/database_helper.dart';
import '../models/inventory_models.dart';

class InventoryRepository {
  final DatabaseHelper _databaseHelper;

  InventoryRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<InventorySummary> getSummary() async {
    final db = await _databaseHelper.database;
    final row = (await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM inventory_items) AS total_items,
        COALESCE((SELECT SUM(quantity) FROM inventory_purchase_items), 0) AS purchased,
        COALESCE((SELECT SUM(quantity_used) FROM inventory_usage), 0) AS used,
        COALESCE((SELECT SUM(total_cost) FROM inventory_purchase_items), 0) AS purchase_cost
    '''))[0];

    final purchased = (row['purchased'] as num?)?.toDouble() ?? 0;
    final used = (row['used'] as num?)?.toDouble() ?? 0;

    return InventorySummary(
      totalItems: (row['total_items'] as num?)?.toInt() ?? 0,
      purchasedQuantity: purchased,
      usedQuantity: used,
      remainingQuantity: purchased - used,
      purchaseCost: (row['purchase_cost'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<InventoryPurchaseRow>> getPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _databaseHelper.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('date(p.purchase_date) >= date(?)');
      args.add(_dateOnly(fromDate));
    }
    if (toDate != null) {
      conditions.add('date(p.purchase_date) <= date(?)');
      args.add(_dateOnly(toDate));
    }
    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim().toLowerCase()}%';
      conditions.add('''
        (LOWER(COALESCE(p.bill_number, '')) LIKE ?
         OR LOWER(COALESCE(p.supplier_name, '')) LIKE ?
         OR LOWER(i.item_name) LIKE ?)
      ''');
      args.addAll([value, value, value]);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT
        p.id AS purchase_id,
        p.bill_number,
        p.supplier_name,
        p.purchase_date,
        p.bill_image_path,
        i.item_name,
        pi.quantity,
        pi.unit_price,
        pi.total_cost
      FROM inventory_purchases p
      INNER JOIN inventory_purchase_items pi ON pi.purchase_id = p.id
      INNER JOIN inventory_items i ON i.id = pi.item_id
      $where
      ORDER BY p.purchase_date DESC, p.id DESC, pi.id ASC
    ''', args);

    return rows.map(InventoryPurchaseRow.fromMap).toList();
  }

  Future<List<InventoryStockRow>> getStock({String? search}) async {
    final db = await _databaseHelper.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('LOWER(i.item_name) LIKE ?');
      args.add('%${search.trim().toLowerCase()}%');
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT
        i.id AS item_id,
        i.item_name,
        i.unit,
        COALESCE(SUM(pi.quantity), 0) AS purchased,
        COALESCE((SELECT SUM(u.quantity_used) FROM inventory_usage u WHERE u.item_id = i.id), 0) AS used,
        MAX(p.purchase_date) AS last_purchase_date
      FROM inventory_items i
      LEFT JOIN inventory_purchase_items pi ON pi.item_id = i.id
      LEFT JOIN inventory_purchases p ON p.id = pi.purchase_id
      $where
      GROUP BY i.id, i.item_name, i.unit
      ORDER BY i.item_name ASC
    ''', args);

    return rows.map((row) {
      final purchased = (row['purchased'] as num?)?.toDouble() ?? 0;
      final used = (row['used'] as num?)?.toDouble() ?? 0;
      return InventoryStockRow(
        itemId: (row['item_id'] as num).toInt(),
        itemName: row['item_name']?.toString() ?? '',
        unit: row['unit']?.toString(),
        purchased: purchased,
        used: used,
        remaining: purchased - used,
        lastPurchaseDate: row['last_purchase_date']?.toString(),
      );
    }).toList();
  }

  Future<List<InventoryUsageRow>> getUsage({String? search}) async {
    final db = await _databaseHelper.database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (search != null && search.trim().isNotEmpty) {
      final value = '%${search.trim().toLowerCase()}%';
      conditions.add('''
        (LOWER(i.item_name) LIKE ?
         OR LOWER(COALESCE(u.used_for, '')) LIKE ?
         OR LOWER(COALESCE(u.remarks, '')) LIKE ?)
      ''');
      args.addAll([value, value, value]);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT u.id, i.item_name, u.quantity_used, u.usage_date, u.used_for, u.remarks
      FROM inventory_usage u
      INNER JOIN inventory_items i ON i.id = u.item_id
      $where
      ORDER BY u.usage_date DESC, u.id DESC
    ''', args);

    return rows.map(InventoryUsageRow.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getReport({
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String? itemName,
  }) async {
    final db = await _databaseHelper.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('date(p.purchase_date) >= date(?)');
      args.add(_dateOnly(fromDate));
    }
    if (toDate != null) {
      conditions.add('date(p.purchase_date) <= date(?)');
      args.add(_dateOnly(toDate));
    }
    if (itemName != null && itemName.trim().isNotEmpty) {
      conditions.add('LOWER(i.item_name) = ?');
      args.add(itemName.trim().toLowerCase());
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        i.item_name,
        i.unit,
        COALESCE(SUM(pi.quantity), 0) AS purchased_qty,
        COALESCE((SELECT SUM(u.quantity_used) FROM inventory_usage u WHERE u.item_id = i.id), 0) AS used_qty,
        COALESCE(SUM(pi.quantity), 0) - COALESCE((SELECT SUM(u.quantity_used) FROM inventory_usage u WHERE u.item_id = i.id), 0) AS remaining_qty,
        COALESCE(SUM(pi.total_cost), 0) AS purchase_cost
      FROM inventory_items i
      LEFT JOIN inventory_purchase_items pi ON pi.item_id = i.id
      LEFT JOIN inventory_purchases p ON p.id = pi.purchase_id
      $where
      GROUP BY i.id, i.item_name, i.unit
      HAVING purchased_qty > 0 OR used_qty > 0
      ORDER BY i.item_name ASC
    ''', args);
  }

  Future<List<InventoryItemModel>> getItems() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('inventory_items', orderBy: 'item_name ASC');
    return rows.map(InventoryItemModel.fromMap).toList();
  }

  Future<int> createPurchase(InventoryPurchaseInput input) async {
    if (input.items.isEmpty) {
      throw ArgumentError('At least one purchase item is required.');
    }

    final db = await _databaseHelper.database;

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final purchaseId = await txn.insert('inventory_purchases', {
        'bill_number': input.billNumber,
        'supplier_name': input.supplierName,
        'purchase_date': input.purchaseDate,
        'bill_image_path': input.billImagePath,
        'subtotal': input.subtotal,
        'gst_amount': input.gstAmount,
        'grand_total': input.grandTotal,
        'created_at': now,
        'updated_at': now,
      });

      for (final item in input.items) {
        final existing = await txn.query(
          'inventory_items',
          columns: ['id'],
          where: 'LOWER(item_name) = LOWER(?)',
          whereArgs: [item.itemName.trim()],
          limit: 1,
        );

        final itemId = existing.isNotEmpty
            ? (existing.first['id'] as num).toInt()
            : await txn.insert('inventory_items', {
                'item_name': item.itemName.trim(),
                'unit': null,
                'created_at': now,
                'updated_at': now,
              });

        await txn.insert('inventory_purchase_items', {
          'purchase_id': purchaseId,
          'item_id': itemId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'gst_percentage': item.gstPercentage,
          'subtotal': item.subtotal,
          'gst_amount': item.gstAmount,
          'total_cost': item.totalCost,
          'created_at': now,
        });
      }

      return purchaseId;
    });
  }

  Future<int> createUsage({
    required String itemName,
    required double quantityUsed,
    required String usageDate,
    String? usedFor,
    String? remarks,
  }) async {
    final db = await _databaseHelper.database;
    final item = await db.query(
      'inventory_items',
      columns: ['id'],
      where: 'LOWER(item_name) = LOWER(?)',
      whereArgs: [itemName.trim()],
      limit: 1,
    );
    if (item.isEmpty) throw Exception('Spare item not found.');

    final itemId = (item.first['id'] as num).toInt();
    final stockRows = await db.rawQuery(
      '''
      SELECT
        COALESCE((SELECT SUM(quantity) FROM inventory_purchase_items WHERE item_id = ?), 0) AS purchased,
        COALESCE((SELECT SUM(quantity_used) FROM inventory_usage WHERE item_id = ?), 0) AS used
    ''',
      [itemId, itemId],
    );
    final purchased = (stockRows.first['purchased'] as num?)?.toDouble() ?? 0;
    final used = (stockRows.first['used'] as num?)?.toDouble() ?? 0;
    if (quantityUsed > purchased - used) {
      throw Exception('Usage quantity exceeds available stock.');
    }

    return db.insert('inventory_usage', {
      'item_id': itemId,
      'quantity_used': quantityUsed,
      'usage_date': usageDate,
      'used_for': usedFor,
      'remarks': remarks,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
