import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/services/llm_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_html/html.dart' as http;

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
    List<Map<String, Object?>> chatListData = await db.query(
      ChatDatabase.tableChatList,
      orderBy: '${ChatDatabase.chatId} DESC',
    );
    for (var listData in chatListData) {
      dataList.add(
        ChatData.fromMap(
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
  }) async {
    currentData = ChatData(messageList: List<Message>.empty(growable: true));
    currentSelected = -1;
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': '0'});
    }
    await llmModel?.resetKnowledge();
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
    currentData = value;
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': value.id});
    }
    await db.insert(
      ChatDatabase.tableChatList,
      value.toMap(),
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

  void loadData(int index, {LLMModel? llmModel, BuildContext? context}) async {
    if (index > dataList.length - 1 || index < 0) {
      newChat();
      return;
    }
    currentSelected = index;
    currentData = dataList[index];
    if (context != null) {
      Utils.navigateWithNewQueryParams(context, {'chat': currentData.id});
    }

    await llmModel?.setKnowledge(currentData.knowledges);
  }

  void addToMessageList(Message messageWidget, ChatData chatData,
      {bool onlyAddToDatabase = false}) async {
    if (chatData.messageList.isNotEmpty &&
        chatData.messageList.last.role == MessageRole.modelTyping) {
      chatData.messageList.removeLast();
    }
    if (!onlyAddToDatabase) {
      chatData.messageList.add(messageWidget);
    }
    await db.insert(ChatDatabase.tableChatMessages, {
      ChatDatabase.chatId: chatData.id,
      ChatDatabase.role: messageWidget.role.index,
      ChatDatabase.message: messageWidget.message,
      ChatDatabase.messageTextData: jsonEncode(messageWidget.textData),
      ChatDatabase.messageToken: messageWidget.token
    });
  }

  Future<Message> removeToMessageList(int index, {ChatData? chatData}) async {
    chatData ??= currentData;
    Message message = chatData.messageList[index];

    await db.delete(
      ChatDatabase.tableChatMessages,
      where:
          '${ChatDatabase.chatId} = ? AND ${ChatDatabase.message} = ? AND ${ChatDatabase.messageTextData} = ?',
      whereArgs: [
        chatData.id,
        message.message,
        jsonEncode(
          message.textData,
        )
      ],
    );

    chatData.messageList.remove(message);
    return message;
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

  void renameChat(String title) {
    ChatDatabase().updateValue(
        table: ChatDatabase.tableChatList,
        where: ChatDatabase.chatId,
        whereArgs: currentData.id,
        values: {ChatDatabase.chatTitle: title});
  }

  void importFromJson(BuildContext? context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      String fileString = '';
      if (kIsWeb) {
        fileString = String.fromCharCodes(result.files.first.bytes!);
      } else {
        File file = File(result.paths.first!);
        fileString = await file.readAsString();
      }
      Map<String, Object?> fileData =
          jsonDecode(fileString) as Map<String, Object?>;
      ChatData chatData = ChatData.fromMap(
        fileData,
        List<Map<String, Object?>>.from(
            fileData[ChatDatabase.tableChatMessages] as List),
        newId: true,
      );
      for (var item in chatData.messageList) {
        addToMessageList(item, chatData, onlyAddToDatabase: true);
      }
      add(chatData);
      if (context != null && context.mounted) {
        Utils.showSnackBar(
          context,
          title: 'Imported',
          subTitle: 'Import: ${fileData[ChatDatabase.chatTitle]}',
        );
      }
    }
  }

  void exportToJson(BuildContext? context) async {
    String fileData = jsonEncode(currentData.toMapAll());
    String fileName = Utils.sanitizeFilename(currentData.title);
    if (kIsWeb) {
      final blob = http.Blob([fileData]);
      final url = http.Url.createObjectUrlFromBlob(blob);
      final anchor = http.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = fileName;
      http.document.body!.append(anchor);
      anchor.click();
      http.document.body!.children.remove(anchor);
      http.Url.revokeObjectUrl(url);
      return;
    }
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save as',
      fileName: '$fileName.json',
    );
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(fileData, mode: FileMode.write);
      if (context != null && context.mounted) {
        Utils.showSnackBar(
          context,
          title: 'Export To Json',
          subTitle: 'Saving: $outputFile',
        );
      }
    }
  }
}
