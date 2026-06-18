import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/item.dart';
import '../../models/rental.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';

class AddRentalScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const AddRentalScreen({super.key, required this.databaseService});

  @override
  State<AddRentalScreen> createState() => _AddRentalScreenState();
}

class _AddRentalScreenState extends State<AddRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _itemSearchController = TextEditingController();
  String _itemSearchQuery = '';

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 1)),
  );
  
  List<Item> _allAvailableItems = [];
  final Map<int, int> _selectedItemsCount = {}; // itemId -> quantity

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  void _loadItems() async {
    final items = await widget.databaseService.getAllItems();
    setState(() {
      _allAvailableItems = items.where((i) => i.stock > 0).toList();
    });
  }

  List<Item> get _filteredItems {
    if (_itemSearchQuery.isEmpty) return _allAvailableItems;
    return _allAvailableItems.where((item) => 
      item.name.toLowerCase().contains(_itemSearchQuery.toLowerCase()) ||
      item.category.toLowerCase().contains(_itemSearchQuery.toLowerCase())
    ).toList();
  }

  int get _rentalDays {
    int days = _dateRange.duration.inDays;
    return days <= 0 ? 1 : days;
  }

  double get _totalPrice {
    double total = 0;
    for (var entry in _selectedItemsCount.entries) {
      final item = _allAvailableItems.firstWhere((i) => i.id == entry.key);
      if (item.type == 'RENT') {
        total += item.pricePerDay * _rentalDays * entry.value;
      } else {
        total += item.pricePerDay * entry.value;
      }
    }
    return total;
  }

  void _saveRental() async {
    if (_formKey.currentState!.validate() && _selectedItemsCount.isNotEmpty) {
      final List<Item> itemsToSave = [];
      for (var entry in _selectedItemsCount.entries) {
        final item = _allAvailableItems.firstWhere((i) => i.id == entry.key);
        for (int i = 0; i < entry.value; i++) {
          itemsToSave.add(item);
        }
      }

      final rental = Rental(
        customerName: _customerController.text.toUpperCase(),
        startDate: _dateRange.start,
        endDate: _dateRange.end,
        totalPrice: _totalPrice,
        status: 0,
        createdAt: DateTime.now(),
        items: itemsToSave,
      );

      await widget.databaseService.saveRental(rental);

      for (var entry in _selectedItemsCount.entries) {
        final item = _allAvailableItems.firstWhere((i) => i.id == entry.key);
        item.stock -= entry.value;
        await widget.databaseService.saveItem(item);
      }

      if (mounted) Navigator.pop(context);
    } else if (_selectedItemsCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PILIH MINIMAL 1 BARANG'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRANSAKSI BARU', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('INFORMASI PELANGGAN', theme),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customerController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'NAMA LENGKAP PELANGGAN',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? 'Nama pelanggan wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('DURASI SEWA (TIPE RENTAL)', theme),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _dateRange,
                          firstDate: DateTime.now().subtract(const Duration(days: 0)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: theme.copyWith(
                                colorScheme: theme.colorScheme.copyWith(
                                  primary: theme.colorScheme.primary,
                                  onPrimary: theme.colorScheme.onPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setState(() => _dateRange = picked);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Durasi: $_rentalDays Hari',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary, 
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit_calendar_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('PILIH BARANG', theme),
                        if (_selectedItemsCount.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedItemsCount.length} item dipilih', 
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildItemSearchBar(isDark, theme),
                    const SizedBox(height: 16),
                    _buildItemsList(isDark, theme),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomSummary(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildItemSearchBar(bool isDark, ThemeData theme) {
    return TextField(
      controller: _itemSearchController,
      onChanged: (value) => setState(() => _itemSearchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari nama barang atau kategori...',
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: _itemSearchQuery.isNotEmpty 
          ? IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              onPressed: () {
                _itemSearchController.clear();
                setState(() => _itemSearchQuery = '');
              },
            )
          : null,
        filled: true,
        fillColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        fontSize: 11,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildItemsList(bool isDark, ThemeData theme) {
    final filtered = _filteredItems;
    
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.withAlpha(100)),
              const SizedBox(height: 12),
              const Text('Barang tidak ditemukan', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final count = _selectedItemsCount[item.id] ?? 0;
        final isRental = item.type == 'RENT';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: count > 0 ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(isDark ? 80 : 150),
              width: count > 0 ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 0 : 5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ITEM IMAGE
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                  child: item.imagePath != null && item.imagePath!.isNotEmpty
                      ? (item.imagePath!.startsWith('assets/')
                          ? Image.asset(item.imagePath!, fit: BoxFit.cover)
                          : Image.file(File(item.imagePath!), fit: BoxFit.cover))
                      : Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant.withAlpha(100), size: 30),
                ),
              ),
              
              // ITEM DETAILS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRental 
                                  ? theme.colorScheme.primaryContainer.withAlpha(150)
                                  : theme.colorScheme.secondaryContainer.withAlpha(150),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isRental ? 'RENT' : 'SELL',
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold,
                                color: isRental 
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${CurrencyInputFormatter.format(item.pricePerDay)}${isRental ? "/hari" : ""}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stok: ${item.stock}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                          
                          // Quantity selector
                          Row(
                            children: [
                              if (count > 0)
                                _buildCircleButton(Icons.remove, theme.colorScheme.error, () {
                                  setState(() {
                                    if (_selectedItemsCount[item.id!] == 1) {
                                      _selectedItemsCount.remove(item.id);
                                    } else {
                                      _selectedItemsCount[item.id!] = _selectedItemsCount[item.id!]! - 1;
                                    }
                                  });
                                }, theme),
                              if (count > 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              _buildCircleButton(Icons.add, theme.colorScheme.primary, () {
                                if (count < item.stock) {
                                  setState(() {
                                    _selectedItemsCount[item.id!] = (_selectedItemsCount[item.id!] ?? 0) + 1;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Stok tidak mencukupi')),
                                  );
                                }
                              }, theme),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(100)),
          color: color.withAlpha(15),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildBottomSummary(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 15), 
            blurRadius: 15, 
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL PEMBAYARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                  'Rp ${CurrencyInputFormatter.format(_totalPrice)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveRental,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded),
                  SizedBox(width: 8),
                  Text('SIMPAN TRANSAKSI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
