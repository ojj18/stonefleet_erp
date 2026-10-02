class InventoryItemModel {
  final int? id;
  final String itemName;
  final String? category;
  final String? unit;
  final String createdAt;
  final String? updatedAt;

  const InventoryItemModel({
    this.id,
    required this.itemName,
    this.category,
    this.unit,
    required this.createdAt,
    this.updatedAt,
  });

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) => InventoryItemModel(
        id: map['id'] as int?,
        itemName: map['item_name']?.toString() ?? '',
        category: map['category']?.toString(),
        unit: map['unit']?.toString(),
        createdAt: map['created_at']?.toString() ?? '',
        updatedAt: map['updated_at']?.toString(),
      );
}

class InventoryPurchaseItemInput {
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double gstPercentage;
  final double subtotal;
  final double gstAmount;
  final double totalCost;

  const InventoryPurchaseItemInput({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.gstPercentage,
    required this.subtotal,
    required this.gstAmount,
    required this.totalCost,
  });
}

class InventoryPurchaseInput {
  final String? billNumber;
  final String? supplierName;
  final String purchaseDate;
  final String? billImagePath;
  final double subtotal;
  final double gstAmount;
  final double grandTotal;
  final List<InventoryPurchaseItemInput> items;

  const InventoryPurchaseInput({
    this.billNumber,
    this.supplierName,
    required this.purchaseDate,
    this.billImagePath,
    required this.subtotal,
    required this.gstAmount,
    required this.grandTotal,
    required this.items,
  });
}

class InventoryPurchaseRow {
  final int purchaseId;
  final String? billNumber;
  final String? supplierName;
  final String purchaseDate;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalCost;
  final String? billImagePath;

  const InventoryPurchaseRow({
    required this.purchaseId,
    this.billNumber,
    this.supplierName,
    required this.purchaseDate,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    this.billImagePath,
  });

  factory InventoryPurchaseRow.fromMap(Map<String, dynamic> map) => InventoryPurchaseRow(
        purchaseId: (map['purchase_id'] as num).toInt(),
        billNumber: map['bill_number']?.toString(),
        supplierName: map['supplier_name']?.toString(),
        purchaseDate: map['purchase_date']?.toString() ?? '',
        itemName: map['item_name']?.toString() ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
        billImagePath: map['bill_image_path']?.toString(),
      );
}

class InventoryStockRow {
  final int itemId;
  final String itemName;
  final String? unit;
  final double purchased;
  final double used;
  final double remaining;
  final String? lastPurchaseDate;

  const InventoryStockRow({
    required this.itemId,
    required this.itemName,
    this.unit,
    required this.purchased,
    required this.used,
    required this.remaining,
    this.lastPurchaseDate,
  });

  factory InventoryStockRow.fromMap(Map<String, dynamic> map) => InventoryStockRow(
        itemId: (map['item_id'] as num).toInt(),
        itemName: map['item_name']?.toString() ?? '',
        unit: map['unit']?.toString(),
        purchased: (map['purchased'] as num?)?.toDouble() ?? 0,
        used: (map['used'] as num?)?.toDouble() ?? 0,
        remaining: (map['remaining'] as num?)?.toDouble() ?? 0,
        lastPurchaseDate: map['last_purchase_date']?.toString(),
      );
}

class InventoryUsageRow {
  final int id;
  final String itemName;
  final double quantityUsed;
  final String usageDate;
  final String? usedFor;
  final String? remarks;

  const InventoryUsageRow({
    required this.id,
    required this.itemName,
    required this.quantityUsed,
    required this.usageDate,
    this.usedFor,
    this.remarks,
  });

  factory InventoryUsageRow.fromMap(Map<String, dynamic> map) => InventoryUsageRow(
        id: (map['id'] as num).toInt(),
        itemName: map['item_name']?.toString() ?? '',
        quantityUsed: (map['quantity_used'] as num?)?.toDouble() ?? 0,
        usageDate: map['usage_date']?.toString() ?? '',
        usedFor: map['used_for']?.toString(),
        remarks: map['remarks']?.toString(),
      );
}

class InventorySummary {
  final int totalItems;
  final double purchasedQuantity;
  final double usedQuantity;
  final double remainingQuantity;
  final double purchaseCost;

  const InventorySummary({
    this.totalItems = 0,
    this.purchasedQuantity = 0,
    this.usedQuantity = 0,
    this.remainingQuantity = 0,
    this.purchaseCost = 0,
  });
}
