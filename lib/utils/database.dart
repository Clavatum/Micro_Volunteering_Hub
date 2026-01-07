import 'dart:convert';

import 'package:micro_volunteering_hub/models/event.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:latlong2/latlong.dart';
import 'package:micro_volunteering_hub/models/event.dart';

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

    return await openDatabase(path, version: 15, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
        user_attended_events TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE app_state(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE chats(
        key TEXT PRIMARY KEY,
        event_id TEXT,
        text TEXT,
        sender_id TEXT,
        sender_name TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE events(
        event_id TEXT PRIMARY KEY,
        title TEXT,
        desc TEXT,
        user_id TEXT,
        host_name TEXT,
        time INTEGER,
        capacity INTEGER,
        instant_join INTEGER,
        participant_count INTEGER,
        image_url TEXT,
        tags TEXT,
        lat REAL,
        lon REAL,
        is_close INTEGER,
        distance_to_user INTEGER,
        attendants TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async{
    if (oldVersion < 15){
      await db.execute('DROP TABLE IF EXISTS user');
      await db.execute('DROP TABLE IF EXISTS chats');
      await db.execute('DROP TABLE IF EXISTS events');
      await db.execute('DROP TABLE IF EXISTS app_state');
      await db.execute('''
        CREATE TABLE app_state(
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
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
          user_attended_events TEXT,
          updated_at INTEGER
        )
      ''');
    await db.execute('''
      CREATE TABLE chats(
        key TEXT PRIMARY KEY,
        event_id TEXT,
        text TEXT,
        sender_id TEXT,
        sender_name TEXT,
        created_at INTEGER
      )
    ''');
    }
    await db.execute('''
      CREATE TABLE events(
        event_id TEXT PRIMARY KEY,
        title TEXT,
        desc TEXT,
        user_id TEXT,
        host_name TEXT,
        time INTEGER,
        capacity INTEGER,
        instant_join INTEGER,
        participant_count INTEGER,
        image_url TEXT,
        tags TEXT,
        lat REAL,
        lon REAL,
        is_close INTEGER,
        distance_to_user INTEGER,
        attendants TEXT
      )
    ''');
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
        "user_attended_events": jsonEncode(user["user_attended_events"]),
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
    m["user_attended_events"] = List<String>.from(jsonDecode(m["user_attended_events"]));
    print(m["user_attended_events"]);
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

  static Future<void> storeMessage(String key, String eventID, String message, String senderID, String senderName, int dateSinceEpoch) async{
    final db = await database;
    await db.insert(
      "chats",
      {"key": key,
        "event_id": eventID,
        "text": message,
        "sender_id": senderID,
        "sender_name": senderName,
        "created_at": dateSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<List<Map<String, dynamic>>> getMessages(String eventID) async {
    final db = await database;

    final result = await db.query(
      "chats",
      where: "event_id = ?",
      whereArgs: [eventID],
      orderBy: "created_at ASC"
    );
    final messages = result.map((row) {
      final m = Map<String, dynamic>.from(row);
      final ts = m["created_at"] as int;
      final iso = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toIso8601String();
      m["created_at"] = iso;
      m["created_at_iso"] = iso;
      return m;
    }).toList();
    return messages;
  }

  static Future<void> storeEventDB(Event e) async {
    final db = await database;

    await db.insert(
      "events",
      {
        "event_id": e.eventId,
        "title": e.title,
        "desc": e.desc,
        "user_id": e.userId,
        "host_name": e.hostName,
        "time": e.time.millisecondsSinceEpoch,
        "capacity": e.capacity,
        "instant_join": e.instantJoin ? 1 : 0,
        "participant_count": e.participantCount,
        "image_url": e.imageUrl,
        "tags": jsonEncode(e.tags.map((e) => e.name).toList()),
        "lat": e.coords.latitude,
        "lon": e.coords.longitude,
        "is_close": e.isClose ? 1 : 0,
        "distance_to_user": e.distanceToUser,
        "attendants": jsonEncode(e.attendantIds),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Event>> getEventsDB() async {
    final db = await database;

    final rows = await db.query("events");

    return rows.map((m) {
      return Event(
        title: m["title"] as String,
        desc: m["desc"] as String,
        userId: m["user_id"] as String,
        eventId: m["event_id"] as String,
        time: DateTime.fromMillisecondsSinceEpoch(m["time"] as int),
        hostName: m["host_name"] as String,
        capacity: m["capacity"] as int,
        instantJoin: (m["instant_join"] as int) == 1,
        participantCount: m["participant_count"] as int,
        imageUrl: m["image_url"] as String,
        tags: (jsonDecode(m["tags"] as String) as List)
                .map((e) => Tag.values.byName(e as String))
                .toList(),
        coords: LatLng(
          m["lat"] as double,
          m["lon"] as double,
        ),
        distanceToUser: m["distance_to_user"] as int,
        attendantIds: (jsonDecode(m["attendants"] as String) as List).cast<String>(),
      );
    }).toList();
  }
}
