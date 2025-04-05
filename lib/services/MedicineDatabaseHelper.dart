import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/services.dart';

class MedicineDatabaseHelper {
  static const _databaseName = "MedicineDatabase.db";
  static const _databaseVersion = 2;
  static const table = 'medicines';
  static const columnId = '_id';
  static const columnName = 'name';

  // Make this a singleton class
  MedicineDatabaseHelper._privateConstructor();
  static final MedicineDatabaseHelper instance = MedicineDatabaseHelper._privateConstructor();

  static Database? _database;
  static bool _isInitializing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for initialization to complete
      }
      return _database!;
    }

    _isInitializing = true;
    _database = await _initDatabase();
    _isInitializing = false;
    return _database!;
  }

  // Open the database and create it if it doesn't exist
  Future<Database> _initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    print('Database path: $path');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: (db) {
        print('Database opened successfully');
      },
    );
  }



  // SQL code to create the database table
  static Future _onCreate(Database db, int version) async {
    print(" MedicineDatabaseHelper:  _onCreate method is being called!");
    await db.execute('''
    CREATE TABLE $table (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnName TEXT NOT NULL UNIQUE
    )
  ''');
    print("MedicineDatabaseHelper:  Table created successfully.");
    print(" MedicineDatabaseHelper:  Calling _populateDatabaseWithInitialData from _onCreate.");
    await MedicineDatabaseHelper.instance._populateDatabaseWithInitialData(db);
    print(" MedicineDatabaseHelper:  Finished _populateDatabaseWithInitialData from _onCreate.");
    // Move debugDatabase to be awaited here as well
    await MedicineDatabaseHelper.instance.debugDatabase();
  }

  // Method to populate the database from an asset file
  Future<void> _populateDatabaseWithInitialData(Database db) async {
    print(" MedicineDatabaseHelper:  _populateDatabaseWithInitialData called.");
    try {
      print(" MedicineDatabaseHelper:  Attempting to load assets/medicines.json");
      String jsonString = await rootBundle.loadString('assets/medicines.json');
      print(" MedicineDatabaseHelper: Successfully loaded assets/medicines.json. Length: ${jsonString.length}");
      List<dynamic> jsonData = json.decode(jsonString);
      print(" MedicineDatabaseHelper:  Loaded JSON data: ${jsonData.length} medicines.");

      if (jsonData.isNotEmpty) {
        Batch batch = db.batch();
        int insertedCount = 0;
        for (var itemName in jsonData) { // Iterate through the list of strings
          if (itemName is String && itemName.isNotEmpty) {
            batch.insert(MedicineDatabaseHelper.table, {'name': itemName});
            insertedCount++;
          } else {
            print("MedicineDatabaseHelper:  Skipping invalid JSON item: $itemName");
          }
        }
        await batch.commit();
        print(" MedicineDatabaseHelper: Database populated with $insertedCount medicines from JSON.");
      } else {
        print(" MedicineDatabaseHelper:  JSON data is empty. No medicines to populate.");
      }
    } catch (e) {
      print(" MedicineDatabaseHelper:  Error populating database: $e");
      print(" MedicineDatabaseHelper:  Error details: $e");
    }
    print(" MedicineDatabaseHelper:  _populateDatabaseWithInitialData finished.");
  }



  Future<void> debugDatabase() async {
    print(" MedicineDatabaseHelper:  debugDatabase called.");
    try {
      Database db = _database!;
      List<Map<String, dynamic>> data = await db.query(table, limit: 5); // Limit to a few rows
      print(" MedicineDatabaseHelper:  First few medicines: $data");
      print(" MedicineDatabaseHelper:  debugDatabase finished.");
    } catch (e) {
      print(" MedicineDatabaseHelper:  Error in debugDatabase: $e");
    }
  }


  // Method to query medicines for autocomplete
  Future<List<String>> getSuggestions(String query) async {
    print(" MedicineDatabaseHelper:  getSuggestions called with query: $query");
    Database db = await instance.database;
    if (query.isEmpty) return [];

    final List<Map<String, dynamic>> results = await db.rawQuery(
        "SELECT name FROM $table WHERE name LIKE ? ORDER BY name ASC",
        ['$query%']
    );

    return results.map((row) => row['name'] as String).toList();
  }



  // Optional: Method to add a new medicine to the database
  Future<int> insert(String name) async {
    Database db = await instance.database;
    return await db.insert(table, {columnName: name},
        conflictAlgorithm: ConflictAlgorithm.ignore); // Avoid duplicates
  }

  // Optional: Method to get all medicines (for debugging or other purposes)
  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    Database db = await instance.database;
    return await db.query(table);
  }



}