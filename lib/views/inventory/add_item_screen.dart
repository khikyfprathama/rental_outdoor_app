import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../models/item.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';
import 'manage_categories_screen.dart';

class AddItemScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final Item? itemToEdit; // Jika ada, berarti mode EDIT

  const AddItemScreen({super.key, required this.databaseService, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedCategory;
  String _selectedType = 'RENT'; // Default RENT
  List<String> _categories = [];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _priceController.text = CurrencyInputFormatter.format(widget.itemToEdit!.pricePerDay);
      _stockController.text = widget.itemToEdit!.stock.toString();
      _selectedCategory = widget.itemToEdit!.category;
      _selectedType = widget.itemToEdit!.type;
      _imagePath = widget.itemToEdit!.imagePath;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await widget.databaseService.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: ${e.toString().toUpperCase()}')),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'PILIH SUMBER FOTO',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
              title: const Text('KAMERA'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
              title: const Text('GALERI'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TAMBAH KATEGORI'),
        content: TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'NAMA KATEGORI',
            hintText: 'CONTOH: TENDA, TAS, DLL',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim().toUpperCase();
              if (text.isNotEmpty) {
                await widget.databaseService.addCategory(text);
                await _loadCategories();
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PILIH KATEGORI TERLEBIH DAHULU'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final newItem = Item(
        id: widget.itemToEdit?.id,
        name: _nameController.text.trim().toUpperCase(),
        category: _selectedCategory!,
        pricePerDay: CurrencyInputFormatter.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        imagePath: _imagePath,
        createdAt: widget.itemToEdit?.createdAt ?? DateTime.now(),
        type: _selectedType,
      );

      await widget.databaseService.saveItem(newItem);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemToEdit == null ? 'TAMBAH BARANG' : 'EDIT BARANG',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PHOTO PICKER CARD
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(isDark ? 80 : 150),
                      width: 1.5,
                    ),
                  ),
                  child: _imagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_a_photo_rounded, size: 36, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'TAMBAHKAN FOTO BARANG',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap untuk mengambil foto dari kamera/galeri',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _imagePath!.startsWith('assets/')
                                    ? Image.asset(_imagePath!, fit: BoxFit.cover)
                                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // TIPE PRODUK (Segmented Button M3)
              Text(
                'TIPE PRODUK',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    selectedBackgroundColor: theme.colorScheme.primaryContainer,
                    selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'RENT',
                      label: Text('DISEWAKAN'),
                      icon: Icon(Icons.autorenew_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'SELL',
                      label: Text('DIJUAL'),
                      icon: Icon(Icons.sell_outlined),
                    ),
                  ],
                  selected: <String>{_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // NAMA BARANG
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'NAMA BARANG',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (value) => value!.isEmpty ? 'Nama barang tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              
              // KATEGORI & ACTIONS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'KATEGORI',
                        prefixIcon: Icon(Icons.grid_view_rounded),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                      validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Kelola kategori button
                  Container(
                    height: 56, // Matches standard form input height
                    margin: const EdgeInsets.only(top: 0),
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageCategoriesScreen(databaseService: widget.databaseService),
                          ),
                        );
                        _loadCategories();
                      },
                      icon: const Icon(Icons.settings_outlined),
                      color: theme.colorScheme.primary,
                      tooltip: 'KELOLA KATEGORI',
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Tambah kategori button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_circle_outline),
                      color: theme.colorScheme.primary,
                      tooltip: 'TAMBAH KATEGORI BARU',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // HARGA SEWA / JUAL
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: _selectedType == 'RENT' ? 'HARGA SEWA / HARI' : 'HARGA JUAL',
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                validator: (value) => value!.isEmpty ? 'Harga tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              
              // STOK
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'STOK AWAL',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value!.isEmpty ? 'Stok tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),
              
              // BUTTON SIMPAN
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: theme.colorScheme.primary.withAlpha(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded),
                    const SizedBox(width: 8),
                    Text(
                      widget.itemToEdit == null ? 'SIMPAN BARANG' : 'UPDATE BARANG',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
