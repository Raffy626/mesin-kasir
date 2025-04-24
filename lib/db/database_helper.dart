import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'kasir.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity INTEGER,
            price INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE daily_income(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            amount INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE daily_income(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT,
              amount INTEGER
            )
          ''');
        }
      },
    );
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products', 
      product.toMap(), 
      where: 'id = ?', 
      whereArgs: [product.id]
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllProducts() async {
    final db = await database;
    await db.delete('products');
  }

  Future<void> addDailyIncome(int amount) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> result = await db.query(
      'daily_income',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (result.isEmpty) {
      await db.insert('daily_income', {
        'date': today,
        'amount': amount,
      });
    } else {
      await db.update(
        'daily_income',
        {'amount': result.first['amount'] + amount},
        where: 'date = ?',
        whereArgs: [today],
      );
    }
  }

  Future<int> getTodayIncome() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> result = await db.query(
      'daily_income',
      where: 'date = ?',
      whereArgs: [today],
    );

    return result.isEmpty ? 0 : result.first['amount'] as int;
  }

  Future<void> clearTodayIncome() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await db.delete(
      'daily_income',
      where: 'date = ?',
      whereArgs: [today],
    );
  }

  Future<void> clearOldDailyIncome() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await db.delete(
      'daily_income',
      where: 'date != ?',
      whereArgs: [today],
    );
  }

  Future<int> getTransactionCount() async {
  final db = await database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM income');
  return Sqflite.firstIntValue(result) ?? 0;
  }
}