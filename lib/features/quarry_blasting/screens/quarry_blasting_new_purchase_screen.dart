import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quarry_blasting_purchase_model.dart';
import '../providers/quarry_blasting_provider.dart';
import '../widgets/quarry_blasting_shell.dart';

class QuarryBlastingNewPurchaseScreen extends StatefulWidget {
  final QuarryBlastingPurchase? purchase;

  const QuarryBlastingNewPurchaseScreen({super.key, this.purchase});

  bool get isEdit => purchase != null;

  @override
  State<QuarryBlastingNewPurchaseScreen> createState() =>
      _QuarryBlastingNewPurchaseScreenState();
}

class _QuarryBlastingNewPurchaseScreenState
    extends State<QuarryBlastingNewPurchaseScreen> {
  DateTime _date = DateTime.now();
  final _bulletQty = TextEditingController();
  final _bulletPrice = TextEditingController();
  final _wire3Qty = TextEditingController();
  final _wire3Price = TextEditingController();
  final _wire4Qty = TextEditingController();
  final _wire4Price = TextEditingController();
  final _edQty = TextEditingController();
  final _edPrice = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    if (p != null) {
      final parsed = DateTime.tryParse(p.purchaseDate);
      if (parsed != null) _date = parsed;
      _bulletQty.text = _valueText(p.bulletQuantity);
      _bulletPrice.text = _valueText(p.bulletPrice);
      _wire3Qty.text = _valueText(p.wire3mQuantity);
      _wire3Price.text = _valueText(p.wire3mPrice);
      _wire4Qty.text = _valueText(p.wire4mQuantity);
      _wire4Price.text = _valueText(p.wire4mPrice);
      _edQty.text = _valueText(p.edQuantity);
      _edPrice.text = _valueText(p.edPrice);
    }
    for (final controller in [
      _bulletQty,
      _bulletPrice,
      _wire3Qty,
      _wire3Price,
      _wire4Qty,
      _wire4Price,
      _edQty,
      _edPrice,
    ]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _bulletQty,
      _bulletPrice,
      _wire3Qty,
      _wire3Price,
      _wire4Qty,
      _wire4Price,
      _edQty,
      _edPrice,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  String _valueText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  double _number(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  double get _bulletTotal => _number(_bulletQty) * _number(_bulletPrice);
  double get _wire3Total => _number(_wire3Qty) * _number(_wire3Price);
  double get _wire4Total => _number(_wire4Qty) * _number(_wire4Price);
  double get _edTotal => _number(_edQty) * _number(_edPrice);
  double get _grandTotal => _bulletTotal + _wire3Total + _wire4Total + _edTotal;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final quantities = [
      _number(_bulletQty),
      _number(_wire3Qty),
      _number(_wire4Qty),
      _number(_edQty),
    ];
    final prices = [
      _number(_bulletPrice),
      _number(_wire3Price),
      _number(_wire4Price),
      _number(_edPrice),
    ];

    if (quantities.every((q) => q <= 0)) {
      _showError('Enter quantity for at least one item.');
      return;
    }

    for (var i = 0; i < quantities.length; i++) {
      if (quantities[i] > 0 && prices[i] <= 0) {
        _showError('Enter a valid unit price for every item with quantity.');
        return;
      }
    }

    final provider = context.read<QuarryBlastingProvider>();
    if (widget.isEdit) {
      await provider.updatePurchase(
        id: widget.purchase!.id!,
        purchaseDate: _date.toIso8601String(),
        bulletQuantity: quantities[0],
        bulletPrice: prices[0],
        wire3mQuantity: quantities[1],
        wire3mPrice: prices[1],
        wire4mQuantity: quantities[2],
        wire4mPrice: prices[2],
        edQuantity: quantities[3],
        edPrice: prices[3],
      );
    } else {
      await provider.savePurchase(
        purchaseDate: _date.toIso8601String(),
        bulletQuantity: quantities[0],
        bulletPrice: prices[0],
        wire3mQuantity: quantities[1],
        wire3mPrice: prices[1],
        wire4mQuantity: quantities[2],
        wire4mPrice: prices[2],
        edQuantity: quantities[3],
        edPrice: prices[3],
      );
    }

    if (!mounted) return;
    if (provider.error != null) {
      _showError(provider.error!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEdit
              ? AppLocalization.t('Purchase updated successfully.')
              : AppLocalization.t('Purchase saved successfully.'),
        ),
      ),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return QuarryBlastingShell(
      selectedIndex: 15,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuarryPageHeader(
                    title: widget.isEdit
                        ? AppLocalization.t('Edit Blasting Material Purchase')
                        : AppLocalization.t('New Blasting Material Purchase'),
                    subtitle:
                        AppLocalization.t('Enter quantities and unit prices for the four fixed blasting items.'),
                  ),
                  const SizedBox(height: 24),
                  QuarryCard(
                    title: AppLocalization.t('Purchase Details'),
                    icon: Icons.receipt_long_outlined,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalization.t('Purchase Date'),
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  QuarryCard(
                    title: AppLocalization.t('Purchase Items'),
                    icon: Icons.inventory_2_outlined,
                    child: Column(
                      children: [
                        _itemRow(
                          'Bullet',
                          _bulletQty,
                          _bulletPrice,
                          _bulletTotal,
                        ),
                        const SizedBox(height: 14),
                        _itemRow(
                          '3m Wire',
                          _wire3Qty,
                          _wire3Price,
                          _wire3Total,
                        ),
                        const SizedBox(height: 14),
                        _itemRow(
                          '4m Wire',
                          _wire4Qty,
                          _wire4Price,
                          _wire4Total,
                        ),
                        const SizedBox(height: 14),
                        _itemRow('ED', _edQty, _edPrice, _edTotal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFB7D7BE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalization.t('Grand Total Cost'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatMoney(_grandTotal),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00652C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalization.t('Cancel')),
                      ),
                      const SizedBox(width: 12),
                      Consumer<QuarryBlastingProvider>(
                        builder: (context, provider, _) => FilledButton.icon(
                          onPressed: provider.isLoading ? null : _save,
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(
                            widget.isEdit ? AppLocalization.t('Update Purchase') : AppLocalization.t('Save Purchase'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00652C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemRow(
    String item,
    TextEditingController quantity,
    TextEditingController price,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              item,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _numberField('Quantity', quantity)),
          const SizedBox(width: 16),
          Expanded(child: _numberField('Cost / Unit', price, rupee: true)),
          const SizedBox(width: 18),
          SizedBox(
            width: 145,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocalization.t('TOTAL'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF68717D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(total),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool rupee = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: rupee ? '₹ ' : null,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value != null &&
            value.trim().isNotEmpty &&
            double.tryParse(value.trim()) == null) {
          return AppLocalization.t('Invalid');
        }
        if (value != null &&
            value.trim().isNotEmpty &&
            double.parse(value.trim()) < 0) {
          return AppLocalization.t('Invalid');
        }
        return null;
      },
    );
  }
}
