import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';

class HistoryScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const HistoryScreen({super.key, required this.databaseService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Rental>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = widget.databaseService.getAllRentals(status: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIWAYAT TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Rental>>(
        future: _historyFuture,
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
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final rental = history[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 150)),
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
                    onTap: () => _showRentalDetails(rental),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.primary.withAlpha(20),
                                    child: Icon(Icons.person_outline_rounded, size: 16, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    rental.customerName.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.withAlpha(60)),
                                ),
                                child: const Text(
                                  'SELESAI',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 0.8),
                          
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Barang: ${_getGroupedItemsText(rental.items)}',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.event_available_rounded, size: 16, color: Colors.orange[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Selesai pada: ${DateFormat('dd MMM yyyy').format(rental.endDate)}',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 0.8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Transaksi', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                'Rp ${CurrencyInputFormatter.format(rental.totalPrice)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 15,
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
            },
          );
        },
      ),
    );
  }

  String _getGroupedItemsText(List<dynamic> items) {
    if (items.isEmpty) return 'Tidak ada barang';
    final Map<String, int> counts = {};
    for (var item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}${e.value > 1 ? " (x${e.value})" : ""}').join(", ");
  }

  int _calculateDays(Rental rental) {
    int days = rental.endDate.difference(rental.startDate).inDays;
    return days <= 0 ? 1 : days;
  }

  void _showRentalDetails(Rental rental) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Map<String, int> itemCounts = {};
    for (var item in rental.items) {
      itemCounts[item.name] = (itemCounts[item.name] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'RIWAYAT STRUK',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 150)),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('Nama Pelanggan', rental.customerName, theme, isBoldValue: true),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInvoiceRow('Status', 'Selesai & Kembali', theme, customColor: Colors.green[800]),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInvoiceRow('Tanggal Pinjam', DateFormat('dd MMMM yyyy').format(rental.startDate), theme),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInvoiceRow('Tanggal Kembali', DateFormat('dd MMMM yyyy').format(rental.endDate), theme),
                    const Divider(height: 20, thickness: 0.5),
                    _buildInvoiceRow('Durasi Penyewaan', '${_calculateDays(rental)} Hari', theme),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RINCIAN BARANG',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              ...itemCounts.entries.map((entry) {
                final item = rental.items.firstWhere((i) => i.name == entry.key);
                final isRental = item.type == 'RENT';
                final totalDays = isRental ? _calculateDays(rental) : 1;
                final lineTotal = item.pricePerDay * totalDays * entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer.withAlpha(120) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withAlpha(100)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isRental ? Colors.blue.withAlpha(25) : Colors.purple.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isRental ? Colors.blue.withAlpha(60) : Colors.purple.withAlpha(60)),
                        ),
                        child: Text(
                          isRental ? 'RENT' : 'SELL',
                          style: TextStyle(
                            fontSize: 9, 
                            fontWeight: FontWeight.bold,
                            color: isRental ? Colors.blue[800] : Colors.purple[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(), 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.value} unit x Rp ${CurrencyInputFormatter.format(item.pricePerDay)}${isRental ? "/hari" : ""}',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${CurrencyInputFormatter.format(lineTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL TRANSAKSI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Rp ${CurrencyInputFormatter.format(rental.totalPrice)}',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w900, 
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('TUTUP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, ThemeData theme, {bool isBoldValue = false, Color? customColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
            color: customColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
