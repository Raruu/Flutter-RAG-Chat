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

    return await openDatabase(
      path,
      version: 1, // Testing, possible data lost
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
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
        $useChatContext INTEGER NOT NULL,
        $maxKnowledgeCount INTEGER,
        $minKnowledgeScore REAL  
        )
      ''');

    await db.execute('''
        CREATE TABLE $tableChatMessages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          $chatId TEXT,
          $role INTEGER NOT NULL,
          $message TEXT NOT NULL,
          $messageContext TEXT,
          $messageToken INTEGER NOT NULL,
          FOREIGN KEY ($chatId) REFERENCES $tableChatList ($chatId)
        )
      ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  void update({
    required String table,
    required String where,
    required String whereArgs,
    required Map<String, Object> values,
  }) async {
    var db = await database;
    await db.update(table, values, where: '$where = ?', whereArgs: [whereArgs]);
  }

  Future<List<Map<String, Object?>>> getChatList() async {
    var db = await database;
    return await db.query(
      ChatDatabase.tableChatList,
      orderBy: '${ChatDatabase.chatId} DESC',
    );
  }

  Future<List<Map<String, Object?>>> getChatMessages(String chatId) async {
    var db = await database;
    return await db.query(
      ChatDatabase.tableChatMessages,
      where: '${ChatDatabase.chatId} = ?',
      whereArgs: [chatId],
    );
  }

  void addChat(Map<String, Object> data) async {
    var db = await database;
    await db.insert(
      ChatDatabase.tableChatList,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void addMessage({
    required String chatId,
    required Map messageMap,
  }) async {
    var db = await database;
    await db.insert(ChatDatabase.tableChatMessages, {
      ChatDatabase.chatId: chatId,
      ...messageMap,
    });
  }

  void deleteMessage(
      String whereId, String whereMessage, String? whereMessageContext) async {
    var db = await database;
    await db.delete(
      tableChatMessages,
      where: '$chatId = ? AND $message = ? AND $messageContext = ?',
      whereArgs: [whereId, whereMessage, whereMessageContext],
    );
  }

  void deleteChat(String chatId) async {
    var db = await database;
    await db.delete(
      tableChatMessages,
      where: '${ChatDatabase.chatId} = ?',
      whereArgs: [chatId],
    );

    await db.delete(
      tableChatList,
      where: '${ChatDatabase.chatId} = ?',
      whereArgs: [chatId],
    );
  }

  void resetDatabase() async => await deleteDatabase(await getDatabasesPath());

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
  static const String maxKnowledgeCount = 'max_knowledge_count';
  static const String minKnowledgeScore = 'min_knowledge_score';

  static const String role = 'role';
  static const String message = 'message';
  static const String messageContext = 'message_context';
  static const String messageToken = 'message_token';
}
