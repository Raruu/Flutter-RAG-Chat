import 'dart:convert';

import '../controllers/chat_database.dart';
import 'message.dart';

class ChatData {
  late final String id;
  late String title;
  late int totalToken;
  late Map<String, dynamic> parameters;
  List<bool> usePreprompt = [false];
  String? prePrompt;
  List<bool> useChatConversationContext = [true];
  List<int> maxKnowledgeCount = [2];
  List<double> minKnowledgeScore = [0.1];
  late final List<Message> messageList;
  late final String dateCreated;
  late final List<Map<String, dynamic>> knowledges;

  ChatData({
    this.title = 'Unknown chat ###',
    this.totalToken = 0,
    required this.messageList,
  }) {
    String dateTimeNow = DateTime.now().toUtc().toString();
    id = dateTimeNow
        .substring(0, dateTimeNow.length - 1)
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');

    parameters = {};

    dateCreated = dateTimeNow.substring(0, dateTimeNow.indexOf(' '));

    knowledges = [];
  }

  ChatData.fromMap(
      Map<String, Object?> mapChat, List<Map<String, Object?>> mapMessages,
      {bool newId = false}) {
    if (newId) {
      String dateTimeNow = DateTime.now().toUtc().toString();
      id = dateTimeNow
          .substring(0, dateTimeNow.length - 1)
          .replaceAll('-', '')
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll(' ', '');
    } else {
      id = mapChat[ChatDatabase.chatId] as String;
    }
    title = mapChat[ChatDatabase.chatTitle] as String;
    knowledges =
        List.from(jsonDecode(mapChat[ChatDatabase.knowledges] as String));
    parameters = jsonDecode(mapChat[ChatDatabase.parameters] as String);
    usePreprompt = [(mapChat[ChatDatabase.usePreprompt] as int) == 1];
    prePrompt = mapChat[ChatDatabase.preprompt] as String;
    useChatConversationContext = [
      (mapChat[ChatDatabase.useChatContext] as int) == 1
    ];
    maxKnowledgeCount = [
      (mapChat[ChatDatabase.maxKnowledgeCount] ?? maxKnowledgeCount[0]) as int
    ];
    minKnowledgeScore = [
      (mapChat[ChatDatabase.minKnowledgeScore] ?? minKnowledgeScore[0])
          as double
    ];
    dateCreated = mapChat[ChatDatabase.lastMessageTimestamp] as String;

    totalToken = 0;
    messageList = [];
    for (var item in mapMessages) {
      totalToken += item[ChatDatabase.messageToken] as int;
      messageList.add(Message.fromMap(item));
    }
  }

  Map<String, Object> toMap() => {
        ChatDatabase.chatId: id,
        ChatDatabase.chatTitle: title,
        ChatDatabase.knowledges: jsonEncode(knowledges),
        ChatDatabase.parameters: jsonEncode(parameters),
        ChatDatabase.usePreprompt: usePreprompt.first ? 1 : 0,
        ChatDatabase.preprompt: prePrompt ?? '',
        ChatDatabase.useChatContext: useChatConversationContext.first ? 1 : 0,
        ChatDatabase.maxKnowledgeCount: maxKnowledgeCount.first,
        ChatDatabase.minKnowledgeScore: minKnowledgeScore.first,
        ChatDatabase.lastMessageTimestamp: dateCreated,
      };

  Map<String, Object> toMapAll() => {
        ...toMap(),
        ChatDatabase.tableChatMessages: List.generate(
          messageList.length,
          (index) => {
            ChatDatabase.chatId: id,
            ...messageList[index].toMap(),
          },
        ),
      };
}
