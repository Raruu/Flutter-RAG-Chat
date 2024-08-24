import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat_data_list.dart';

abstract class BaseModel {
  Map<String, dynamic>? defaultParameters;
  Widget? widgetLlmodelSetting;
  Widget? widgetEmbeddingmodelSetting;
  Widget? informationWidget;

  Future? onChatSettingsChanged();
  Future? resetKnowledge();
  Future? deleteKnowledge(String filename);
  Future? setKnowledge(List<Map<String, dynamic>> knowledges);
  Future? addKnowledge(dynamic value, {String? webFileName});

  final Function() notifyListenerLLM;
  final SharedPreferences prefs;
  final ChatDataList chatDataList;
  BaseModel(this.notifyListenerLLM, this.prefs, this.chatDataList);

  Future<Map<String, dynamic>?> generateText({
    required String prompt,
    required int seed,
    required Map<String, dynamic> parameters,
  });
}
