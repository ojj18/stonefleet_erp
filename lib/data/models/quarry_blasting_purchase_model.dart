class QuarryBlastingPurchase {
  final int? id;
  final String purchaseDate;
  final String operatorName;
  final double salary;
  final double bulletQuantity;
  final double bulletPrice;
  final double bulletTotal;
  final double wire3mQuantity;
  final double wire3mPrice;
  final double wire3mTotal;
  final double wire4mQuantity;
  final double wire4mPrice;
  final double wire4mTotal;
  final double edQuantity;
  final double edPrice;
  final double edTotal;
  final double totalCost;
  final String? createdAt;
  final String? updatedAt;

  const QuarryBlastingPurchase({
    this.id,
    required this.purchaseDate,
    this.operatorName = 'Company',
    this.salary = 0,
    this.bulletQuantity = 0,
    this.bulletPrice = 0,
    this.bulletTotal = 0,
    this.wire3mQuantity = 0,
    this.wire3mPrice = 0,
    this.wire3mTotal = 0,
    this.wire4mQuantity = 0,
    this.wire4mPrice = 0,
    this.wire4mTotal = 0,
    this.edQuantity = 0,
    this.edPrice = 0,
    this.edTotal = 0,
    this.totalCost = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory QuarryBlastingPurchase.fromMap(Map<String, dynamic> map) {
    double number(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return QuarryBlastingPurchase(
      id: (map['id'] as num?)?.toInt(),
      purchaseDate: map['purchase_date']?.toString() ?? '',
      operatorName: map['operator_name']?.toString() ?? 'Company',
      salary: number('salary'),
      bulletQuantity: number('bullet_quantity'),
      bulletPrice: number('bullet_price'),
      bulletTotal: number('bullet_total'),
      wire3mQuantity: number('wire_3m_quantity'),
      wire3mPrice: number('wire_3m_price'),
      wire3mTotal: number('wire_3m_total'),
      wire4mQuantity: number('wire_4m_quantity'),
      wire4mPrice: number('wire_4m_price'),
      wire4mTotal: number('wire_4m_total'),
      edQuantity: number('ed_quantity'),
      edPrice: number('ed_price'),
      edTotal: number('ed_total'),
      totalCost: number('total_cost'),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}

class QuarryPurchaseSummary {
  final int purchaseCount;
  final double bulletQuantity;
  final double wire3mQuantity;
  final double wire4mQuantity;
  final double edQuantity;
  final double bulletCost;
  final double wire3mCost;
  final double wire4mCost;
  final double edCost;
  final double totalCost;

  const QuarryPurchaseSummary({
    this.purchaseCount = 0,
    this.bulletQuantity = 0,
    this.wire3mQuantity = 0,
    this.wire4mQuantity = 0,
    this.edQuantity = 0,
    this.bulletCost = 0,
    this.wire3mCost = 0,
    this.wire4mCost = 0,
    this.edCost = 0,
    this.totalCost = 0,
  });

  factory QuarryPurchaseSummary.fromMap(Map<String, dynamic> map) {
    double number(String key) => (map[key] as num?)?.toDouble() ?? 0;

    return QuarryPurchaseSummary(
      purchaseCount: (map['purchase_count'] as num?)?.toInt() ?? 0,
      bulletQuantity: number('bullet_quantity'),
      wire3mQuantity: number('wire_3m_quantity'),
      wire4mQuantity: number('wire_4m_quantity'),
      edQuantity: number('ed_quantity'),
      bulletCost: number('bullet_cost'),
      wire3mCost: number('wire_3m_cost'),
      wire4mCost: number('wire4m_cost'),
      edCost: number('ed_cost'),
      totalCost: number('total_cost'),
    );
  }
}
