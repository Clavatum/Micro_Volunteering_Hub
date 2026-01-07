import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UserLocalDb{
  static Database? _db;

  static Future<Database> get database async{
    if(_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  } 

  static Future<Database> _initDatabase() async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "database.db");

    return await openDatabase(path, version: 9, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async{
    //Create user table
    await db.execute('''
      CREATE TABLE user(
        id TEXT PRIMARY KEY,
        user_name TEXT,
        user_mail TEXT,
        photo_iscustom INTEGER NOT NULL DEFAULT 0,
        photo_url TEXT,
        photo_url_custom TEXT,
        photo_path TEXT,
        photo_path_custom TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE app_state(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async{
    if (oldVersion < 9){
      await db.execute('DROP TABLE user');
      await db.execute('''
        CREATE TABLE user(
          id TEXT PRIMARY KEY,
          user_name TEXT,
          user_mail TEXT,
          photo_iscustom INTEGER NOT NULL DEFAULT 0,
          photo_url TEXT,
          photo_url_custom TEXT,
          photo_path TEXT,
          photo_path_custom TEXT,
          updated_at INTEGER
        )
      ''');
    }
  }

  static Future<void> saveUserAndActivate(Map<String, dynamic> user) async{
    final db = await database;
    await db.insert(
      "user",{
        "id": user["id"],
        "user_name": user["user_name"],
        "user_mail": user["user_mail"],
        "photo_iscustom": (user["photo_iscustom"] == true) ? 1 : 0,
        "photo_url": user["photo_url"],
        "photo_url_custom": user["photo_url_custom"],
        "photo_path": user["photo_path"],
        "photo_path_custom": user["photo_path_custom"],
        "updated_at": user["updated_at"] ?? DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert("app_state",{
      "key": "current_user_id", "value": user["id"],
    },
    conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<void> setCurrentUser(String userId) async{
    final db = await database;
    await db.insert(
      "app_state",
      {"key": "current_user_id", "value": userId},
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<String?> getCurrentUserId() async{
    final db = await database;
    final result = await db.query("app_state",
      where: "key = ?",
      whereArgs: ["current_user_id"],
      limit: 1
    );

    if (result.isEmpty) return null;
    return result.first["value"] as String;
  }

  static Future<Map<String,dynamic>?> getActiveUser() async{
    final db = await database;
    final userId = await getCurrentUserId();

    if (userId == null) return null;

    final result = await db.query("user",
      where: "id = ?",
      whereArgs: [userId],
      limit: 1
    );
  if (result.isNotEmpty) {
    final m = Map<String, dynamic>.from(result.first);
    m["photo_iscustom"] = m["photo_iscustom"] == 1;
    return m;
  }

  return null;
  }

  static Future<void> updateAvatarState(bool isCustom) async{
    final db = await database;
    final userId = await getCurrentUserId();
    await db.update(
      'user',
      {
        'photo_iscustom': isCustom ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [userId],
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<bool> getCurrentAvatarState() async{
    final result = await getActiveUser();
    if (result == null || result["photo_iscustom"] == null){
      return false;
    }
    return (result["photo_iscustom"] == 1) ? true : false;
  }
}