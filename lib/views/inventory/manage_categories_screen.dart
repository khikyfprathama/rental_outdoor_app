import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final DatabaseService databaseService;
  const ManageCategoriesScreen({super.key, required this.databaseService});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = widget.databaseService.getAllCategories();
    });
  }

  void _showCategoryDialog({String? oldName}) {
    final controller = TextEditingController(text: oldName);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          oldName == null ? 'TAMBAH KATEGORI' : 'EDIT KATEGORI',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'NAMA KATEGORI',
            hintText: 'CONTOH: JAKET, SEPATU',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim().toUpperCase();
              if (text.isNotEmpty) {
                if (oldName == null) {
                  await widget.databaseService.addCategory(text);
                } else {
                  await widget.databaseService.updateCategory(oldName, text);
                }
                _refreshCategories();
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "$name"? Semua barang dengan kategori ini tetap ada namun kategorinya tidak akan otomatis berubah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('BATAL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.databaseService.deleteCategory(name);
      _refreshCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KELOLA KATEGORI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
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
                  Icon(Icons.label_off_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
                  const SizedBox(height: 16),
                  const Text('Belum ada kategori.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 150)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer.withAlpha(120),
                    child: Icon(Icons.label_rounded, color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(
                    cat,
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: Colors.blue[600],
                        onPressed: () => _showCategoryDialog(oldName: cat),
                        tooltip: 'Edit Kategori',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: theme.colorScheme.error,
                        onPressed: () => _deleteCategory(cat),
                        tooltip: 'Hapus Kategori',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('TAMBAH KATEGORI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
