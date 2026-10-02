class SparePurchaseOcrItem {
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double gstPercentage;
  final double subtotal;
  final double gstAmount;
  final double totalCost;

  const SparePurchaseOcrItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.gstPercentage,
    required this.subtotal,
    required this.gstAmount,
    required this.totalCost,
  });

  factory SparePurchaseOcrItem.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    return SparePurchaseOcrItem(
      itemName: json['item_name']?.toString() ?? '',
      quantity: number(json['quantity']),
      unitPrice: number(json['unit_price']),
      gstPercentage: number(json['gst_percentage']),
      subtotal: number(json['subtotal']),
      gstAmount: number(json['gst_amount']),
      totalCost: number(json['total_cost']),
    );
  }
}

class SparePurchaseOcrModel {
  final String? billNumber;
  final String? supplierName;
  final String? purchaseDate;
  final double subtotal;
  final double gstAmount;
  final double grandTotal;
  final List<SparePurchaseOcrItem> items;

  const SparePurchaseOcrModel({
    this.billNumber,
    this.supplierName,
    this.purchaseDate,
    this.subtotal = 0,
    this.gstAmount = 0,
    this.grandTotal = 0,
    this.items = const [],
  });

  factory SparePurchaseOcrModel.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;

    final rawItems = json['items'];

    return SparePurchaseOcrModel(
      billNumber: json['bill_number']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      purchaseDate: json['purchase_date']?.toString(),
      subtotal: number(json['subtotal']),
      gstAmount: number(json['gst_amount']),
      grandTotal: number(json['grand_total']),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => SparePurchaseOcrItem.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
          : const [],
    );
  }
}
