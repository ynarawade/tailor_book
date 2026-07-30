// import 'package:atelier/models/customer.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';

// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   static Database? _database;

//   DatabaseHelper._internal();

//   factory DatabaseHelper() => _instance;

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'tailor_app.db');
//     return await openDatabase(path, version: 2, onCreate: _onCreate);
//   }

//   Future<void> _onCreate(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE customers (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL,
//         mobile_number TEXT NOT NULL,
//         created_at TEXT NOT NULL
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE images (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         customer_id INTEGER NOT NULL,
//         image_path TEXT NOT NULL,
//         image_type TEXT NOT NULL,
//         created_at TEXT NOT NULL,
//         FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
//       )
//     ''');
//     await db.execute(
//       'CREATE INDEX idx_images_customer_id ON images(customer_id)',
//     );
//   }

//   Future<int> insertCustomer(Map<String, dynamic> customer) async {
//     final db = await database;
//     return await db.insert('customers', customer);
//   }

//   Future<int> insertImage(Map<String, dynamic> image) async {
//     final db = await database;
//     return await db.insert('images', image);
//   }

//   Future<List<Map<String, dynamic>>> getAllCustomers() async {
//     final db = await database;
//     return await db.rawQuery('''
//       SELECT c.*, COUNT(i.id) as image_count
//       FROM customers c
//       LEFT JOIN images i ON c.id = i.customer_id
//       GROUP BY c.id
//       ORDER BY c.created_at DESC
//     ''');
//   }

//   Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
//     final db = await database;
//     return await db.rawQuery(
//       '''
//       SELECT c.*, COUNT(i.id) as image_count
//       FROM customers c
//       LEFT JOIN images i ON c.id = i.customer_id
//       WHERE c.name LIKE ? OR c.mobile_number LIKE ?
//       GROUP BY c.id
//       ORDER BY c.created_at DESC
//       ''',
//       ['%$query%', '%$query%'],
//     );
//   }

//   Future<List<Map<String, dynamic>>> getCustomerImages(int customerId) async {
//     final db = await database;
//     return await db.query(
//       'images',
//       where: 'customer_id = ?',
//       whereArgs: [customerId],
//       orderBy: 'created_at DESC',
//     );
//   }

//   Future<int> deleteCustomer(int id) async {
//     final db = await database;
//     await db.delete('images', where: 'customer_id = ?', whereArgs: [id]);
//     return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<Map<String, dynamic>?> getCustomer(int id) async {
//     final db = await database;
//     final result = await db.query(
//       'customers',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     return result.isNotEmpty ? result.first : null;
//   }

//   /// NEW — used by BackupService to check if a customer exists before import.
//   Future<Map<String, dynamic>?> getCustomerByMobile(String mobile) async {
//     final db = await database;
//     final result = await db.query(
//       'customers',
//       where: 'mobile_number = ?',
//       whereArgs: [mobile],
//       limit: 1,
//     );
//     return result.isNotEmpty ? result.first : null;
//   }

//   Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
//     final db = await database;
//     return await db.update(
//       'customers',
//       customer,
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }

//   Future<int> deleteImage(int imageId) async {
//     final db = await database;
//     return await db.delete('images', where: 'id = ?', whereArgs: [imageId]);
//   }

//   // Fetch clients in batches (default: 50 at a time)
//   Future<List<Customer>> getCustomersPaginated({
//     required int limit,
//     required int offset,
//   }) async {
//     final db = await database;

//     // Gets count of attached images per customer along with customer details
//     final List<Map<String, dynamic>> maps = await db.rawQuery(
//       '''
//     SELECT c.*, COUNT(i.id) as imageCount
//     FROM customers c
//     LEFT JOIN images i ON c.id = i.customer_id
//     GROUP BY c.id
//     ORDER BY c.id DESC
//     LIMIT ? OFFSET ?
//   ''',
//       [limit, offset],
//     );

//     return maps.map((map) => Customer.fromMap(map)).toList();
//   }
// }

// lib/helpers/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tailor_app.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile_number TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        image_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_images_customer_id ON images(customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_mobile ON customers(mobile_number)',
    );
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('customers', customer);
  }

  Future<int> insertImage(Map<String, dynamic> image) async {
    final db = await database;
    return await db.insert('images', image);
  }

  /// Needed for backup service and settings page stats
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, COUNT(i.id) as image_count
      FROM customers c
      LEFT JOIN images i ON c.id = i.customer_id
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''');
  }

  /// Returns total count of records matching optional search query
  Future<int> getTotalCustomerCount({String? searchQuery}) async {
    final db = await database;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanQuery = '%${searchQuery.trim()}%';
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers WHERE name LIKE ? OR mobile_number LIKE ?',
        [cleanQuery, cleanQuery],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Unified paginated fetch that handles both browsing and searching
  Future<List<Map<String, dynamic>>> getCustomersPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final cleanQuery = '%${searchQuery.trim()}%';
      return await db.rawQuery(
        '''
        SELECT c.*, COUNT(i.id) as image_count
        FROM customers c
        LEFT JOIN images i ON c.id = i.customer_id
        WHERE c.name LIKE ? OR c.mobile_number LIKE ?
        GROUP BY c.id
        ORDER BY c.created_at DESC
        LIMIT ? OFFSET ?
      ''',
        [cleanQuery, cleanQuery, limit, offset],
      );
    }

    return await db.rawQuery(
      '''
      SELECT c.*, COUNT(i.id) as image_count
      FROM customers c
      LEFT JOIN images i ON c.id = i.customer_id
      GROUP BY c.id
      ORDER BY c.created_at DESC
      LIMIT ? OFFSET ?
    ''',
      [limit, offset],
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerImages(int customerId) async {
    final db = await database;
    return await db.query(
      'images',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteImage(int imageId) async {
    final db = await database;
    return await db.delete('images', where: 'id = ?', whereArgs: [imageId]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('images', where: 'customer_id = ?', whereArgs: [id]);
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getCustomerByMobile(String mobile) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'mobile_number = ?',
      whereArgs: [mobile],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
