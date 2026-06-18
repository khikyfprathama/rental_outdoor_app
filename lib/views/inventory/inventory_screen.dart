import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import 'add_item_screen.dart';
import 'stock_opname_screen.dart';
import 'manage_categories_screen.dart';

class InventoryScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const InventoryScreen({super.key, required this.databaseService});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Item>> _itemsFuture;
  String? _selectedCategory;
  String? _selectedType; // RENT, SELL, or NULL (ALL)
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _loadCategories();
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = widget.databaseService.getAllItems(
        category: _selectedCategory,
        type: _selectedType,
      );
    });
  }

  Future<void> _loadCategories() async {
    final cats = await widget.databaseService.getAllCategories();
    setState(() {
      _categories = cats;
    });
  }

  void _showImagePreview(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
              backgroundColor: Colors.black45,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            InteractiveViewer(
              child: imagePath.startsWith('assets/')
                ? Image.asset(imagePath, fit: BoxFit.contain)
                : Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('INVENTORI ALAT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            tooltip: 'KELOLA KATEGORI',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageCategoriesScreen(databaseService: widget.databaseService),
                ),
              );
              _loadCategories();
              _refreshItems();
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_check_rounded),
            tooltip: 'STOCK OPNAME',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockOpnameScreen(databaseService: widget.databaseService),
                ),
              );
              if (result == true) _refreshItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(theme),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('ERROR: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory != null || _selectedType != null
                              ? 'Barang filter tidak ditemukan'
                              : 'Belum ada barang di inventori.',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data!;
                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(item, theme, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemScreen(databaseService: widget.databaseService),
            ),
          );
          if (result == true) {
            _refreshItems();
            _loadCategories();
          }
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('TAMBAH BARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Type Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTypeChip('Semua Tipe', null, theme),
                const SizedBox(width: 8),
                _buildTypeChip('Disewakan', 'RENT', theme),
                const SizedBox(width: 8),
                _buildTypeChip('Dijual', 'SELL', theme),
              ],
            ),
          ),
          // Row 2: Category Chips
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _buildCategoryChip('Semua Kategori', null, theme),
                  ..._categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _buildCategoryChip(cat.toUpperCase(), cat, theme),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String? typeValue, ThemeData theme) {
    final isSelected = _selectedType == typeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = typeValue;
          });
          _refreshItems();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary.withAlpha(100) : theme.colorScheme.outline.withAlpha(150),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildCategoryChip(String label, String? catValue, ThemeData theme) {
    final isSelected = _selectedCategory == catValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = catValue;
          });
          _refreshItems();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.secondary.withAlpha(100) : theme.colorScheme.outline.withAlpha(150),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildItemCard(Item item, ThemeData theme, bool isDark) {
    final isRental = item.type == 'RENT';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 150),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 0 : 5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _editItem(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Item Photo
                GestureDetector(
                  onTap: item.imagePath != null
                      ? () => _showImagePreview(item.imagePath!, item.name)
                      : null,
                  child: Hero(
                    tag: 'item_img_${item.id}',
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
                      ),
                      child: item.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: item.imagePath!.startsWith('assets/')
                                  ? Image.asset(item.imagePath!, fit: BoxFit.cover)
                                  : Image.file(File(item.imagePath!), fit: BoxFit.cover),
                            )
                          : Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant.withAlpha(100), size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Badge & Category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRental 
                                  ? theme.colorScheme.primaryContainer.withAlpha(150)
                                  : theme.colorScheme.secondaryContainer.withAlpha(150),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRental ? 'SEWA' : 'JUAL',
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
                              item.category.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Name
                      Text(
                        item.name.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Price & Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${CurrencyInputFormatter.format(item.pricePerDay)}${isRental ? "/hari" : ""}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          _buildStockBadge(item.stock, theme),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Popup Actions Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editItem(item);
                    } else if (value == 'delete') {
                      _showDeleteConfirm(item);
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Edit Item'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                          SizedBox(width: 12),
                          Text('Hapus', style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, ThemeData theme) {
    Color badgeColor;
    Color textColor;
    String label;

    if (stock == 0) {
      badgeColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
      label = 'Habis';
    } else if (stock <= 3) {
      badgeColor = Colors.orange.withAlpha(35);
      textColor = Colors.orange[800]!;
      label = 'Stok $stock';
    } else {
      badgeColor = theme.colorScheme.primaryContainer.withAlpha(60);
      textColor = theme.colorScheme.primary;
      label = '$stock unit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _editItem(Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          databaseService: widget.databaseService,
          itemToEdit: item,
        ),
      ),
    );
    if (result == true) {
      _refreshItems();
      _loadCategories();
    }
  }

  void _showDeleteConfirm(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: Text('Apakah Anda yakin ingin menghapus ${item.name.toUpperCase()} dari inventori?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          TextButton(
            onPressed: () async {
              await widget.databaseService.deleteItem(item.id!);
              if (mounted) Navigator.pop(context);
              _refreshItems();
            },
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
