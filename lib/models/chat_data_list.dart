import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/llm_model.dart';
import 'package:sqflite/sqflite.dart';

import 'message.dart';
import 'chat_data.dart';
import '../utils/util.dart';
import './chat_database.dart';

class ChatDataList extends ChangeNotifier {
  late final Database db;
  late final List<ChatData> dataList;
  late Function() notifyChatDataListner;

  late ChatData _currentData;
  ChatData get currentData => _currentData;
  set currentData(ChatData value) {
    _currentData = value;
    notifyListeners();
  }

  int currentSelected = -1;

  ChatDataList() {
    dataList = [];
    _loadDatabase();
    newChat();
    notifyChatDataListner = notifyListeners;
  }

  void _loadDatabase() async {
    db = await ChatDatabase().database;
    List<Map<String, Object?>> chatListData =
        await db.query(ChatDatabase.tableChatList);
    for (var listData in chatListData) {
      dataList.add(
        ChatData.fromJson(
          listData,
          await db.query(
            ChatDatabase.tableChatMessages,
            where: '${ChatDatabase.chatId} = ?',
            whereArgs: [listData[ChatDatabase.chatId] as String],
          ),
        ),
      );
    }
    notifyListeners();
  }

  void newChat({
    LLMModel? llmModel,
    BuildContext? context,
  }) {
    currentData = ChatData(messageList: List<Message>.empty(growable: true));
    currentSelected = -1;
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': '0'});
    }
    llmModel?.resetKnowledge?.call();
  }

  void add(ChatData value,
      {bool checkDuplicate = false, BuildContext? context}) async {
    if (dataList.contains(value) && checkDuplicate) {
      if (kDebugMode) {
        print('Duplicate! ${value.id}');
      }
      return;
    }
    dataList.insert(0, value);
    currentSelected = 0;
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': value.id});
    }
    await db.insert(
      ChatDatabase.tableChatList,
      {
        ChatDatabase.chatId: currentData.id,
        ChatDatabase.chatTitle: currentData.title,
        ChatDatabase.knowledges: jsonEncode(currentData.knowledges),
        ChatDatabase.parameters: jsonEncode(currentData.parameters),
        ChatDatabase.usePreprompt: currentData.usePreprompt.first ? 1 : 0,
        ChatDatabase.preprompt: 'currentData.prePrompt',
        ChatDatabase.useChatContext:
            currentData.useChatConversationContext.first ? 1 : 0,
        ChatDatabase.lastMessageTimestamp: currentData.dateCreated,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    notifyListeners();
  }

  void remove(ChatData value) async {
    db.delete(ChatDatabase.tableChatList,
        where: '${ChatDatabase.chatId} = ?', whereArgs: [value.id]);
    db.delete(ChatDatabase.tableChatMessages,
        where: '${ChatDatabase.chatId} = ?', whereArgs: [value.id]);
    bool result = dataList.remove(value);
    newChat();
    if (kDebugMode) {
      print('Remove: $value is $result');
    }
  }

  void loadData(int index, {LLMModel? llmModel, BuildContext? context}) {
    if (index > dataList.length - 1 || index < 0) {
      newChat();
      return;
    }
    currentSelected = index;
    currentData = dataList[index];
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': currentData.id});
    }

    llmModel?.setKnowledge?.call(currentData.knowledges);
  }

  void addToMessageList(Message messageWidget, ChatData chatData) async {
    if (chatData.messageList.isNotEmpty &&
        chatData.messageList.last.role == MessageRole.modelTyping) {
      chatData.messageList.removeLast();
    }
    chatData.messageList.add(messageWidget);
    await db.insert(ChatDatabase.tableChatMessages, {
      ChatDatabase.chatId: chatData.id,
      ChatDatabase.role: messageWidget.role.index,
      ChatDatabase.message: messageWidget.message,
      ChatDatabase.messageTextData: jsonEncode(messageWidget.textData),
      ChatDatabase.messageToken: messageWidget.token
    });
  }

  void updateConfigToDatabase() {
    ChatDatabase().updateValue(
      table: ChatDatabase.tableChatList,
      where: ChatDatabase.chatId,
      whereArgs: currentData.id,
      values: {
        ChatDatabase.chatTitle: currentData.title,
        ChatDatabase.knowledges: jsonEncode(currentData.knowledges),
        ChatDatabase.parameters: jsonEncode(currentData.parameters),
        ChatDatabase.usePreprompt: currentData.usePreprompt.first ? 1 : 0,
        ChatDatabase.preprompt: 'currentData.prePrompt',
        ChatDatabase.useChatContext:
            currentData.useChatConversationContext.first ? 1 : 0,
        ChatDatabase.lastMessageTimestamp: currentData.dateCreated,
      },
    );
  }

  void applyParameter(Map<String, dynamic> toApply) {
    for (var i in toApply.keys) {
      var element = currentData.parameters[i];
      if (element == null) {
        continue;
      }
      toApply[i] = element;
    }
    notifyListeners();
  }
}
