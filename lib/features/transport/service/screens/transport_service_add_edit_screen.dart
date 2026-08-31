import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/table_constants.dart';
import '../../../../core/database/database_helper.dart';

import '../../../../data/models/transport_service_item_model.dart';
import '../../../../data/models/transport_service_model.dart';

import '../../master/providers/transport_master_provider.dart';
import '../providers/transport_service_provider.dart';

class TransportServiceAddEditScreen extends StatefulWidget {
  final int? serviceId;

  const TransportServiceAddEditScreen({super.key, this.serviceId});

  bool get isEdit => serviceId != null;

  @override
  State<TransportServiceAddEditScreen> createState() =>
      _TransportServiceAddEditScreenState();
}

class _TransportServiceAddEditScreenState
    extends State<TransportServiceAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _kmController = TextEditingController();
  final _remarksController = TextEditingController();

  int? _selectedVehicleId;

  DateTime _serviceDate = DateTime.now();

  final List<_ServiceItemDraft> _items = [];

  List<Map<String, dynamic>> _spares = [];

  bool _initializing = true;
  bool _saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _dateController.text = _formatDate(_serviceDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _dateController.dispose();
    _kmController.dispose();
    _remarksController.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final transportProvider = context.read<TransportProvider>();

      await transportProvider.loadActiveVehicles();

      await _loadSpares();

      if (widget.isEdit) {
        await _loadService();
      } else {
        _addItem();
      }
    } catch (e) {
      if (mounted) {
        _showError('Unable to initialize screen: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD SPARES
  // ============================================================

  Future<void> _loadSpares() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      TableConstants.spares,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    if (!mounted) return;

    setState(() {
      _spares = result;
    });
  }

  // ============================================================
  // LOAD SERVICE
  // ============================================================

  Future<void> _loadService() async {
    final provider = context.read<TransportServiceProvider>();

    final result = await provider.getByIdWithItems(widget.serviceId!);

    if (result == null) {
      throw Exception('Service record not found.');
    }

    if (!mounted) return;

    final service = result.service;

    _serviceDate = DateTime.tryParse(service.serviceDate) ?? DateTime.now();

    _dateController.text = _formatDate(_serviceDate);

    _kmController.text = service.currentKm.toString();

    _remarksController.text = service.remarks ?? '';

    _selectedVehicleId = service.transportVehicleId;

    for (final item in _items) {
      item.dispose();
    }

    _items.clear();

    for (final item in result.items) {
      _items.add(
        _ServiceItemDraft(
          spareId: item.spareId,
          quantity: item.quantity,
          cost: item.cost,
          remark: item.remark,
        ),
      );
    }

    if (_items.isEmpty) {
      _addItem();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00652C)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildTopBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 24),

                        _buildServiceDetails(),

                        const SizedBox(height: 20),

                        _buildServiceItems(),

                        const SizedBox(height: 20),

                        _buildRemarks(),

                        const SizedBox(height: 28),

                        _buildBottomActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),

          const SizedBox(width: 8),

          const Text(
            'StoneFleet ERP Manager',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person_outline, color: Color(0xFF00652C)),
          ),

          const SizedBox(width: 8),

          const Text('Admin', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEdit ? 'Edit Transport Service' : 'Add Transport Service',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191C1E),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          widget.isEdit
              ? 'Update service details and spare parts used.'
              : 'Record transport vehicle service details and spare parts used.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
        ),
      ],
    );
  }

  // ============================================================
  // SERVICE DETAILS
  // ============================================================

  Widget _buildServiceDetails() {
    return _sectionCard(
      title: 'Service Details',
      icon: Icons.build_outlined,
      child: Consumer<TransportProvider>(
        builder: (context, provider, child) {
          final vehicles = provider.vehicles;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;

              final fields = [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedVehicleId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Transport Registration',
                      icon: Icons.local_shipping_outlined,
                    ),
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem<int>(
                        value: vehicle.id,
                        child: Text(
                          vehicle.registrationNumber,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedVehicleId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Select transport vehicle';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: _inputDecoration(
                      label: 'Service Date',
                      icon: Icons.calendar_today_outlined,
                    ),
                    onTap: _saving ? null : _selectDate,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Select service date';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TextFormField(
                    controller: _kmController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(
                      label: 'Current KM',
                      hint: 'e.g. 125850',
                      icon: Icons.speed_outlined,
                    ),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');

                      if (number == null) {
                        return 'Enter current KM';
                      }

                      if (number < 0) {
                        return 'Invalid KM';
                      }

                      return null;
                    },
                  ),
                ),
              ];

              if (wide) {
                return Row(children: fields);
              }

              return Column(
                children: [
                  fields[0],
                  const SizedBox(height: 16),
                  fields[2],
                  const SizedBox(height: 16),
                  fields[4],
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  Widget _buildServiceItems() {
    return _sectionCard(
      title: 'Service Items',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Spare parts used during this service',
                  style: TextStyle(fontSize: 13, color: Color(0xFF68717D)),
                ),
              ),

              OutlinedButton.icon(
                onPressed: _saving ? null : _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Spare'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_items.isEmpty)
            _buildNoItems()
          else
            ...List.generate(
              _items.length,
              (index) => _buildItemRow(_items[index], index),
            ),

          const SizedBox(height: 18),

          _buildTotalCard(),
        ],
      ),
    );
  }

  // ============================================================
  // NO ITEMS
  // ============================================================

  Widget _buildNoItems() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFF68717D)),

          SizedBox(height: 8),

          Text(
            'No spare parts added',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          SizedBox(height: 4),

          Text(
            'Click "Add Spare" to add a service item.',
            style: TextStyle(fontSize: 12, color: Color(0xFF68717D)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM ROW
  // ============================================================

  Widget _buildItemRow(_ServiceItemDraft item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;

          final spareField = _buildSpareDropdown(item);

          final quantityField = _buildQuantityField(item);

          final costField = _buildCostField(item);

          final remarkField = _buildItemRemarkField(item);

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                spareField,

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: quantityField),

                    const SizedBox(width: 12),

                    Expanded(child: costField),
                  ],
                ),

                const SizedBox(height: 12),

                remarkField,

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: _removeButton(index),
                ),

                const SizedBox(height: 8),

                _itemTotal(item),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: spareField),

              const SizedBox(width: 12),

              SizedBox(width: 100, child: quantityField),

              const SizedBox(width: 12),

              SizedBox(width: 130, child: costField),

              const SizedBox(width: 12),

              Expanded(flex: 3, child: remarkField),

              const SizedBox(width: 8),

              SizedBox(
                width: 105,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _removeButton(index),

                    const SizedBox(height: 6),

                    _itemTotal(item),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SPARE DROPDOWN
  // ============================================================

  Widget _buildSpareDropdown(_ServiceItemDraft item) {
    final validSpareIds = _spares.map((spare) => spare['id'] as int).toSet();

    final selectedValue = validSpareIds.contains(item.spareId)
        ? item.spareId
        : null;

    return DropdownButtonFormField<int>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Spare Part',
        icon: Icons.settings_outlined,
      ),
      items: _spares.map((spare) {
        final id = spare['id'] as int;

        final name = spare['name'] as String? ?? '';

        final code = spare['code'] as String?;

        final displayName = code == null || code.trim().isEmpty ? name : name;

        return DropdownMenuItem<int>(
          value: id,
          child: Text(displayName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _saving
          ? null
          : (value) {
              setState(() {
                item.spareId = value;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Select spare';
        }

        return null;
      },
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Widget _buildQuantityField(_ServiceItemDraft item) {
    return TextFormField(
      controller: item.quantityController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: 'Quantity'),
      onChanged: (_) {
        setState(() {});
      },
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');

        if (number == null || number <= 0) {
          return 'Invalid';
        }

        return null;
      },
    );
  }

  // ============================================================
  // COST
  // ============================================================

  Widget _buildCostField(_ServiceItemDraft item) {
    return TextFormField(
      controller: item.costController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: 'Cost / Unit', prefix: '₹ '),
      onChanged: (_) {
        setState(() {});
      },
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');

        if (number == null || number < 0) {
          return 'Invalid';
        }

        return null;
      },
    );
  }

  // ============================================================
  // ITEM REMARK
  // ============================================================

  Widget _buildItemRemarkField(_ServiceItemDraft item) {
    return TextFormField(
      controller: item.remarkController,
      decoration: _inputDecoration(label: 'Item Remark', hint: 'Optional'),
      maxLines: 1,
    );
  }

  // ============================================================
  // REMOVE BUTTON
  // ============================================================

  Widget _removeButton(int index) {
    return IconButton(
      tooltip: 'Remove',
      onPressed: _saving
          ? null
          : () {
              setState(() {
                final item = _items.removeAt(index);

                item.dispose();
              });
            },
      icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
    );
  }

  // ============================================================
  // ITEM TOTAL
  // ============================================================

  Widget _itemTotal(_ServiceItemDraft item) {
    final quantity = double.tryParse(item.quantityController.text) ?? 0;

    final cost = double.tryParse(item.costController.text) ?? 0;

    final total = quantity * cost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'TOTAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF68717D),
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          _currency(total),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOTAL CARD
  // ============================================================

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: Color(0xFF00652C)),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Total Service Cost',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF174D2B),
              ),
            ),
          ),

          Text(
            _currency(_grandTotal),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00652C),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REMARKS
  // ============================================================

  Widget _buildRemarks() {
    return _sectionCard(
      title: 'Remarks',
      icon: Icons.notes_outlined,
      child: TextFormField(
        controller: _remarksController,
        maxLines: 4,
        decoration: _inputDecoration(
          label: 'Service Remarks',
          hint: 'Enter any additional service notes...',
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text('Cancel'),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _saving
                ? 'Saving...'
                : widget.isEdit
                ? 'Update Service'
                : 'Save Service',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  void _addItem() {
    if (_spares.isEmpty) {
      _showError('No active spare parts found. Please add spares first.');
      return;
    }

    setState(() {
      _items.add(_ServiceItemDraft());
    });
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _serviceDate = selected;

      _dateController.text = _formatDate(selected);
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      _showError('Please select a transport vehicle.');
      return;
    }

    if (_items.isEmpty) {
      _showError('Please add at least one spare part.');
      return;
    }

    final selectedSpareIds = <int>{};

    for (final item in _items) {
      if (item.spareId == null) {
        _showError('Please select a spare part.');
        return;
      }

      if (!selectedSpareIds.add(item.spareId!)) {
        _showError('The same spare part cannot be added twice.');
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final provider = context.read<TransportServiceProvider>();

      final now = DateTime.now().toIso8601String();

      final service = TransportServiceModel(
        id: widget.serviceId,
        transportVehicleId: _selectedVehicleId!,
        serviceDate: _databaseDate(_serviceDate),
        currentKm: double.parse(_kmController.text.trim()),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        createdAt: widget.isEdit ? await _getExistingCreatedAt() : now,
        updatedAt: widget.isEdit ? now : null,
      );

      final items = _buildItems(serviceId: widget.serviceId ?? 0, now: now);

      final success = widget.isEdit
          ? await provider.updateService(service: service, items: items)
          : await provider.addService(service: service, items: items);

      if (!mounted) return;

      if (!success) {
        throw Exception(
          provider.error ??
              (widget.isEdit
                  ? 'Unable to update service.'
                  : 'Unable to save service.'),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Service updated successfully.'
                : 'Service added successfully.',
          ),
          backgroundColor: const Color(0xFF00652C),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // EXISTING CREATED AT
  // ============================================================

  Future<String> _getExistingCreatedAt() async {
    final provider = context.read<TransportServiceProvider>();

    final existing = await provider.getById(widget.serviceId!);

    return existing?.createdAt ?? DateTime.now().toIso8601String();
  }

  // ============================================================
  // BUILD ITEMS
  // ============================================================

  List<TransportServiceItemModel> _buildItems({
    required int serviceId,
    required String now,
  }) {
    return _items.map((item) {
      return TransportServiceItemModel(
        serviceId: serviceId,
        spareId: item.spareId!,
        quantity: double.parse(item.quantityController.text.trim()),
        cost: double.parse(item.costController.text.trim()),
        remark: item.remarkController.text.trim().isEmpty
            ? null
            : item.remarkController.text.trim(),
        createdAt: now,
        updatedAt: null,
      );
    }).toList();
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF00652C)),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      prefixText: prefix,
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBECABC)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBECABC)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00652C), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double get _grandTotal {
    var total = 0.0;

    for (final item in _items) {
      final quantity = double.tryParse(item.quantityController.text) ?? 0;

      final cost = double.tryParse(item.costController.text) ?? 0;

      total += quantity * cost;
    }

    return total;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _databaseDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _currency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }
}

// ================================================================
// SERVICE ITEM DRAFT
// ================================================================

class _ServiceItemDraft {
  int? spareId;

  final TextEditingController quantityController;

  final TextEditingController costController;

  final TextEditingController remarkController;

  _ServiceItemDraft({
    this.spareId,
    double quantity = 1,
    double cost = 0,
    String? remark,
  }) : quantityController = TextEditingController(
         text: _numberString(quantity),
       ),
       costController = TextEditingController(text: _numberString(cost)),
       remarkController = TextEditingController(text: remark ?? '');

  void dispose() {
    quantityController.dispose();

    costController.dispose();

    remarkController.dispose();
  }

  static String _numberString(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}
