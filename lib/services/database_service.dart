import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/rental.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('commithike.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add type column to items table
      await db.execute('ALTER TABLE items ADD COLUMN type TEXT DEFAULT "RENT"');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        pricePerDay REAL NOT NULL,
        stock INTEGER NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        type TEXT DEFAULT "RENT"
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rentals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        totalPrice REAL NOT NULL,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rental_items (
        rentalId INTEGER NOT NULL,
        itemId INTEGER NOT NULL,
        FOREIGN KEY (rentalId) REFERENCES rentals (id) ON DELETE CASCADE,
        FOREIGN KEY (itemId) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');
  }

  // ITEM OPERATIONS
  Future<int> saveItem(Item item) async {
    final db = await instance.database;
    if (item.id != null) {
      return await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    } else {
      return await db.insert('items', item.toMap());
    }
  }

  Future<List<Item>> getAllItems({String? category, String? type}) async {
    final db = await instance.database;
    String? where;
    List<dynamic>? whereArgs;

    if (category != null && type != null) {
      where = 'category = ? AND type = ?';
      whereArgs = [category, type];
    } else if (category != null) {
      where = 'category = ?';
      whereArgs = [category];
    } else if (type != null) {
      where = 'type = ?';
      whereArgs = [type];
    }

    final result = await db.query('items', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // RENTAL OPERATIONS
  Future<void> saveRental(Rental rental) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final rentalId = await txn.insert('rentals', rental.toMap());
      for (var item in rental.items) {
        await txn.insert('rental_items', {
          'rentalId': rentalId,
          'itemId': item.id,
        });
      }
    });
  }

  Future<List<Rental>> getAllRentals({int? status}) async {
    final db = await instance.database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    }

    final result = await db.query('rentals', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
    
    List<Rental> rentals = [];
    for (var row in result) {
      final rentalId = row['id'] as int;
      final itemIdsResult = await db.rawQuery('''
        SELECT items.* FROM items
        INNER JOIN rental_items ON items.id = rental_items.itemId
        WHERE rental_items.rentalId = ?
      ''', [rentalId]);
      
      final items = itemIdsResult.map((json) => Item.fromMap(json)).toList();
      rentals.add(Rental.fromMap(row, items: items));
    }
    return rentals;
  }

  Future<void> updateRentalStatus(int id, int status) async {
    final db = await instance.database;
    await db.update('rentals', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  // DASHBOARD STATS
  Future<Map<String, dynamic>> getSummaryStats() async {
    final db = await instance.database;
    
    final totalItemsResult = await db.rawQuery('SELECT COUNT(*) as count FROM items');
    final totalRentalsActiveResult = await db.rawQuery('SELECT COUNT(*) as count FROM rentals WHERE status = 0');
    final totalRevenueResult = await db.rawQuery('SELECT SUM(totalPrice) as total FROM rentals WHERE status = 1');

    return {
      'totalItems': totalItemsResult.first['count'] ?? 0,
      'activeRentals': totalRentalsActiveResult.first['count'] ?? 0,
      'totalRevenue': totalRevenueResult.first['total'] ?? 0.0,
    };
  }

  // CATEGORY OPERATIONS
  Future<int> addCategory(String name) async {
    final db = await instance.database;
    return await db.insert('categories', {'name': name.toUpperCase()});
  }

  Future<int> updateCategory(String oldName, String newName) async {
    final db = await instance.database;
    return await db.update('categories', {'name': newName.toUpperCase()}, where: 'name = ?', whereArgs: [oldName]);
  }

  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => json['name'] as String).toList();
  }

  Future<void> deleteCategory(String name) async {
    final db = await instance.database;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }
}
