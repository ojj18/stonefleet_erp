import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_sidebar.dart';
import '../../../data/models/inventory_models.dart';
import '../../../data/models/ocr/spare_purchase_ocr_model.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

class SparePurchaseOcrScreen extends StatefulWidget {
  const SparePurchaseOcrScreen({super.key});

  @override
  State<SparePurchaseOcrScreen> createState() => _SparePurchaseOcrScreenState();
}

class _SparePurchaseOcrScreenState extends State<SparePurchaseOcrScreen> {
  XFile? _file;
  Uint8List? _bytes;
  SparePurchaseOcrModel? _ocr;
  bool _manualMode = false;
  final _billController = TextEditingController();
  final _supplierController = TextEditingController();
  final _dateController = TextEditingController();
  final List<_EditableItem> _items = [];
  final _subtotalController = TextEditingController(text: '0');
  final _gstController = TextEditingController(text: '0');
  final _grandTotalController = TextEditingController(text: '0');

  @override
  void dispose() {
    _billController.dispose();
    _supplierController.dispose();
    _dateController.dispose();
    _subtotalController.dispose();
    _gstController.dispose();
    _grandTotalController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _selectBill() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: AppLocalization.t('Bills'),
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
        ),
      ],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _manualMode = false;
      _file = file;
      _bytes = bytes;
      _ocr = null;
    });
  }

  void _startManualEntry() {
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
    _ocr = null;
    _manualMode = true;
    _file = null;
    _bytes = null;
    _billController.clear();
    _supplierController.clear();
    _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
    _subtotalController.text = '0';
    _gstController.text = '0';
    _grandTotalController.text = '0';
    _items.add(
      _EditableItem(
        name: TextEditingController(),
        quantity: TextEditingController(),
        unitPrice: TextEditingController(),
        gst: TextEditingController(text: '0'),
        subtotal: TextEditingController(),
        total: TextEditingController(),
      ),
    );
    setState(() {});
  }

  void _addManualItem() {
    setState(() {
      _items.add(
        _EditableItem(
          name: TextEditingController(),
          quantity: TextEditingController(),
          unitPrice: TextEditingController(),
          gst: TextEditingController(text: '0'),
          subtotal: TextEditingController(),
          total: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _extract() async {
    final file = _file;
    if (file == null) {
      _show(AppLocalization.t('Please upload a bill first.'));
      return;
    }

    try {
      final result = await context.read<InventoryProvider>().extractBill(file);
      _applyOcr(result);
      _show(AppLocalization.t('Bill data extracted. Please review before saving.'));
    } catch (e) {
      _show(e.toString());
    }
  }

  void _applyOcr(SparePurchaseOcrModel data) {
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
    _ocr = data;
    _billController.text = data.billNumber ?? '';
    _supplierController.text = data.supplierName ?? '';
    _dateController.text =
        data.purchaseDate ?? DateTime.now().toIso8601String().substring(0, 10);
    _subtotalController.text = data.subtotal.toStringAsFixed(2);
    _gstController.text = data.gstAmount.toStringAsFixed(2);
    _grandTotalController.text = data.grandTotal.toStringAsFixed(2);
    for (final item in data.items) {
      _items.add(_EditableItem.fromOcr(item));
    }
    setState(() {});
  }

  Future<void> _save() async {
    _items.removeWhere((item) => item.name.text.trim().isEmpty);
    if (_items.isEmpty) {
      _show(AppLocalization.t('Add at least one purchase item.'));
      return;
    }
    for (final item in _items) {
      final qty = double.tryParse(item.quantity.text.trim()) ?? 0;
      final price = double.tryParse(item.unitPrice.text.trim()) ?? 0;
      if (item.name.text.trim().isEmpty || qty <= 0 || price < 0) {
        _show(AppLocalization.t('Enter valid purchase item details.'));
        return;
      }
    }
    final provider = context.read<InventoryProvider>();
    final input = InventoryPurchaseInput(
      billNumber: _billController.text.trim().isEmpty
          ? null
          : _billController.text.trim(),
      supplierName: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
      purchaseDate: _dateController.text.trim(),
      billImagePath: _file?.path,
      subtotal: double.tryParse(_subtotalController.text) ?? 0,
      gstAmount: double.tryParse(_gstController.text) ?? 0,
      grandTotal: double.tryParse(_grandTotalController.text) ?? 0,
      items: _items.map((item) => item.toInput()).toList(),
    );
    try {
      await provider.savePurchase(input);
      if (provider.error != null) throw Exception(provider.error);
      _show(AppLocalization.t('Purchase saved successfully.'));
      if (mounted) handleMenuTap(12, context: context);
    } catch (e) {
      _show(e.toString());
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return InventoryShell(
      selectedIndex: 12,
      child: Consumer<InventoryProvider>(
        builder: (context, provider, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InventoryPageHeader(
                    title: AppLocalization.t('Spare Purchase & OCR'),
                    subtitle:
                        AppLocalization.t('Upload a purchase bill, extract data and verify it before saving.'),
                  ),
                  const SizedBox(height: 24),
                  InventorySectionCard(
                    title: AppLocalization.t('Upload Spare Purchase Bill'),
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBECABC)),
                          ),
                          child: Column(
                            children: [
                              if (_bytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _bytes!,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else ...[
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 46,
                                  color: Color(0xFF00652C),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalization.t(
                                    'Upload a photo of the purchase bill',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                onPressed: _selectBill,
                                icon: const Icon(Icons.upload_file_outlined),
                                label: Text(
                                  _file == null ? AppLocalization.t('Upload Bill') : AppLocalization.t('Change Bill'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: provider.isExtracting ? null : _extract,
                            icon: provider.isExtracting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(
                              provider.isExtracting
                                  ? 'Extracting...'
                                  : AppLocalization.t('Extract Data'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00652C),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(145, 46),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _startManualEntry,
                            icon: const Icon(Icons.edit_note_outlined),
                            label: Text(AppLocalization.t('Add Manually')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_ocr != null || _manualMode) ...[
                    const SizedBox(height: 24),
                    _buildReviewCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    return InventorySectionCard(
      title: AppLocalization.t('Review Purchase Details'),
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field(AppLocalization.t('Bill Number'), _billController)),
              const SizedBox(width: 16),
              Expanded(child: _field(AppLocalization.t('Supplier Name'), _supplierController)),
              const SizedBox(width: 16),
              Expanded(
                child: _field(AppLocalization.t('Purchase Date (YYYY-MM-DD)'), _dateController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(AppLocalization.t('Subtotal'), _subtotalController)),
              const SizedBox(width: 16),
              Expanded(child: _field(AppLocalization.t('GST Amount'), _gstController)),
              const SizedBox(width: 16),
              Expanded(child: _field(AppLocalization.t('Grand Total'), _grandTotalController)),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalization.t('Purchase Items'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          _items.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    AppLocalization.t(
                      'No items extracted. Add items after OCR.',
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 0,
                    columnSpacing: 18,
                    headingRowHeight: 44,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    dividerThickness: 1,
                    columns: [
                      DataColumn(label: Text(AppLocalization.t('SPARE ITEM'))),
                      DataColumn(label: Text(AppLocalization.t('QTY'))),
                      DataColumn(label: Text(AppLocalization.t('UNIT PRICE'))),
                      DataColumn(label: Text(AppLocalization.t('GST %'))),
                      DataColumn(label: Text(AppLocalization.t('SUBTOTAL'))),
                      DataColumn(label: Text(AppLocalization.t('TOTAL COST'))),
                    ],
                    rows: _items
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 260,
                                  child: TextField(controller: item.name),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 95,
                                  child: TextField(
                                    controller: item.quantity,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 125,
                                  child: TextField(
                                    controller: item.unitPrice,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 95,
                                  child: TextField(
                                    controller: item.gst,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 125,
                                  child: TextField(
                                    controller: item.subtotal,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 125,
                                  child: TextField(
                                    controller: item.total,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
           const SizedBox(height: 16),
           Align(
             alignment: Alignment.centerLeft,
             child: OutlinedButton.icon(
               onPressed: _addManualItem,
               icon: const Icon(Icons.add),
               label: Text(AppLocalization.t('Add Item')),
             ),
           ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalization.t('Cancel')),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(AppLocalization.t('Confirm & Save')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00652C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _EditableItem {
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController gst;
  final TextEditingController subtotal;
  final TextEditingController total;

  _EditableItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.gst,
    required this.subtotal,
    required this.total,
  });

  factory _EditableItem.fromOcr(SparePurchaseOcrItem item) => _EditableItem(
    name: TextEditingController(text: item.itemName),
    quantity: TextEditingController(text: item.quantity.toString()),
    unitPrice: TextEditingController(text: item.unitPrice.toString()),
    gst: TextEditingController(text: item.gstPercentage.toString()),
    subtotal: TextEditingController(text: item.subtotal.toString()),
    total: TextEditingController(text: item.totalCost.toString()),
  );

  InventoryPurchaseItemInput toInput() => InventoryPurchaseItemInput(
    itemName: name.text.trim(),
    quantity: double.tryParse(quantity.text) ?? 0,
    unitPrice: double.tryParse(unitPrice.text) ?? 0,
    gstPercentage: double.tryParse(gst.text) ?? 0,
    subtotal: double.tryParse(subtotal.text) ?? 0,
    gstAmount: 0,
    totalCost: double.tryParse(total.text) ?? 0,
  );

  void dispose() {
    name.dispose();
    quantity.dispose();
    unitPrice.dispose();
    gst.dispose();
    subtotal.dispose();
    total.dispose();
  }
}
