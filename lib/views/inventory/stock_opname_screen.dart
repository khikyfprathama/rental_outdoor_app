import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/database_service.dart';

class StockOpnameScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const StockOpnameScreen({super.key, required this.databaseService});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  late Future<List<Item>> _itemsFuture;
  final Map<int, int> _updatedStocks = {}; // itemId -> physicalStock
  final Set<int> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = widget.databaseService.getAllItems();
    });
  }

  void _saveOpname() async {
    int updatedCount = 0;
    final items = await _itemsFuture;
    for (var entry in _updatedStocks.entries) {
      // Find item
      final itemIndex = items.indexWhere((i) => i.id == entry.key);
      if (itemIndex != -1) {
        final item = items[itemIndex];
        // Only update if physical stock is different from system stock
        if (item.stock != entry.value) {
          item.stock = entry.value;
          await widget.databaseService.saveItem(item);
          updatedCount++;
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedCount > 0 
            ? 'BERHASIL MEMPERBARUI STOK $updatedCount BARANG' 
            : 'STOK SESUAI, TIDAK ADA PERUBAHAN TERSIMPAN'),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasChanges = _updatedStocks.keys.any((key) => _checkedItems.contains(key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('STOCK OPNAME', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'SIMPAN',
            onPressed: !hasChanges ? null : _saveOpname,
          )
        ],
      ),
      body: FutureBuilder<List<Item>>(
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
                  Icon(Icons.checklist_rtl_rounded, size: 80, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('Belum ada barang untuk diaudit.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemBuilder: (context, index) {
              final item = items[index];
              final isChecked = _checkedItems.contains(item.id);
              final physicalStock = _updatedStocks[item.id] ?? item.stock;
              final diff = physicalStock - item.stock;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isChecked 
                        ? theme.colorScheme.primary.withAlpha(120)
                        : theme.colorScheme.outline.withAlpha(isDark ? 80 : 150),
                    width: isChecked ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox
                      Checkbox(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _checkedItems.add(item.id!);
                              _updatedStocks[item.id!] = item.stock; // Default to system stock
                            } else {
                              _checkedItems.remove(item.id!);
                              _updatedStocks.remove(item.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'KATEGORI: ${item.category.toUpperCase()}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // System Stock Label
                            Row(
                              children: [
                                const Text('Stok Sistem: ', style: TextStyle(fontSize: 12)),
                                Text('${item.stock}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            
                            // Edit area when checked
                            if (isChecked) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Stok Fisik: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  // Counter Decrement
                                  _buildCounterButton(Icons.remove, () {
                                    if (physicalStock > 0) {
                                      setState(() {
                                        _updatedStocks[item.id!] = physicalStock - 1;
                                      });
                                    }
                                  }, theme),
                                  // Counter Value
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      '$physicalStock',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Counter Increment
                                  _buildCounterButton(Icons.add, () {
                                    setState(() {
                                      _updatedStocks[item.id!] = physicalStock + 1;
                                    });
                                  }, theme),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Discrepancy Badge
                              Row(
                                children: [
                                  const Text('Status: ', style: TextStyle(fontSize: 12)),
                                  _buildDiffBadge(diff, theme),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 0 : 8),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: !hasChanges ? null : _saveOpname,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded),
                SizedBox(width: 8),
                Text('SIMPAN PERUBAHAN STOK', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed, ThemeData theme) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildDiffBadge(int diff, ThemeData theme) {
    Color badgeColor;
    Color textColor;
    String label;

    if (diff == 0) {
      badgeColor = Colors.green.withAlpha(35);
      textColor = Colors.green[800]!;
      label = 'Sesuai';
    } else if (diff < 0) {
      badgeColor = theme.colorScheme.errorContainer.withAlpha(150);
      textColor = theme.colorScheme.onErrorContainer;
      label = 'Selisih $diff (Kurang)';
    } else {
      badgeColor = Colors.orange.withAlpha(35);
      textColor = Colors.orange[800]!;
      label = 'Selisih +$diff (Lebih)';
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
}
