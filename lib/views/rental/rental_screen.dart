import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import 'add_rental_screen.dart';

class RentalScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const RentalScreen({super.key, required this.databaseService});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Rental>> _activeRentalsFuture;
  late Future<List<Rental>> _historyRentalsFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshRentals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshRentals() {
    setState(() {
      _activeRentalsFuture = widget.databaseService.getAllRentals(status: 0);
      _historyRentalsFuture = widget.databaseService.getAllRentals(status: 1);
    });
  }

  List<Rental> _filterRentals(List<Rental> rentals) {
    if (_searchQuery.isEmpty) return rentals;
    return rentals.where((rental) {
      final nameMatch = rental.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final itemMatch = rental.items.any((item) => 
        item.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      return nameMatch || itemMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAJEMEN RENTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari pelanggan atau barang...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: isDark ? theme.colorScheme.surfaceContainerHighest.withAlpha(100) : Colors.white,
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
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'AKTIF'),
                  Tab(text: 'RIWAYAT'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRentalList(_activeRentalsFuture, true),
          _buildRentalList(_historyRentalsFuture, false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRentalScreen(databaseService: widget.databaseService),
            ),
          );
          _refreshRentals();
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('RENTAL BARU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRentalList(Future<List<Rental>> future, bool isActive) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Rental>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final rentals = _filterRentals(snapshot.data ?? []);
        
        if (rentals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withAlpha(100)),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Tidak ada data rental',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: rentals.length,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemBuilder: (context, index) {
            final rental = rentals[index];
            return _buildRentalCard(rental, isActive, theme);
          },
        );
      },
    );
  }

  Widget _buildRentalCard(Rental rental, bool isActive, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          onTap: () => _showRentalDetails(rental, isActive),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary.withAlpha(25),
                            child: Icon(Icons.person_rounded, size: 16, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rental.customerName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(isActive, theme),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                
                // Items info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.checklist_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getGroupedItemsText(rental.items),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant, 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Dates info
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd MMM').format(rental.startDate)} - ${DateFormat('dd MMM yyyy').format(rental.endDate)}',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_calculateDays(rental)} Hari',
                        style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                
                // Payment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${CurrencyInputFormatter.format(rental.totalPrice)}',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w900, 
                        color: theme.colorScheme.primary,
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

  Widget _buildStatusBadge(bool isActive, ThemeData theme) {
    final statusColor = isActive ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withAlpha(80), width: 1),
      ),
      child: Text(
        isActive ? 'DISEWA' : 'SELESAI',
        style: TextStyle(
          color: statusColor[800],
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
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

  void _showRentalDetails(Rental rental, bool isActive) {
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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
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
              
              // Title Invoice
              Center(
                child: Text(
                  'STRUK TRANSAKSI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Receipt Container Info
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
                    _buildInvoiceRow('Status Peminjaman', isActive ? 'Aktif (Disewa)' : 'Selesai Dikembalikan', theme, 
                        customColor: isActive ? Colors.orange[800] : Colors.green[800]),
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
              
              // Invoice Items Table title
              Text(
                'DAFTAR DETAIL BARANG',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              
              // Items Invoice list
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
                      // Badge
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
                      
                      // Details name
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
                      
                      // Price Line
                      Text(
                        'Rp ${CurrencyInputFormatter.format(lineTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              
              // Total invoice box
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
                      'TOTAL PEMBAYARAN',
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
              const SizedBox(height: 36),
              
              // Action buttons
              if (isActive) ...[
                ElevatedButton(
                  onPressed: () async {
                    await widget.databaseService.updateRentalStatus(rental.id!, 1);
                    for (var entry in itemCounts.entries) {
                      final item = rental.items.firstWhere((i) => i.name == entry.key);
                      if (item.type == 'RENT') {
                        item.stock += entry.value;
                        await widget.databaseService.saveItem(item);
                      }
                    }
                    if (mounted) Navigator.pop(context);
                    _refreshRentals();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 8),
                      Text('SELESAIKAN TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('TUTUP STRUK', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
