import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../inventory/add_item_screen.dart';
import '../rental/add_rental_screen.dart';
import '../inventory/stock_opname_screen.dart';

class DashboardScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const DashboardScreen({super.key, required this.databaseService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = widget.databaseService.getSummaryStats();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore ⛅';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ??
              {
                'totalItems': 0,
                'activeRentals': 0,
                'totalRevenue': 0.0,
              };

          return RefreshIndicator(
            onRefresh: () async {
              _loadStats();
            },
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, theme),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome / Greeting Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [theme.colorScheme.primaryContainer.withAlpha(150), theme.colorScheme.surface]
                                  : [theme.colorScheme.primary.withAlpha(25), theme.colorScheme.primary.withAlpha(5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(isDark ? 80 : 30),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'CommitHike Manager',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kelola inventori dan rental outdoor Anda dengan efisien.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader(context, 'RINGKASAN PERFORMA'),
                        const SizedBox(height: 16),
                        
                        // GRID STATS
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                          children: [
                            _buildModernStatCard(
                              context,
                              'TOTAL BARANG',
                              stats['totalItems'].toString(),
                              Icons.inventory_2_rounded,
                              isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [Colors.white, Colors.white],
                              theme.colorScheme.primary,
                            ),
                            _buildModernStatCard(
                              context,
                              'SEWA AKTIF',
                              stats['activeRentals'].toString(),
                              Icons.shopping_bag_rounded,
                              isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [Colors.white, Colors.white],
                              theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRevenueCard(
                          context,
                          'TOTAL PENDAPATAN',
                          currencyFormat.format(stats['totalRevenue']),
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 36),
                        _buildSectionHeader(context, 'MENU CEPAT'),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Text(
          'COMMITHIKE',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2.0,
            color: theme.colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withAlpha(20),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.landscape_rounded,
                  size: 160,
                  color: theme.colorScheme.primary.withAlpha(isDark ? 15 : 10),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  themeNotifier.value =
                      mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Icon(
                    mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<ThemeMode>(mode),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 12,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> cardColors,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(isDark ? 50 : 150),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                icon,
                size: 70,
                color: accentColor.withAlpha(isDark ? 20 : 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    String title,
    String value,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(isDark ? 50 : 150),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'BARANG BARU',
                'Tambah item outdoor',
                Icons.add_circle_outline_rounded,
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                'SEWA BARU',
                'Buat transaksi sewa',
                Icons.shopping_cart_checkout_rounded,
                theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          'STOCK OPNAME',
          'Audit dan checklist stok fisik barang',
          Icons.fact_check_rounded,
          Colors.orange,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    String description,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? color.withAlpha(20) : color.withAlpha(10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            Widget? screen;
            if (label == 'BARANG BARU') screen = AddItemScreen(databaseService: widget.databaseService);
            if (label == 'SEWA BARU') screen = AddRentalScreen(databaseService: widget.databaseService);
            if (label == 'STOCK OPNAME') screen = StockOpnameScreen(databaseService: widget.databaseService);
            
            if (screen != null) {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
              if (result == true) _loadStats();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isFullWidth ? 20 : 24, horizontal: 20),
            child: isFullWidth
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

