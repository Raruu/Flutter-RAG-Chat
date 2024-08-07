import 'dart:convert';

import 'package:flutter_rag_chat/models/chat_database.dart';

import 'message.dart';

class ChatData {
  late final String id;
  late String title;
  late int totalToken;
  late Map<String, dynamic> parameters;
  List<bool> usePreprompt = [false];
  String? prePrompt;
  List<bool> useChatConversationContext = [true];
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

  ChatData.fromJson(
      Map<String, Object?> jsonChat, List<Map<String, Object?>> jsonMessages) {
    id = jsonChat[ChatDatabase.chatId] as String;
    title = jsonChat[ChatDatabase.chatTitle] as String;
    knowledges =
        List.from(jsonDecode(jsonChat[ChatDatabase.knowledges] as String));
    parameters = jsonDecode(jsonChat[ChatDatabase.parameters] as String);
    usePreprompt = [(jsonChat[ChatDatabase.usePreprompt] as int) == 1];
    prePrompt = jsonChat[ChatDatabase.preprompt] as String;
    useChatConversationContext = [
      (jsonChat[ChatDatabase.useChatContext] as int) == 1
    ];
    dateCreated = jsonChat[ChatDatabase.lastMessageTimestamp] as String;

    print(jsonDecode(jsonChat[ChatDatabase.knowledges] as String));

    totalToken = 0;
    messageList = [];
    for (var item in jsonMessages) {
      int token = item[ChatDatabase.messageToken] as int;
      totalToken += token;
      messageList.add(
        Message(
          token: token,
          role: item[ChatDatabase.role] as int == 0
              ? MessageRole.user
              : MessageRole.model,
          message: item[ChatDatabase.message] as String,
          textData: jsonDecode(item[ChatDatabase.messageTextData] as String),
        ),
      );
    }
  }
}
