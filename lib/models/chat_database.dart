import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatDatabase {
  static final ChatDatabase _instance = ChatDatabase._internal();
  static Database? _database;
  factory ChatDatabase() {
    return _instance;
  }
  ChatDatabase._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'chats.db');
    // await deleteDatabase(path);

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  void _createDatabase(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableChatList (
        $chatId TEXT PRIMARY KEY,
        $chatTitle TEXT NOT NULL,
        $lastMessageTimestamp DATETIME,
        $parameters TEXT,
        $knowledges TEXT,
        $usePreprompt INTEGER NOT NULL,
        $preprompt TEXT,
        $useChatContext INTEGER NOT NULL       
        )
      ''');

    await db.execute('''
        CREATE TABLE $tableChatMessages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $chatId TEXT,
          $role INTEGER NOT NULL,
          $message TEXT NOT NULL,
          $messageTextData TEXT,
          $messageToken INTEGER NOT NULL,
          FOREIGN KEY ($chatId) REFERENCES $tableChatList ($chatId)
        )
      ''');
  }

  void updateValue({
    required String table,
    required String where,
    required String whereArgs,
    required Map<String, Object> values,
  }) async {
    var db = await database;
    await db.update(table, values, where: '$where = ?', whereArgs: [whereArgs]);
  }

  static const String tableChatList = 'chat_list';
  static const String tableChatMessages = 'chat_messages';
  static const String chatId = 'chat_id';
  static const String chatTitle = 'chat_title';
  static const String lastMessageTimestamp = 'last_message_timestamp';
  static const String parameters = 'parameters';
  static const String knowledges = 'knowledges';
  static const String usePreprompt = 'use_preprompt';
  static const String preprompt = 'preprompt';
  static const String useChatContext = 'use_chat_context';

  static const String role = 'role';
  static const String message = 'message';
  static const String messageTextData = 'message_text_data';
  static const String messageToken = 'message_token';
}
