import 'package:flutter/foundation.dart';
import 'package:flutter_rag_chat/models/llm_model.dart';

import 'message.dart';
import 'chat_data.dart';

class ChatDataList extends ChangeNotifier {
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
    newChat();
    notifyChatDataListner = notifyListeners;
  }

  void newChat({LLMModel? llmModel}) {
    currentData = ChatData(messageList: List<Message>.empty(growable: true));
    currentSelected = -1;
    llmModel?.setKnowledge?.call([]);
  }

  void add(ChatData value, {bool checkDuplicate = false}) {
    if (dataList.contains(value) && checkDuplicate) {
      if (kDebugMode) {
        print('Duplicate! ${value.id}');
      }
      return;
    }
    dataList.insert(0, value);
    notifyListeners();
  }

  void remove(ChatData value) {
    bool result = dataList.remove(value);
    newChat();
    if (kDebugMode) {
      print('Remove: $value is $result');
    }
  }

  void loadData(int index) {
    if (index > dataList.length - 1 || index < 0) {
      newChat();
      return;
    }
    currentSelected = index;
    currentData = dataList[index];
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
